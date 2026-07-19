import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";

import {
  advanceVirtualTime,
  blockUnsafeRequests,
  delay,
  getBrowser,
  startLocalServer,
  type LocalServer,
} from "./browser";
import { encodeFrames } from "./encode";
import { MAX_RENDER_MS, RenderError, type RenderOptions } from "./options";

/** Renders the animation to an MP4 and returns the encoded bytes. */
export async function renderHtmlToMp4(options: RenderOptions): Promise<Buffer> {
  const { width, height, fps, durationMs } = options;
  const frameCount = Math.max(1, Math.round((durationMs / 1000) * fps));
  const frameBudgetMs = 1000 / fps;

  const deadline = Date.now() + MAX_RENDER_MS;
  const checkDeadline = () => {
    if (Date.now() > deadline) {
      throw new RenderError(
        "The render took too long. Try a shorter duration, a lower fps, or a smaller size.",
        504,
      );
    }
  };

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
      // Bail out with a clear error before the front proxy would kill the
      // connection (which the apps show as the generic connection error).
      checkDeadline();
      const filePath = path.join(
        workDir,
        `frame_${String(frame + 1).padStart(5, "0")}.jpg`,
      );
      // JPEG is far cheaper to encode than PNG; the output is re-encoded to
      // H.264 (yuv420p) anyway, so the high-quality JPEG is visually lossless.
      await page.screenshot({
        path: filePath as `${string}.jpeg`,
        type: "jpeg",
        quality: 92,
        clip: { x: 0, y: 0, width, height },
        captureBeyondViewport: false,
        optimizeForSpeed: true,
      });
      await advanceVirtualTime(client, frameBudgetMs);
    }

    // Write the optional soundtrack next to the frames so ffmpeg can mux it.
    let audioPath: string | undefined;
    if (options.audio && options.audio.byteLength > 0) {
      audioPath = path.join(workDir, "audio.input");
      await writeFile(audioPath, options.audio);
    }

    const outputPath = path.join(workDir, "out.mp4");
    await encodeFrames(workDir, outputPath, fps, audioPath);
    return await readFile(outputPath);
  } finally {
    await page.close().catch(() => {});
    if (localServer) await localServer.close().catch(() => {});
    await rm(workDir, { recursive: true, force: true }).catch(() => {});
  }
}
