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
/**
 * Wall-clock budget for a single render. Kept below the typical reverse-proxy
 * read timeout (~60s) so an over-long render returns a clear JSON error instead
 * of the proxy killing the connection with an HTML 504 (which the apps surface
 * as the unhelpful generic "check your connection" message). Tune to match the
 * front proxy's `proxy_read_timeout` / equivalent.
 */
export const MAX_RENDER_MS = 50_000;

/** Largest accepted HTML document. Self-unpacking / bundled exports inline
 * their fonts, images and runtime as base64, so they can be tens of MB. */
export const MAX_HTML_BYTES = 30_000_000;
/** Largest accepted audio track (base64-decoded). */
export const MAX_AUDIO_BYTES = 30_000_000;

export type RenderInput = {
  html?: unknown;
  url?: unknown;
  width?: unknown;
  height?: unknown;
  durationMs?: unknown;
  fps?: unknown;
  /** Optional soundtrack / voice-over, base64-encoded (any ffmpeg-decodable
   * container: mp3, m4a, aac, wav, …). Muxed onto the rendered video. */
  audio?: unknown;
};

export type RenderOptions = {
  html?: string;
  url?: string;
  width: number;
  height: number;
  durationMs: number;
  fps: number;
  /** Decoded audio bytes to mux onto the output, if provided. */
  audio?: Buffer;
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
  if (html && html.length > MAX_HTML_BYTES) {
    throw new RenderError(
      `HTML document is too large (max ${Math.round(MAX_HTML_BYTES / 1e6)} MB).`,
      413,
    );
  }
  if (url) assertSafeUrl(url);

  // Optional audio track, sent base64-encoded.
  let audio: Buffer | undefined;
  if (typeof body.audio === "string" && body.audio.length > 0) {
    audio = Buffer.from(body.audio, "base64");
    if (audio.byteLength === 0) {
      throw new RenderError("Audio track could not be decoded.", 400);
    }
    if (audio.byteLength > MAX_AUDIO_BYTES) {
      throw new RenderError(
        `Audio track is too large (max ${Math.round(MAX_AUDIO_BYTES / 1e6)} MB).`,
        413,
      );
    }
  }

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

  return { html, url, width, height, durationMs, fps, audio };
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

export function isPrivateHost(hostname: string) {
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
