import { existsSync } from "node:fs";
import path from "node:path";
import ffmpegPath from "ffmpeg-static";

export function getFfmpegPath() {
  // In the Docker image ffmpeg is installed via apt (FFMPEG_PATH); in local dev
  // it comes from the ffmpeg-static download. Fall through both, then rely on
  // PATH so the spawn still works if only a system ffmpeg is available.
  const envPath = process.env.FFMPEG_PATH;
  if (envPath && existsSync(envPath)) {
    return envPath;
  }

  if (
    ffmpegPath &&
    ffmpegPath !== "/ROOT/node_modules/ffmpeg-static/ffmpeg" &&
    existsSync(ffmpegPath)
  ) {
    return ffmpegPath;
  }

  const localBinary = path.join(
    process.cwd(),
    "node_modules",
    "ffmpeg-static",
    "ffmpeg",
  );
  if (existsSync(localBinary)) {
    return localBinary;
  }

  return envPath ?? "ffmpeg";
}
