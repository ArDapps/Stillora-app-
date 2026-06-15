import { getAdminFromRequest } from "@/lib/admin";
import { getUserFromRequest } from "@/lib/auth";
import {
  normalizeOptions,
  renderHtmlToMp4,
  RenderError,
  type RenderInput,
} from "@/lib/html-video";

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
  // Native apps authenticate as a user; the admin-only web tool may instead
  // carry an admin session.
  const user = await getUserFromRequest(request);
  const admin = user ? null : await getAdminFromRequest(request);
  if (!user && !admin) {
    return Response.json({ error: "Unauthorized." }, { status: 401 });
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
    console.error("html->mp4 render failed", error);
    return Response.json({ error: "Render failed." }, { status: 500 });
  }
}
