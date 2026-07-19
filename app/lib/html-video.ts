/**
 * Server-side renderer that turns an animated HTML document into an H.264 MP4.
 *
 * Frames are captured with Chromium "virtual time": the page clock is paused and
 * advanced by exactly `1000 / fps` ms per frame, so CSS keyframe animations, JS
 * `requestAnimationFrame`, and timers all step in lockstep. This makes the output
 * deterministic and smooth regardless of how fast the host can actually render.
 *
 * Barrel for the implementation in `lib/html-render/`:
 *   - `options.ts` — limits, request validation/clamping, SSRF guards
 *   - `browser.ts` — shared Chromium, virtual-time stepping, loopback server
 *   - `encode.ts`  — ffmpeg frame → MP4 encoding (with optional audio mux)
 *   - `render.ts`  — the capture/encode orchestration
 */

export type { RenderInput, RenderOptions } from "./html-render/options";
export {
  RenderError,
  MIN_DIMENSION,
  MAX_DIMENSION,
  MIN_FPS,
  MAX_FPS,
  MIN_DURATION_MS,
  MAX_DURATION_MS,
  MAX_FRAMES,
  MAX_RENDER_MS,
  MAX_HTML_BYTES,
  MAX_AUDIO_BYTES,
  normalizeOptions,
} from "./html-render/options";

export { renderHtmlToMp4 } from "./html-render/render";
