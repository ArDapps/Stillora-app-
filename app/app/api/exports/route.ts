import { mkdir } from "node:fs/promises";
import path from "node:path";
import { spawn } from "node:child_process";

import ffmpegPath from "ffmpeg-static";

import {
  FitMode,
  MAX_VIDEO_DURATION_SECONDS,
  OUTPUT_PRESETS,
  OutputPresetId,
  SourceMediaKind,
} from "@/lib/stillora";
import {
  EXPORTS_ROOT,
  getStoragePath,
} from "@/lib/server-storage";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type ExportRequest = {
  sourcePath?: string;
  sourceKind?: SourceMediaKind;
  imagePath?: string;
  audioPath?: string | null;
  presetId: OutputPresetId;
  fitMode: FitMode;
  duration: number;
  imageWidth: number;
  imageHeight: number;
};

export async function POST(request: Request) {
  try {
    const ffmpegBinary = getFfmpegPath();

    if (!ffmpegBinary) {
      return Response.json({ error: "FFmpeg is not available." }, { status: 500 });
    }

    const body = (await request.json()) as ExportRequest;
    const preset = OUTPUT_PRESETS.find((item) => item.id === body.presetId);

    if (!preset) {
      return Response.json({ error: "Invalid output preset." }, { status: 400 });
    }

    const duration = Number(body.duration);

    if (
      !Number.isFinite(duration) ||
      duration <= 0 ||
      duration > MAX_VIDEO_DURATION_SECONDS
    ) {
      return Response.json(
        { error: `Duration must be between 1 and ${MAX_VIDEO_DURATION_SECONDS} seconds.` },
        { status: 400 },
      );
    }

    const sourceKind = body.sourceKind ?? "image";

    if (!["image", "video"].includes(sourceKind)) {
      return Response.json({ error: "Invalid source media type." }, { status: 400 });
    }

    const sourcePath = getStoragePath(body.sourcePath ?? body.imagePath ?? "");
    const audioPath = body.audioPath ? getStoragePath(body.audioPath) : null;
    const exportId = crypto.randomUUID();
    const day = new Date().toISOString().slice(0, 10);
    const outputDir = path.join(EXPORTS_ROOT, day);
    const outputPath = path.join(outputDir, `${exportId}.mp4`);

    await mkdir(outputDir, { recursive: true });

    const width = evenDimension(preset.width ?? body.imageWidth);
    const height = evenDimension(preset.height ?? body.imageHeight);
    const videoFilter = buildVideoFilter(width, height, body.fitMode);
    const args = ["-y"];

    if (sourceKind === "image") {
      args.push("-loop", "1", "-framerate", "30", "-i", sourcePath);
    } else {
      args.push("-stream_loop", "-1", "-i", sourcePath);
    }

    if (audioPath) {
      args.push("-i", audioPath);
    }

    args.push(
      "-t",
      String(duration),
      "-vf",
      videoFilter,
      "-map",
      "0:v:0",
      "-c:v",
      "libx264",
      "-pix_fmt",
      "yuv420p",
      "-movflags",
      "+faststart",
    );

    if (audioPath) {
      args.push("-map", "1:a:0", "-c:a", "aac");
    } else if (sourceKind === "video") {
      args.push("-map", "0:a:0?", "-c:a", "aac");
    } else {
      args.push("-an");
    }

    args.push(outputPath);

    await runFfmpeg(ffmpegBinary, args);

    return Response.json(
      {
        export: {
          id: exportId,
          filename: `stillora-${exportId}.mp4`,
          downloadUrl: `/api/exports/${exportId}/download?day=${day}`,
        },
      },
      { status: 201 },
    );
  } catch (error) {
    return Response.json(
      {
        error: error instanceof Error ? error.message : "Export failed.",
      },
      { status: 500 },
    );
  }
}

function buildVideoFilter(width: number, height: number, fitMode: FitMode) {
  if (fitMode === "fill") {
    return `scale=${width}:${height}:force_original_aspect_ratio=increase,crop=${width}:${height}`;
  }

  return `scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2:color=0x111827`;
}

function evenDimension(value: number) {
  return value % 2 === 0 ? value : value + 1;
}

function runFfmpeg(binaryPath: string, args: string[]) {
  return new Promise<void>((resolve, reject) => {
    const process = spawn(binaryPath, args);
    let errorOutput = "";

    process.stderr.on("data", (chunk: Buffer) => {
      errorOutput += chunk.toString();
    });

    process.on("error", reject);
    process.on("close", (code) => {
      if (code === 0) {
        resolve();
        return;
      }

      reject(new Error(errorOutput || `FFmpeg exited with code ${code}.`));
    });
  });
}

function getFfmpegPath() {
  const localBinary = path.join(process.cwd(), "node_modules", "ffmpeg-static", "ffmpeg");

  if (ffmpegPath && ffmpegPath !== "/ROOT/node_modules/ffmpeg-static/ffmpeg") {
    return ffmpegPath;
  }

  return localBinary;
}
