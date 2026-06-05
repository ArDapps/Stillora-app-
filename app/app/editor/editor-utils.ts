import { MAX_VIDEO_DURATION_SECONDS } from "@/lib/stillora";

export function getAudioFitDuration(duration: number) {
  return Math.min(Math.max(Math.ceil(duration), 1), MAX_VIDEO_DURATION_SECONDS);
}

export function formatDuration(duration: number) {
  const roundedDuration = Math.ceil(duration);
  const minutes = Math.floor(roundedDuration / 60);
  const seconds = roundedDuration % 60;

  if (minutes === 0) {
    return `${seconds}s`;
  }

  return `${minutes}:${seconds.toString().padStart(2, "0")}`;
}

export async function uploadFile(_endpoint: string, file: File) {
  const id = crypto.randomUUID();

  return {
    id,
    originalName: file.name,
    storedName: file.name,
    relativePath: id,
    size: file.size,
    mimeType: file.type,
    storage: "local" as const,
  };
}

export async function readImageDimensions(url: string) {
  return new Promise<{ width: number; height: number } | null>((resolve) => {
    const image = new Image();

    image.onload = () => resolve({ width: image.naturalWidth, height: image.naturalHeight });
    image.onerror = () => resolve(null);
    image.src = url;
  });
}

export async function readVideoMetadata(url: string) {
  return new Promise<{ width: number; height: number; duration: number | null } | null>((resolve) => {
    const video = document.createElement("video");

    video.onloadedmetadata = () =>
      resolve({
        width: video.videoWidth,
        height: video.videoHeight,
        duration: Number.isFinite(video.duration) ? video.duration : null,
      });
    video.onerror = () => resolve(null);
    video.preload = "metadata";
    video.src = url;
  });
}

export async function readAudioDuration(url: string) {
  return new Promise<number | null>((resolve) => {
    const audio = document.createElement("audio");

    audio.onloadedmetadata = () =>
      resolve(Number.isFinite(audio.duration) ? audio.duration : null);
    audio.onerror = () => resolve(null);
    audio.src = url;
  });
}
