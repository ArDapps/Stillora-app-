import type { StoredUpload } from "./stillora";

export type SaveUploadOptions = {
  file: File;
  folder: "images" | "videos" | "audio";
  allowedMimeTypes: Set<string>;
  maxBytes: number;
};

export async function saveUpload({
  file,
  allowedMimeTypes,
  maxBytes,
}: SaveUploadOptions): Promise<StoredUpload> {
  validateUpload(file, allowedMimeTypes, maxBytes);

  throw new UploadError("Files are processed only during export and are not saved.", 410);
}

export function validateUpload(
  file: File,
  allowedMimeTypes: Set<string>,
  maxBytes: number,
) {
  if (!allowedMimeTypes.has(file.type)) {
    throw new UploadError("Unsupported file format.", 415);
  }

  if (file.size > maxBytes) {
    throw new UploadError("File is too large.", 413);
  }
}

export class UploadError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}
