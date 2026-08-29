import { recordExport } from "@/lib/admin-store";
import { logError } from "@/lib/error-log";
import { exportDeviceId, exportPlatform } from "@/lib/export-identity";
import { getClientIp } from "@/lib/geo";
import { overRateLimit } from "@/lib/rate-limit";
import {
  normalizeOptions,
  renderHtmlToMp4,
  RenderError,
  type RenderInput,
} from "@/lib/html-video";

// Renders per IP per window. A person converting a page does a handful; a
// scraper does hundreds.
const RENDER_LIMIT = 10;
const RENDER_WINDOW_MS = 60_000;

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
// Rendering + encoding can take a while for longer clips.
export const maxDuration = 300;

/**
 * Converts an animated HTML document into an MP4. Used by the mobile and desktop
 * apps' "HTML → Video" feature. The encoded video is streamed back in the response
 * body (nothing is persisted server-side, matching the rest of the pipeline).
 */
export async function POST(request: Request) {
  // Public: HTML → Video is a free feature of the apps, which render through
  // this route on every platform except macOS, and Stillora has no accounts to
  // authenticate. A headless-Chrome render is expensive, so it is capped per IP
  // instead. Anything heavier belongs at the proxy.
  if (overRateLimit(getClientIp(request), RENDER_LIMIT, RENDER_WINDOW_MS)) {
    return Response.json(
      { error: "Too many renders. Try again in a minute." },
      { status: 429 },
    );
  }

  let body: RenderInput;
  try {
    body = (await request.json()) as RenderInput;
  } catch {
    return Response.json({ error: "Invalid request body." }, { status: 400 });
  }

  try {
    const options = normalizeOptions(body);
    const mp4 = await renderHtmlToMp4(options);
    // Counted alongside every other export so the dashboard's per-tool
    // breakdown reflects HTML → Video, not just the editor.
    void recordExport({
      deviceId: exportDeviceId(request),
      platform: exportPlatform(request),
      tool: "html",
      presetId: `${options.width}x${options.height}`,
      duration: Math.round(options.durationMs / 1000),
    });
    return new Response(new Uint8Array(mp4), {
      status: 200,
      headers: {
        "Content-Type": "video/mp4",
        "Content-Length": String(mp4.byteLength),
        "Content-Disposition": 'attachment; filename="stillora.mp4"',
        "Cache-Control": "no-store",
      },
    });
  } catch (error) {
    if (error instanceof RenderError) {
      return Response.json({ error: error.message }, { status: error.status });
    }
    void logError({
      source: "api/convert/html",
      error,
      platform: exportPlatform(request),
      deviceId: exportDeviceId(request),
    });
    return Response.json({ error: "Render failed." }, { status: 500 });
  }
}
