import { spawn } from "node:child_process";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import http from "node:http";
import type { AddressInfo } from "node:net";
import { tmpdir } from "node:os";
import path from "node:path";
import ffmpegPath from "ffmpeg-static";
import puppeteer, { type Browser, type CDPSession, type Page } from "puppeteer";

/**
 * Server-side renderer that turns an animated HTML document into an H.264 MP4.
 *
 * Frames are captured with Chromium "virtual time": the page clock is paused and
 * advanced by exactly `1000 / fps` ms per frame, so CSS keyframe animations, JS
 * `requestAnimationFrame`, and timers all step in lockstep. This makes the output
 * deterministic and smooth regardless of how fast the host can actually render.
 */

export class RenderError extends Error {
  status: number;
  constructor(message: string, status = 400) {
    super(message);
    this.status = status;
    this.name = "RenderError";
  }
}

export const MIN_DIMENSION = 16;
export const MAX_DIMENSION = 1920;
export const MIN_FPS = 1;
export const MAX_FPS = 60;
export const MIN_DURATION_MS = 200;
export const MAX_DURATION_MS = 60_000;
/** Hard cap on captured frames so a request can't pin a CPU indefinitely. */
export const MAX_FRAMES = 1800;

export type RenderInput = {
  html?: unknown;
  url?: unknown;
  width?: unknown;
  height?: unknown;
  durationMs?: unknown;
  fps?: unknown;
};

export type RenderOptions = {
  html?: string;
  url?: string;
  width: number;
  height: number;
  durationMs: number;
  fps: number;
};

function toEven(value: number) {
  return value % 2 === 0 ? value : value - 1;
}

function clampInt(value: unknown, min: number, max: number, fallback: number) {
  const num = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(num)) return fallback;
  return Math.min(Math.max(Math.round(num), min), max);
}

/** Validates and clamps the raw request body into safe render options. */
export function normalizeOptions(body: RenderInput): RenderOptions {
  const html = typeof body.html === "string" ? body.html : undefined;
  const url = typeof body.url === "string" ? body.url.trim() : undefined;

  if (!html && !url) {
    throw new RenderError("Provide `html` markup or a `url` to render.", 400);
  }
  if (html && html.length > 5_000_000) {
    throw new RenderError("HTML document is too large (max 5 MB).", 413);
  }
  if (url) assertSafeUrl(url);

  // H.264 + yuv420p requires even dimensions.
  const width = toEven(clampInt(body.width, MIN_DIMENSION, MAX_DIMENSION, 1080));
  const height = toEven(clampInt(body.height, MIN_DIMENSION, MAX_DIMENSION, 1920));
  const fps = clampInt(body.fps, MIN_FPS, MAX_FPS, 30);
  const durationMs = clampInt(
    body.durationMs,
    MIN_DURATION_MS,
    MAX_DURATION_MS,
    5000,
  );

  if (Math.round((durationMs / 1000) * fps) > MAX_FRAMES) {
    throw new RenderError(
      `Too many frames: reduce duration or fps (max ${MAX_FRAMES} frames).`,
      400,
    );
  }

  return { html, url, width, height, durationMs, fps };
}

/** Blocks non-http(s) schemes and obvious private/loopback hosts (SSRF guard). */
function assertSafeUrl(raw: string) {
  let parsed: URL;
  try {
    parsed = new URL(raw);
  } catch {
    throw new RenderError("Invalid URL.", 400);
  }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
    throw new RenderError("Only http(s) URLs are allowed.", 400);
  }
  if (isPrivateHost(parsed.hostname)) {
    throw new RenderError("That host is not allowed.", 400);
  }
}

function isPrivateHost(hostname: string) {
  const host = hostname.toLowerCase();
  if (host === "localhost" || host === "0.0.0.0" || host.endsWith(".local")) {
    return true;
  }
  const v4 = host.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  if (v4) {
    const [a, b] = [Number(v4[1]), Number(v4[2])];
    if (a === 10 || a === 127) return true;
    if (a === 192 && b === 168) return true;
    if (a === 172 && b >= 16 && b <= 31) return true;
    if (a === 169 && b === 254) return true;
  }
  if (host === "::1" || host.startsWith("fc") || host.startsWith("fd")) {
    return true;
  }
  return false;
}

let browserPromise: Promise<Browser> | null = null;

/** Lazily launches a shared headless Chromium and reuses it across requests. */
async function getBrowser(): Promise<Browser> {
  if (!browserPromise) {
    browserPromise = puppeteer
      .launch({
        headless: true,
        args: [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--disable-dev-shm-usage",
          "--disable-gpu",
          "--hide-scrollbars",
          "--force-color-profile=srgb",
        ],
        executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || undefined,
      })
      .catch((error) => {
        browserPromise = null;
        throw error;
      });
  }
  return browserPromise;
}

/** Advances the page's virtual clock by `budgetMs` and waits for it to elapse. */
function advanceVirtualTime(client: CDPSession, budgetMs: number) {
  return new Promise<void>((resolve, reject) => {
    let settled = false;
    const done = () => {
      if (settled) return;
      settled = true;
      resolve();
    };
    client.once("Emulation.virtualTimeBudgetExpired", done);
    client
      .send("Emulation.setVirtualTimePolicy", {
        policy: "advance",
        budget: budgetMs,
        maxVirtualTimeTaskStarvationCount: 1_000_000,
      })
      .catch((error) => {
        if (settled) return;
        settled = true;
        reject(error);
      });
  });
}

