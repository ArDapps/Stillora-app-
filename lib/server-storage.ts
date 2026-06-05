import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

import type { StoredUpload } from "./stillora";

const STORAGE_ROOT = path.join(process.cwd(), "storage");
export const EXPORTS_ROOT = path.join(STORAGE_ROOT, "exports");

export type SaveUploadOptions = {
  file: File;
  folder: "images" | "videos" | "audio";
  allowedMimeTypes: Set<string>;
  maxBytes: number;
};

export async function saveUpload({
  file,
  folder,
  allowedMimeTypes,
  maxBytes,
}: SaveUploadOptions): Promise<StoredUpload> {
  if (!allowedMimeTypes.has(file.type)) {
    throw new UploadError("Unsupported file format.", 415);
  }

  if (file.size > maxBytes) {
    throw new UploadError("File is too large.", 413);
  }

  const id = crypto.randomUUID();
  const extension = getSafeExtension(file.name, file.type);
  const storedName = `${id}.${extension}`;
  const day = new Date().toISOString().slice(0, 10);
  const relativePath = path.join("uploads", folder, day, storedName);
  const absolutePath = path.join(STORAGE_ROOT, relativePath);

  await mkdir(path.dirname(absolutePath), { recursive: true });
  await writeFile(absolutePath, Buffer.from(await file.arrayBuffer()));

  return {
    id,
    originalName: file.name,
    storedName,
    relativePath,
    size: file.size,
    mimeType: file.type,
  };
}

export class UploadError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

export function getStoragePath(relativePath: string) {
  const absolutePath = path.join(STORAGE_ROOT, relativePath);
  const normalizedRoot = `${path.normalize(STORAGE_ROOT)}${path.sep}`;
  const normalizedPath = path.normalize(absolutePath);

  if (!normalizedPath.startsWith(normalizedRoot)) {
    throw new UploadError("Invalid storage path.", 400);
  }

  return normalizedPath;
}

function getSafeExtension(filename: string, mimeType: string) {
  const extension = filename.toLowerCase().split(".").pop()?.replace(/[^a-z0-9]/g, "");

  if (extension) {
    return extension;
  }

  switch (mimeType) {
    case "image/jpeg":
      return "jpg";
    case "image/png":
      return "png";
    case "image/webp":
      return "webp";
    case "audio/mpeg":
    case "audio/mp3":
      return "mp3";
    case "audio/wav":
    case "audio/x-wav":
      return "wav";
    case "audio/mp4":
      return "m4a";
    case "audio/aac":
      return "aac";
    case "audio/ogg":
      return "ogg";
    case "video/mp4":
      return "mp4";
    case "video/quicktime":
      return "mov";
    case "video/webm":
      return "webm";
    case "video/x-m4v":
      return "m4v";
    default:
      return "bin";
  }
}
