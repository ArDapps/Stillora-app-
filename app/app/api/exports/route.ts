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
  slides?: Array<{
    path: string;
    duration: number;
    width: number;
    height: number;
  }>;
  transition?: "none" | "fade";
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

    const audioPath = body.audioPath ? getStoragePath(body.audioPath) : null;
    const exportId = crypto.randomUUID();
    const day = new Date().toISOString().slice(0, 10);
    const outputDir = path.join(EXPORTS_ROOT, day);
    const outputPath = path.join(outputDir, `${exportId}.mp4`);

    await mkdir(outputDir, { recursive: true });

    const width = evenDimension(preset.width ?? body.imageWidth);
    const height = evenDimension(preset.height ?? body.imageHeight);

    if (body.slides?.length) {
      const slides = body.slides.map((slide) => ({
        ...slide,
        absolutePath: getStoragePath(slide.path),
        duration: normalizeSlideDuration(slide.duration),
      }));
      const totalDuration = slides.reduce((sum, slide) => sum + slide.duration, 0);

      if (totalDuration > MAX_VIDEO_DURATION_SECONDS) {
        return Response.json(
          { error: `Timeline must be ${MAX_VIDEO_DURATION_SECONDS} seconds or shorter.` },
          { status: 400 },
        );
      }

      await runFfmpeg(
        ffmpegBinary,
        buildSlideshowArgs({
          slides,
          audioPath,
          width,
          height,
          fitMode: body.fitMode,
          outputPath,
          transition: body.transition ?? "fade",
        }),
      );
    } else {
      const sourcePath = getStoragePath(body.sourcePath ?? body.imagePath ?? "");
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
    }

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

function buildSlideshowArgs({
  slides,
  audioPath,
  width,
  height,
  fitMode,
  outputPath,
  transition,
}: {
  slides: Array<{ absolutePath: string; duration: number }>;
  audioPath: string | null;
  width: number;
  height: number;
  fitMode: FitMode;
  outputPath: string;
  transition: "none" | "fade";
}) {
  const transitionDuration = transition === "fade" && slides.length > 1 ? 0.5 : 0;
  const args = ["-y"];

  slides.forEach((slide, index) => {
    const inputDuration =
      index < slides.length - 1 ? slide.duration + transitionDuration : slide.duration;
    args.push(
      "-loop",
      "1",
      "-framerate",
      "30",
      "-t",
      String(inputDuration),
      "-i",
      slide.absolutePath,
    );
  });

  if (audioPath) {
    args.push("-i", audioPath);
  }

  const scaleFilter = buildVideoFilter(width, height, fitMode);
  const preparedSlides = slides
    .map(
      (_slide, index) =>
        `[${index}:v]${scaleFilter},setsar=1,format=yuv420p[v${index}]`,
    )
    .join(";");
  let filterComplex = preparedSlides;
  let finalVideoLabel = `v${slides.length - 1}`;

  if (transitionDuration > 0) {
    let elapsed = slides[0].duration;
    let previousLabel = "v0";

    for (let index = 1; index < slides.length; index += 1) {
      const outputLabel = `x${index}`;
      const offset = Math.max(0, elapsed - transitionDuration * index);
      filterComplex += `;[${previousLabel}][v${index}]xfade=transition=fade:duration=${transitionDuration}:offset=${offset.toFixed(2)}[${outputLabel}]`;
      previousLabel = outputLabel;
      finalVideoLabel = outputLabel;
      elapsed += slides[index].duration;
    }
  } else if (slides.length > 1) {
    filterComplex += `;${slides.map((_slide, index) => `[v${index}]`).join("")}concat=n=${slides.length}:v=1:a=0[concatv]`;
    finalVideoLabel = "concatv";
  }

  args.push(
    "-filter_complex",
    filterComplex,
    "-map",
    `[${finalVideoLabel}]`,
    "-t",
    String(slides.reduce((sum, slide) => sum + slide.duration, 0)),
    "-c:v",
    "libx264",
    "-pix_fmt",
    "yuv420p",
    "-movflags",
    "+faststart",
  );

  if (audioPath) {
    args.push("-map", `${slides.length}:a:0`, "-c:a", "aac", "-shortest");
  } else {
    args.push("-an");
  }

  args.push(outputPath);

  return args;
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

function normalizeSlideDuration(duration: number) {
  if (!Number.isFinite(duration)) {
    return 1;
  }

  return Math.min(Math.max(duration, 0.25), MAX_VIDEO_DURATION_SECONDS);
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