async function blockUnsafeRequests(page: Page, allowedOrigin: string | null) {
  await page.setRequestInterception(true);
  page.on("request", (request) => {
    const reqUrl = request.url();
    if (reqUrl.startsWith("data:") || reqUrl.startsWith("blob:")) {
      void request.continue();
      return;
    }
    try {
      const parsed = new URL(reqUrl);
      // The loopback origin we serve the user's own HTML from is always allowed.
      if (allowedOrigin && parsed.origin === allowedOrigin) {
        void request.continue();
        return;
      }
      const httpScheme =
        parsed.protocol === "http:" || parsed.protocol === "https:";
      if (!httpScheme || isPrivateHost(parsed.hostname)) {
        void request.abort();
        return;
      }
    } catch {
      void request.abort();
      return;
    }
    void request.continue();
  });
}

type LocalServer = { origin: string; close: () => Promise<void> };

/**
 * Serves the HTML over an ephemeral loopback origin. Navigating to a real
 * `http://` URL (rather than `setContent`, whose base is `about:blank`) lets the
 * page's `fetch`, blob URLs, web workers, and relative asset URLs resolve — which
 * bundled/self-unpacking exports depend on to render at all.
 */
function startLocalServer(html: string): Promise<LocalServer> {
  return new Promise((resolve, reject) => {
    const server = http.createServer((_req, res) => {
      res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      res.end(html);
    });
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address() as AddressInfo;
      resolve({
        origin: `http://127.0.0.1:${port}`,
        close: () =>
          new Promise<void>((done) => server.close(() => done())),
      });
    });
  });
}

function delay(ms: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}

/** Renders the animation to an MP4 and returns the encoded bytes. */
export async function renderHtmlToMp4(options: RenderOptions): Promise<Buffer> {
  const { width, height, fps, durationMs } = options;
  const frameCount = Math.max(1, Math.round((durationMs / 1000) * fps));
  const frameBudgetMs = 1000 / fps;

  const browser = await getBrowser();
  const page = await browser.newPage();
  const workDir = await mkdtemp(path.join(tmpdir(), "stillora-html-"));
  let localServer: LocalServer | null = null;

  try {
    await page.setViewport({ width, height, deviceScaleFactor: 1 });

    // Serve raw HTML from a loopback origin; navigate user URLs directly.
    let navUrl: string;
    if (options.url) {
      navUrl = options.url;
    } else {
      localServer = await startLocalServer(options.html ?? "");
      navUrl = `${localServer.origin}/`;
    }
    await blockUnsafeRequests(page, localServer?.origin ?? null);

    // Load and fully bootstrap the page in real time: many real-world exports
    // unpack embedded assets, mount a framework, and load web fonts after
    // `DOMContentLoaded`. Capturing before that finishes yields blank frames.
    try {
      await page.goto(navUrl, { waitUntil: "networkidle0", timeout: 30_000 });
    } catch {
      // `networkidle` can stall on pages holding a connection open; capture
      // whatever has rendered rather than failing the whole render.
    }
    await page.evaluate(() => (document as Document).fonts?.ready).catch(() => {});
    await delay(400);

    // Freeze the clock, then step it one frame at a time so CSS animations,
    // requestAnimationFrame, and timers all advance deterministically.
    const client = await page.createCDPSession();
    await client.send("Emulation.setVirtualTimePolicy", { policy: "pause" });

    for (let frame = 0; frame < frameCount; frame += 1) {
      const filePath = path.join(
        workDir,
        `frame_${String(frame + 1).padStart(5, "0")}.png`,
      );
      await page.screenshot({
        path: filePath as `${string}.png`,
        clip: { x: 0, y: 0, width, height },
        captureBeyondViewport: false,
        optimizeForSpeed: true,
      });
      await advanceVirtualTime(client, frameBudgetMs);
    }

    const outputPath = path.join(workDir, "out.mp4");
    await encodeFrames(workDir, outputPath, fps);
    return await readFile(outputPath);
  } finally {
    await page.close().catch(() => {});
    if (localServer) await localServer.close().catch(() => {});
    await rm(workDir, { recursive: true, force: true }).catch(() => {});
  }
}

function encodeFrames(workDir: string, outputPath: string, fps: number) {
  const args = [
    "-y",
    "-framerate",
    String(fps),
    "-i",
    path.join(workDir, "frame_%05d.png"),
    "-c:v",
    "libx264",
    "-preset",
    "veryfast",
    "-pix_fmt",
    "yuv420p",
    "-movflags",
    "+faststart",
    outputPath,
  ];
  return runFfmpeg(getFfmpegPath(), args);
}

function runFfmpeg(binaryPath: string, args: string[]) {
  return new Promise<void>((resolve, reject) => {
    const proc = spawn(binaryPath, args);
    let errorOutput = "";
    proc.stderr.on("data", (chunk: Buffer) => {
      errorOutput += chunk.toString();
    });
    proc.on("error", reject);
    proc.on("close", (code) => {
      if (code === 0) {
        resolve();
        return;
      }
      reject(new RenderError(errorOutput || `FFmpeg exited with code ${code}.`, 500));
    });
  });
}

function getFfmpegPath() {
  const localBinary = path.join(
    process.cwd(),
    "node_modules",
    "ffmpeg-static",
    "ffmpeg",
  );
  if (ffmpegPath && ffmpegPath !== "/ROOT/node_modules/ffmpeg-static/ffmpeg") {
    return ffmpegPath;
  }
  return localBinary;
}
