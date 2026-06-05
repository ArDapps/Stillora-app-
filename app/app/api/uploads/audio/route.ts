import {
  AUDIO_MIME_TYPES,
  MAX_AUDIO_BYTES,
} from "@/lib/stillora";
import { saveUpload, UploadError } from "@/lib/server-storage";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  try {
    const formData = await request.formData();
    const file = formData.get("file");

    if (!(file instanceof File)) {
      return Response.json({ error: "Audio file is required." }, { status: 400 });
    }

    const upload = await saveUpload({
      file,
      folder: "audio",
      allowedMimeTypes: AUDIO_MIME_TYPES,
      maxBytes: MAX_AUDIO_BYTES,
    });

    return Response.json({ upload }, { status: 201 });
  } catch (error) {
    if (error instanceof UploadError) {
      return Response.json({ error: error.message }, { status: error.status });
    }

    return Response.json({ error: "Audio upload failed." }, { status: 500 });
  }
}
