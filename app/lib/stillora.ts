export type OutputPresetId =
  | "original"
  | "reels"
  | "youtube-shorts"
  | "youtube-long"
  | "square";

export type FitMode = "fit" | "fill";
export type SourceMediaKind = "image" | "video";

export type OutputPreset = {
  id: OutputPresetId;
  name: string;
  details: string;
  width: number | null;
  height: number | null;
  aspectRatio: number | null;
  orientation: string;
};

export type StoredUpload = {
  id: string;
  originalName: string;
  storedName: string;
  relativePath: string;
  size: number;
  mimeType: string;
  url?: string;
  downloadUrl?: string;
  storage?: "local" | "blob";
};

export const OUTPUT_PRESETS: OutputPreset[] = [
  {
    id: "reels",
    name: "Reels / TikTok / Stories",
    details: "1080 x 1920 - 9:16 Vertical",
    width: 1080,
    height: 1920,
    aspectRatio: 9 / 16,
    orientation: "Vertical",
  },
  {
    id: "youtube-shorts",
    name: "YouTube Shorts",
    details: "1080 x 1920 - 9:16 Vertical",
    width: 1080,
    height: 1920,
    aspectRatio: 9 / 16,
    orientation: "Vertical",
  },
  {
    id: "youtube-long",
    name: "YouTube Long Video",
    details: "1920 x 1080 - 16:9 Landscape",
    width: 1920,
    height: 1080,
    aspectRatio: 16 / 9,
    orientation: "Landscape",
  },
  {
    id: "square",
    name: "Square Post",
    details: "1080 x 1080 - 1:1 Square",
    width: 1080,
    height: 1080,
    aspectRatio: 1,
    orientation: "Square",
  },
  {
    id: "original",
    name: "Original Image Size",
    details: "Preserve uploaded dimensions",
    width: null,
    height: null,
    aspectRatio: null,
    orientation: "Original",
  },
];

export const IMAGE_ACCEPT = ".jpg,.jpeg,.png,.webp";
export const VIDEO_ACCEPT = ".mp4,.mov,.webm,.m4v";
export const MEDIA_ACCEPT = `${IMAGE_ACCEPT},${VIDEO_ACCEPT}`;
export const AUDIO_ACCEPT = ".mp3,.wav,.m4a,.aac,.ogg";

export const MAX_UPLOAD_BYTES = 200 * 1024 * 1024;
export const MAX_IMAGE_BYTES = MAX_UPLOAD_BYTES;
export const MAX_SOURCE_VIDEO_BYTES = 200 * 1024 * 1024;
export const MAX_AUDIO_BYTES = MAX_UPLOAD_BYTES;
export const DEFAULT_DURATION_SECONDS = 10;
export const FIXED_DURATION_SECONDS = [10, 20, 30, 40, 50, 60] as const;
export const MAX_VIDEO_DURATION_SECONDS = 300;

export const IMAGE_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
]);

export const VIDEO_MIME_TYPES = new Set([
  "video/mp4",
  "video/quicktime",
  "video/webm",
  "video/x-m4v",
]);

export const SOURCE_MEDIA_MIME_TYPES = new Set([
  ...IMAGE_MIME_TYPES,
  ...VIDEO_MIME_TYPES,
]);

export const AUDIO_MIME_TYPES = new Set([
  "audio/mpeg",
  "audio/mp3",
  "audio/wav",
  "audio/x-wav",
  "audio/mp4",
  "audio/aac",
  "audio/ogg",
]);

export function formatBytes(bytes: number) {
  if (bytes < 1024) {
    return `${bytes} B`;
  }

  const units = ["KB", "MB", "GB"];
  let value = bytes / 1024;
  let unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }

  return `${value.toFixed(value >= 10 ? 1 : 2)} ${units[unitIndex]}`;
}

export function getFileExtension(filename: string) {
  const extension = filename.split(".").pop();

  return extension ? extension.toUpperCase() : "Unknown";
}

export function createUploadStoragePath({
  id,
  filename,
  mimeType,
  folder,
  day = new Date().toISOString().slice(0, 10),
}: {
  id: string;
  filename: string;
  mimeType: string;
  folder: "images" | "videos" | "audio";
  day?: string;
}) {
  const extension = getSafeExtension(filename, mimeType);

  return {
    storedName: `${id}.${extension}`,
    relativePath: `uploads/${folder}/${day}/${id}.${extension}`,
  };
}

export function getSafeExtension(filename: string, mimeType: string) {
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

export function getPreviewAspectRatio(
  preset: OutputPreset,
  imageDimensions: { width: number; height: number } | null,
) {
  if (preset.aspectRatio) {
    return preset.aspectRatio;
  }

  if (imageDimensions) {
    return imageDimensions.width / imageDimensions.height;
  }

  return 9 / 16;
}
