import {
  IMAGE_MIME_TYPES,
  MAX_IMAGE_BYTES,
} from "@/lib/stillora";
import { saveUpload, UploadError } from "@/lib/server-storage";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  try {
    const formData = await request.formData();
    const file = formData.get("file");

    if (!(file instanceof File)) {
      return Response.json({ error: "Image file is required." }, { status: 400 });
    }

    const upload = await saveUpload({
      file,
      folder: "images",
      allowedMimeTypes: IMAGE_MIME_TYPES,
      maxBytes: MAX_IMAGE_BYTES,
    });

    return Response.json({ upload }, { status: 201 });
  } catch (error) {
    if (error instanceof UploadError) {
      return Response.json({ error: error.message }, { status: error.status });
    }

    return Response.json({ error: "Image upload failed." }, { status: 500 });
  }
}
