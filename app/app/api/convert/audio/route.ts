import { AudioExtractError, extractAudioFromUrl } from "@/lib/audio-extract";
import { getUserFromRequest } from "@/lib/auth";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
// Fetching + transcoding a longer clip can take a while.
export const maxDuration = 300;

/**
 * Converts a YouTube or TikTok link into an MP3. Used by the mobile and desktop
 * apps' "YouTube → MP3" feature. The encoded audio is streamed back in the
 * response body (nothing is persisted server-side).
 */
export async function POST(request: Request) {
  // Auth is optional here: this converter is usable by anonymous app users,
  // like the on-device tools. We still resolve the user when a token is present
  // (handy for future logging / rate-limiting) but never reject for its absence.
  // NOTE: because this endpoint is public, add rate-limiting before/at deploy so
  // it can't be abused as a free video-download service.
  await getUserFromRequest(request).catch(() => null);

  let body: { url?: unknown; language?: unknown };
  try {
    body = (await request.json()) as { url?: unknown; language?: unknown };
  } catch {
    return Response.json({ error: "Invalid request body." }, { status: 400 });
  }

  const url = typeof body.url === "string" ? body.url.trim() : "";
  if (!url) {
    return Response.json(
      { error: "Enter a YouTube or TikTok link." },
      { status: 400 },
    );
  }

  try {
    const { buffer, title } = await extractAudioFromUrl(url, {
      language: body.language,
    });
    const filename = `${title}.mp3`;
    // ASCII fallback + RFC 5987 UTF-8 name so titles with emoji/non-latin
    // characters survive the Content-Disposition header.
    const asciiName = filename.replace(/[^\x20-\x7e]/g, "_").replace(/"/g, "'");
    return new Response(new Uint8Array(buffer), {
      status: 200,
      headers: {
        "Content-Type": "audio/mpeg",
        "Content-Length": String(buffer.byteLength),
        "Content-Disposition":
          `attachment; filename="${asciiName}"; ` +
          `filename*=UTF-8''${encodeURIComponent(filename)}`,
        // Lets the app name the saved file with the real (decoded) title.
        "X-Stillora-Title": encodeURIComponent(title),
        "Cache-Control": "no-store",
      },
    });
  } catch (error) {
    if (error instanceof AudioExtractError) {
      return Response.json({ error: error.message }, { status: error.status });
    }
    console.error("link->mp3 failed", error);
    return Response.json({ error: "Could not convert that link." }, { status: 500 });
  }
}
