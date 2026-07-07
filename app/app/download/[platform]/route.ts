import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { Readable } from "node:stream";
import { isDownloadPlatform } from "@/lib/downloads";
import { getDownloadLink } from "@/lib/downloads-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/**
 * Public download endpoint. Redirects to the admin-configured external link, or
 * streams the uploaded binary from disk with a download disposition.
 */
export async function GET(
  _request: Request,
  context: { params: Promise<{ platform: string }> },
) {
  const { platform } = await context.params;
  if (!isDownloadPlatform(platform)) {
    return Response.json({ error: "Unknown platform." }, { status: 404 });
  }

  const link = await getDownloadLink(platform);
  if (!link) {
    return Response.json({ error: "No download configured." }, { status: 404 });
  }

  if (link.kind === "url" && link.externalUrl) {
    return Response.redirect(link.externalUrl, 302);
  }

  if (link.kind === "file" && link.filePath) {
    try {
      const info = await stat(link.filePath);
      const stream = Readable.toWeb(
        createReadStream(link.filePath),
      ) as unknown as ReadableStream<Uint8Array>;
      const downloadName = link.fileName || `stillora-${platform}`;
      return new Response(stream, {
        headers: {
          "Content-Type": link.contentType || "application/octet-stream",
          "Content-Length": String(info.size),
          "Content-Disposition": `attachment; filename="${downloadName.replace(/"/g, "")}"`,
          "Cache-Control": "public, max-age=300",
        },
      });
    } catch (error) {
      console.error("download stream failed:", error);
      return Response.json({ error: "Download is unavailable." }, { status: 404 });
    }
  }

  return Response.json({ error: "No download configured." }, { status: 404 });
}
