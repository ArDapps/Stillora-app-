import { spawn } from "node:child_process";
import path from "node:path";

import { getFfmpegPath } from "../ffmpeg";
import { RenderError } from "./options";

export function encodeFrames(
  workDir: string,
  outputPath: string,
  fps: number,
  audioPath?: string,
) {
  const args = [
    "-y",
    "-framerate",
    String(fps),
    "-i",
    path.join(workDir, "frame_%05d.jpg"),
  ];
  // Second input: the optional soundtrack. `-shortest` ends the mux at the
  // shorter of {video, audio} so a long track can't pad the clip with silence.
  if (audioPath) {
    args.push("-i", audioPath);
  }
  args.push(
    "-c:v",
    "libx264",
    "-preset",
    "veryfast",
    "-pix_fmt",
    "yuv420p",
  );
  if (audioPath) {
    args.push(
      "-map",
      "0:v:0",
      "-map",
      "1:a:0",
      "-c:a",
      "aac",
      "-b:a",
      "192k",
      "-shortest",
    );
  }
  args.push("-movflags", "+faststart", outputPath);
  return runFfmpeg(getFfmpegPath(), args);
}

function runFfmpeg(binaryPath: string, args: string[]) {
  return new Promise<void>((resolve, reject) => {
    const proc = spawn(binaryPath, args);
    let errorOutput = "";
    proc.stderr.on("data", (chunk: Buffer) => {
      errorOutput += chunk.toString();
    });
    proc.on("error", reject);
    proc.on("close", (code) => {
      if (code === 0) {
        resolve();
        return;
      }
      reject(new RenderError(errorOutput || `FFmpeg exited with code ${code}.`, 500));
    });
  });
}
