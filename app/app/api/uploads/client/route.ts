import { handleUpload, type HandleUploadBody } from "@vercel/blob/client";

import {
  AUDIO_MIME_TYPES,
  IMAGE_MIME_TYPES,
  MAX_AUDIO_BYTES,
  MAX_IMAGE_BYTES,
  MAX_SOURCE_VIDEO_BYTES,
  VIDEO_MIME_TYPES,
} from "@/lib/stillora";
import { UploadError } from "@/lib/server-storage";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as HandleUploadBody;
    const response = await handleUpload({
      body,
      request,
      onBeforeGenerateToken: async (pathname) => {
        const folder = getFolderFromPathname(pathname);

        return {
          allowedContentTypes: [...getAllowedMimeTypes(folder)],
          maximumSizeInBytes: getMaxBytes(folder),
          addRandomSuffix: false,
        };
      },
      onUploadCompleted: async () => undefined,
    });

    return Response.json(response);
  } catch (error) {
    if (error instanceof UploadError) {
      return Response.json({ error: error.message }, { status: error.status });
    }

    return Response.json(
      { error: error instanceof Error ? error.message : "Upload setup failed." },
      { status: 400 },
    );
  }
}

function getFolderFromPathname(pathname: string) {
  const match = /^uploads\/(images|videos|audio)\/\d{4}-\d{2}-\d{2}\/[0-9a-f-]+\.[a-z0-9]+$/i.exec(
    pathname,
  );

  if (!match) {
    throw new UploadError("Invalid upload path.", 400);
  }

  return match[1] as "images" | "videos" | "audio";
}

function getAllowedMimeTypes(folder: "images" | "videos" | "audio") {
  if (folder === "images") {
    return IMAGE_MIME_TYPES;
  }

  if (folder === "videos") {
    return VIDEO_MIME_TYPES;
  }

  return AUDIO_MIME_TYPES;
}

function getMaxBytes(folder: "images" | "videos" | "audio") {
  if (folder === "images") {
    return MAX_IMAGE_BYTES;
  }

  if (folder === "videos") {
    return MAX_SOURCE_VIDEO_BYTES;
  }

  return MAX_AUDIO_BYTES;
}
