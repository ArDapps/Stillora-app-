import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { spawn } from "node:child_process";

import ffmpegPath from "ffmpeg-static";

import {
  AUDIO_MIME_TYPES,
  FitMode,
  MAX_VIDEO_DURATION_SECONDS,
  MAX_UPLOAD_BYTES,
  OUTPUT_PRESETS,
  OutputPresetId,
  SOURCE_MEDIA_MIME_TYPES,
  SourceMediaKind,
} from "@/lib/stillora";
import { getUserFromRequest } from "@/lib/auth";
import { recordExport } from "@/lib/admin-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type ExportRequest = {
  sourceKind?: SourceMediaKind;
  slides?: Array<{
    kind?: SourceMediaKind;
    duration: number;
    width: number;
    height: number;
  }>;
  transition?: "none" | "fade";
  presetId: OutputPresetId;
  fitMode: FitMode;
  duration: number;
  imageWidth: number;
  imageHeight: number;
};

export async function POST(request: Request) {
  let workDir: string | null = null;

  try {
    const user = await getUserFromRequest(request);

    if (!user) {
      return Response.json(
        { error: "Sign in with Google to export your video." },
        { status: 401 },
      );
    }

    const ffmpegBinary = getFfmpegPath();

    if (!ffmpegBinary) {
      return Response.json({ error: "FFmpeg is not available." }, { status: 500 });
    }

    const formData = await request.formData();
    const metadataValue = formData.get("metadata");

    if (typeof metadataValue !== "string") {
      return Response.json({ error: "Export metadata is required." }, { status: 400 });
    }

    const body = JSON.parse(metadataValue) as ExportRequest;
    const preset = OUTPUT_PRESETS.find((item) => item.id === body.presetId);

    if (!preset) {
      return Response.json({ error: "Invalid output preset." }, { status: 400 });
    }

    const duration = Number(body.duration);
    const isSlideshow = Boolean(body.slides?.length);

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

    const exportId = crypto.randomUUID();
    workDir = path.join("/tmp", "stillora-work", exportId);
    await mkdir(workDir, { recursive: true });
    const activeWorkDir = workDir;

    const uploadedFiles = getUploadedFiles(formData);
    const totalBytes = uploadedFiles.reduce((sum, file) => sum + file.size, 0);

    if (totalBytes > MAX_UPLOAD_BYTES) {
      return Response.json({ error: "Total media must be 200 MB or smaller." }, { status: 413 });
    }

    const audioFile = getOptionalFile(formData, "audio");
    const audioPath = audioFile
      ? await writeTempFile(audioFile, activeWorkDir, "audio", AUDIO_MIME_TYPES)
      : null;
    const outputPath = path.join(activeWorkDir, `${exportId}.mp4`);

    const width = evenDimension(preset.width ?? body.imageWidth);
    const height = evenDimension(preset.height ?? body.imageHeight);

    if (isSlideshow && body.slides?.length) {
      const slides = body.slides.map((slide) => ({
        ...slide,
        kind: slide.kind === "video" ? ("video" as const) : ("image" as const),
        duration: normalizeSlideDuration(slide.duration),
      }));
      const materializedSlides = await Promise.all(
        slides.map(async (slide, index) => ({
          ...slide,
          absolutePath: await writeTempFile(
            getRequiredFile(formData, `slide-${index}`),
            activeWorkDir,
            `slide-${index}`,
            SOURCE_MEDIA_MIME_TYPES,
          ),
        })),
      );
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
          slides: materializedSlides,
          audioPath,
          width,
          height,
          fitMode: body.fitMode,
          outputPath,
          transition: body.transition ?? "fade",
        }),
      );
    } else {
      const sourcePath = await writeTempFile(
        getRequiredFile(formData, "source"),
        activeWorkDir,
        "source",
        SOURCE_MEDIA_MIME_TYPES,
      );
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

    const video = await readFile(outputPath);
    void recordExport(user, { presetId: body.presetId, duration });

    return new Response(video, {
      status: 201,
      headers: {
        "Content-Disposition": `attachment; filename="stillora-${exportId}.mp4"`,
        "Content-Type": "video/mp4",
        "X-Export-Filename": `stillora-${exportId}.mp4`,
      },
    });
  } catch (error) {
    return Response.json(
      {
        error: error instanceof Error ? error.message : "Export failed.",
      },
      { status: 500 },
    );
  } finally {
    if (workDir) {
      await rm(workDir, { recursive: true, force: true });
    }
  }
}

function getUploadedFiles(formData: FormData) {
  return Array.from(formData.values()).filter((value): value is File => value instanceof File);
}

function getRequiredFile(formData: FormData, name: string) {
  const file = formData.get(name);

  if (!(file instanceof File)) {
    throw new Error(`${name} file is required.`);
  }

  return file;
}

function getOptionalFile(formData: FormData, name: string) {
  const file = formData.get(name);

  return file instanceof File ? file : null;
}

async function writeTempFile(
  file: File,
  workDir: string,
  basename: string,
  allowedMimeTypes: Set<string>,
) {
  if (!allowedMimeTypes.has(file.type)) {
    throw new Error("Unsupported file format.");
  }

  if (file.size > MAX_UPLOAD_BYTES) {
    throw new Error("Each file must be 200 MB or smaller.");
  }

  const extension = file.name.split(".").pop()?.replace(/[^a-z0-9]/gi, "").toLowerCase() || "bin";
  const filePath = path.join(workDir, `${basename}.${extension}`);

  await writeFile(filePath, Buffer.from(await file.arrayBuffer()));

  return filePath;
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
  slides: Array<{ absolutePath: string; duration: number; kind: "image" | "video" }>;
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
    if (slide.kind === "video") {
      // Loop short clips and trim long ones so each segment fills its timeline slot.
      args.push("-stream_loop", "-1", "-t", String(inputDuration), "-i", slide.absolutePath);
    } else {
      args.push("-loop", "1", "-framerate", "30", "-t", String(inputDuration), "-i", slide.absolutePath);
    }
  });

  if (audioPath) {
    args.push("-i", audioPath);
  }

  const scaleFilter = buildVideoFilter(width, height, fitMode);
  // Normalize fps, sample aspect, format and timestamps so image and video segments can be joined and crossfaded.
  const preparedSlides = slides
    .map(
      (_slide, index) =>
        `[${index}:v]${scaleFilter},setsar=1,fps=30,format=yuv420p,setpts=PTS-STARTPTS[v${index}]`,
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
    args.push("-map", `${slides.length}:a:0`, "-c:a", "aac");
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

  const localBinary = path.join(process.cwd(), "node_modules", "ffmpeg-static", "ffmpeg");
  if (existsSync(localBinary)) {
    return localBinary;
  }

  return envPath ?? "ffmpeg";
}
