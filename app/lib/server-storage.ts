import { createReadStream, createWriteStream } from "node:fs";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import type { ReadableStream as NodeReadableStream } from "node:stream/web";

import { get, put } from "@vercel/blob";

import {
  createUploadStoragePath,
  type StoredUpload,
} from "./stillora";

const STORAGE_ROOT = path.join(process.cwd(), "storage");
export const EXPORTS_ROOT = path.join(STORAGE_ROOT, "exports");
const BLOB_ACCESS = "public" as const;

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
  validateUpload(file, allowedMimeTypes, maxBytes);

  const id = crypto.randomUUID();
  const { storedName, relativePath } = createUploadStoragePath({
    id,
    filename: file.name,
    mimeType: file.type,
    folder,
  });
  const body = Buffer.from(await file.arrayBuffer());

  if (isBlobStorageEnabled()) {
    const blob = await put(relativePath, body, {
      access: BLOB_ACCESS,
      contentType: file.type,
      multipart: file.size > 4 * 1024 * 1024,
    });

    return {
      id,
      originalName: file.name,
      storedName,
      relativePath: blob.pathname,
      size: file.size,
      mimeType: file.type,
      url: blob.url,
      downloadUrl: blob.downloadUrl,
      storage: "blob",
    };
  }

  const absolutePath = getLocalStoragePath(relativePath);

  await mkdir(path.dirname(absolutePath), { recursive: true });
  await writeFile(absolutePath, body);

  return {
    id,
    originalName: file.name,
    storedName,
    relativePath,
    size: file.size,
    mimeType: file.type,
    storage: "local",
  };
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

export async function materializeStoredFile(relativePath: string, workDir: string) {
  assertSafeStoragePath(relativePath);

  if (!isBlobStorageEnabled()) {
    return getLocalStoragePath(relativePath);
  }

  const blob = await get(relativePath, {
    access: BLOB_ACCESS,
    useCache: false,
  });

  if (!blob || blob.statusCode !== 200 || !blob.stream) {
    throw new UploadError("Uploaded media was not found.", 404);
  }

  await mkdir(workDir, { recursive: true });

  const filename = path.basename(relativePath);
  const localPath = path.join(workDir, filename);

  await pipeline(
    Readable.fromWeb(blob.stream as unknown as NodeReadableStream<Uint8Array>),
    createWriteStream(localPath),
  );

  return localPath;
}

export async function createExportOutputPath(day: string, exportId: string) {
  if (isBlobStorageEnabled()) {
    const outputDir = path.join(tmpdir(), "stillora-exports", day);
    await mkdir(outputDir, { recursive: true });

    return path.join(outputDir, `${exportId}.mp4`);
  }

  const outputDir = path.join(EXPORTS_ROOT, day);
  await mkdir(outputDir, { recursive: true });

  return path.join(outputDir, `${exportId}.mp4`);
}

export async function saveExport(outputPath: string, blobPath: string) {
  assertSafeStoragePath(blobPath);

  if (!isBlobStorageEnabled()) {
    return null;
  }

  return put(blobPath, createReadStream(outputPath), {
    access: BLOB_ACCESS,
    contentType: "video/mp4",
    multipart: true,
  });
}

export async function readExport(day: string, exportId: string) {
  const relativePath = getExportStoragePath(day, exportId);

  if (isBlobStorageEnabled()) {
    const blob = await get(relativePath, {
      access: BLOB_ACCESS,
      useCache: false,
    });

    if (!blob || blob.statusCode !== 200 || !blob.stream) {
      return null;
    }

    return {
      body: blob.stream,
      contentType: blob.blob.contentType ?? "video/mp4",
    };
  }

  try {
    return {
      body: await readFile(path.join(EXPORTS_ROOT, day, `${exportId}.mp4`)),
      contentType: "video/mp4",
    };
  } catch {
    return null;
  }
}

export function getExportStoragePath(day: string, exportId: string) {
  return `exports/${day}/${exportId}.mp4`;
}

export function isBlobStorageEnabled() {
  return Boolean(process.env.BLOB_READ_WRITE_TOKEN);
}

export class UploadError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

function getLocalStoragePath(relativePath: string) {
  assertSafeStoragePath(relativePath);

  return path.join(STORAGE_ROOT, relativePath);
}

function assertSafeStoragePath(relativePath: string) {
  const normalized = path.posix.normalize(relativePath.replaceAll("\\", "/"));

  if (
    normalized.startsWith("../") ||
    normalized === ".." ||
    path.posix.isAbsolute(normalized) ||
    normalized !== relativePath.replaceAll("\\", "/")
  ) {
    throw new UploadError("Invalid storage path.", 400);
  }
}
