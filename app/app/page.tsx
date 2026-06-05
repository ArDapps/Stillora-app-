"use client";

import {
  Clock,
  Download,
  FileAudio,
  FileImage,
  ImagePlus,
  Loader2,
  Pause,
  Play,
  Sparkles,
  Trash2,
  UploadCloud,
  Wand2,
} from "lucide-react";
import { ChangeEvent, DragEvent, useEffect, useMemo, useRef, useState } from "react";
import {
  AUDIO_ACCEPT,
  AUDIO_MIME_TYPES,
  DEFAULT_DURATION_SECONDS,
  FitMode,
  FIXED_DURATION_SECONDS,
  getFileExtension,
  getPreviewAspectRatio,
  IMAGE_ACCEPT,
  IMAGE_MIME_TYPES,
  MAX_AUDIO_BYTES,
  MAX_IMAGE_BYTES,
  MAX_VIDEO_DURATION_SECONDS,
  OUTPUT_PRESETS,
  OutputPresetId,
  StoredUpload,
  formatBytes,
} from "@/lib/stillora";

type ImageAsset = {
  file: File;
  url: string;
  width: number;
  height: number;
};

type AudioAsset = {
  file: File;
  url: string;
  duration: number | null;
};

type UploadState = {
  status: "idle" | "uploading" | "saved" | "failed";
  upload: StoredUpload | null;
  error: string;
};

type ExportResult = {
  id: string;
  filename: string;
  downloadUrl: string;
};

const emptyUploadState: UploadState = { status: "idle", upload: null, error: "" };

export default function Home() {
  const imageInputRef = useRef<HTMLInputElement>(null);
  const audioInputRef = useRef<HTMLInputElement>(null);
  const audioRef = useRef<HTMLAudioElement>(null);
  const [imageAsset, setImageAsset] = useState<ImageAsset | null>(null);
  const [audioAsset, setAudioAsset] = useState<AudioAsset | null>(null);
  const [presetId, setPresetId] = useState<OutputPresetId>("reels");
  const [fitMode, setFitMode] = useState<FitMode>("fit");
  const [duration, setDuration] = useState(DEFAULT_DURATION_SECONDS);
  const [imageError, setImageError] = useState("");
  const [audioError, setAudioError] = useState("");
  const [imageUpload, setImageUpload] = useState<UploadState>(emptyUploadState);
  const [audioUpload, setAudioUpload] = useState<UploadState>(emptyUploadState);
  const [isAudioPlaying, setIsAudioPlaying] = useState(false);
  const [exportStatus, setExportStatus] = useState<"idle" | "exporting" | "ready">("idle");
  const [exportProgress, setExportProgress] = useState(0);
  const [exportResult, setExportResult] = useState<ExportResult | null>(null);
  const [exportError, setExportError] = useState("");

  const selectedPreset = useMemo(
    () => OUTPUT_PRESETS.find((preset) => preset.id === presetId) ?? OUTPUT_PRESETS[0],
    [presetId],
  );

  const previewAspectRatio = getPreviewAspectRatio(
    selectedPreset,
    imageAsset ? { width: imageAsset.width, height: imageAsset.height } : null,
  );
  const previewFrameWidth = useMemo(
    () => Math.max(48, Math.min(760, Math.round(560 * previewAspectRatio))),
    [previewAspectRatio],
  );

  const outputDimensions = useMemo(() => {
    if (selectedPreset.id !== "original") {
      return `${selectedPreset.width} x ${selectedPreset.height}`;
    }

    if (!imageAsset) {
      return "Upload image";
    }

    const width = imageAsset.width % 2 === 0 ? imageAsset.width : imageAsset.width + 1;
    const height = imageAsset.height % 2 === 0 ? imageAsset.height : imageAsset.height + 1;

    return `${width} x ${height}`;
  }, [imageAsset, selectedPreset]);

  useEffect(() => {
    return () => {
      if (imageAsset) {
        URL.revokeObjectURL(imageAsset.url);
      }
    };
  }, [imageAsset]);

  useEffect(() => {
    return () => {
      if (audioAsset) {
        URL.revokeObjectURL(audioAsset.url);
      }
    };
  }, [audioAsset]);

  async function handleImageFile(file: File | undefined) {
    setImageError("");
    setImageUpload(emptyUploadState);
    setExportStatus("idle");
    setExportProgress(0);
    setExportResult(null);
    setExportError("");

    if (!file) {
      return;
    }

    if (!IMAGE_MIME_TYPES.has(file.type)) {
      setImageError("Use a JPG, PNG, or WebP image.");
      return;
    }

    if (file.size > MAX_IMAGE_BYTES) {
      setImageError("Image must be 20 MB or smaller.");
      return;
    }

    const url = URL.createObjectURL(file);
    const dimensions = await readImageDimensions(url);

    if (!dimensions) {
      URL.revokeObjectURL(url);
      setImageError("This image could not be read. Try another file.");
      return;
    }

    if (imageAsset) {
      URL.revokeObjectURL(imageAsset.url);
    }

    setImageAsset({ file, url, ...dimensions });
    void uploadSelectedFile("/api/uploads/image", file, setImageUpload);
  }

  async function handleAudioFile(file: File | undefined) {
    setAudioError("");
    setAudioUpload(emptyUploadState);
    setIsAudioPlaying(false);

    if (!file) {
      return;
    }

    if (!AUDIO_MIME_TYPES.has(file.type)) {
      setAudioError("Use an MP3, WAV, M4A, AAC, or OGG audio file.");
      return;
    }

    if (file.size > MAX_AUDIO_BYTES) {
      setAudioError("Audio must be 50 MB or smaller.");
      return;
    }

    const url = URL.createObjectURL(file);
    const audioDuration = await readAudioDuration(url);

    if (audioAsset) {
      URL.revokeObjectURL(audioAsset.url);
    }

    setAudioAsset({ file, url, duration: audioDuration });
    if (audioDuration) {
      setDuration(getAudioFitDuration(audioDuration));
      setExportStatus("idle");
      setExportProgress(0);
      setExportResult(null);
      setExportError("");
    }
    void uploadSelectedFile("/api/uploads/audio", file, setAudioUpload);
  }

  function removeImage() {
    if (imageAsset) {
      URL.revokeObjectURL(imageAsset.url);
    }

    setImageAsset(null);
    setImageUpload(emptyUploadState);
    setExportStatus("idle");
    setExportProgress(0);
    setExportResult(null);
    setExportError("");
  }

  function removeAudio() {
    if (audioAsset) {
      URL.revokeObjectURL(audioAsset.url);
    }

    setAudioAsset(null);
    setAudioUpload(emptyUploadState);
    setIsAudioPlaying(false);
    if (!FIXED_DURATION_SECONDS.includes(duration as 10 | 30)) {
      setDuration(DEFAULT_DURATION_SECONDS);
    }
    setExportStatus("idle");
    setExportProgress(0);
    setExportResult(null);
    setExportError("");
  }

  function onImageDrop(event: DragEvent<HTMLButtonElement>) {
    event.preventDefault();
    void handleImageFile(event.dataTransfer.files[0]);
  }

  function onAudioDrop(event: DragEvent<HTMLButtonElement>) {
    event.preventDefault();
    void handleAudioFile(event.dataTransfer.files[0]);
  }

  async function startExport() {
    if (
      !imageAsset ||
      !imageUpload.upload ||
      (audioAsset && !audioUpload.upload) ||
      exportStatus === "exporting"
    ) {
      return;
    }

    setExportProgress(20);
    setExportStatus("exporting");
    setExportResult(null);
    setExportError("");

    try {
      const response = await fetch("/api/exports", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          imagePath: imageUpload.upload.relativePath,
          audioPath: audioUpload.upload?.relativePath ?? null,
          presetId,
          fitMode,
          duration,
          imageWidth: imageAsset.width,
          imageHeight: imageAsset.height,
        }),
      });
      const payload = (await response.json()) as {
        export?: ExportResult;
        error?: string;
      };

      if (!response.ok || !payload.export) {
        throw new Error(payload.error ?? "Export failed.");
      }

      setExportProgress(100);
      setExportResult(payload.export);
      setExportStatus("ready");
    } catch (error) {
      setExportStatus("idle");
      setExportProgress(0);
      setExportError(error instanceof Error ? error.message : "Export failed.");
    }
  }

  function toggleAudio() {
    if (!audioRef.current) {
      return;
    }

    if (audioRef.current.paused) {
      void audioRef.current.play();
      setIsAudioPlaying(true);
      return;
    }

    audioRef.current.pause();
    setIsAudioPlaying(false);
  }

  return (
    <main className="min-h-screen bg-[#F5F7FB] text-[#111827]">
      <div className="flex min-h-screen flex-col">
        <header className="border-b border-slate-200 bg-white/90 px-5 py-4 backdrop-blur">
          <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="grid size-10 place-items-center rounded-lg bg-[#7C3AED] text-white shadow-sm shadow-violet-200">
                <Sparkles size={20} strokeWidth={2.4} />
              </div>
              <div>
                <p className="text-lg font-semibold leading-tight">Stillora</p>
                <p className="text-sm text-slate-500">Built by Tecno Blocks</p>
              </div>
            </div>
            <a
              className="hidden rounded-md border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 transition hover:border-[#7C3AED] hover:text-[#5B21B6] sm:inline-flex"
              href="https://tecnoblocks.com"
              rel="noreferrer"
              target="_blank"
            >
              Custom development
            </a>
          </div>
        </header>

        <div className="mx-auto grid w-full max-w-7xl flex-1 items-start gap-5 px-5 py-5 lg:grid-cols-[280px_minmax(0,1fr)_340px]">
          <aside className="space-y-4">
            <section className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
              <div className="mb-3 flex items-center gap-2">
                <ImagePlus size={18} className="text-[#7C3AED]" />
                <h1 className="text-base font-semibold">Image</h1>
              </div>

              <button
                className="flex min-h-44 w-full flex-col items-center justify-center gap-3 rounded-lg border border-dashed border-slate-300 bg-slate-50 px-4 text-center transition hover:border-[#7C3AED] hover:bg-violet-50 focus:outline-none focus:ring-2 focus:ring-[#7C3AED]"
                onClick={() => imageInputRef.current?.click()}
                onDragOver={(event) => event.preventDefault()}
                onDrop={onImageDrop}
                type="button"
              >
                <UploadCloud size={30} className="text-[#7C3AED]" />
                <span className="text-sm font-semibold">
                  {imageAsset ? "Replace image" : "Drop image or browse"}
                </span>
                <span className="text-xs text-slate-500">JPG, PNG, or WebP up to 20 MB</span>
              </button>
              <input
                ref={imageInputRef}
                accept={IMAGE_ACCEPT}
                className="sr-only"
                onChange={(event: ChangeEvent<HTMLInputElement>) =>
                  void handleImageFile(event.target.files?.[0])
                }
                type="file"
              />
              {imageError ? <p className="mt-3 text-sm text-[#DC2626]">{imageError}</p> : null}

              {imageAsset ? (
                <div className="mt-4 rounded-lg border border-slate-200 p-3">
                  <div className="flex items-start gap-3">
                    <FileImage size={18} className="mt-0.5 text-slate-500" />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-semibold">{imageAsset.file.name}</p>
                      <p className="text-xs text-slate-500">
                        {imageAsset.width} x {imageAsset.height} -{" "}
                        {formatBytes(imageAsset.file.size)} -{" "}
                        {getFileExtension(imageAsset.file.name)}
                      </p>
                      <UploadStatus state={imageUpload} />
                    </div>
                    <button
                      aria-label="Remove image"
                      className="rounded-md p-1.5 text-slate-500 transition hover:bg-red-50 hover:text-[#DC2626]"
                      onClick={removeImage}
                      type="button"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>
              ) : null}
            </section>

            <section className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
              <div className="mb-3 flex items-center gap-2">
                <FileAudio size={18} className="text-[#2563EB]" />
                <h2 className="text-base font-semibold">Audio</h2>
              </div>

              <button
                className="flex min-h-28 w-full flex-col items-center justify-center gap-2 rounded-lg border border-dashed border-slate-300 bg-slate-50 px-4 text-center transition hover:border-[#2563EB] hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-[#2563EB]"
                onClick={() => audioInputRef.current?.click()}
                onDragOver={(event) => event.preventDefault()}
                onDrop={onAudioDrop}
                type="button"
              >
                <UploadCloud size={24} className="text-[#2563EB]" />
                <span className="text-sm font-semibold">
                  {audioAsset ? "Replace audio" : "Add optional audio"}
                </span>
                <span className="text-xs text-slate-500">MP3, WAV, M4A, AAC, or OGG</span>
              </button>
              <input
                ref={audioInputRef}
                accept={AUDIO_ACCEPT}
                className="sr-only"
                onChange={(event: ChangeEvent<HTMLInputElement>) =>
                  void handleAudioFile(event.target.files?.[0])
                }
                type="file"
              />
              {audioError ? <p className="mt-3 text-sm text-[#DC2626]">{audioError}</p> : null}

              {audioAsset ? (
                <div className="mt-4 rounded-lg border border-slate-200 p-3">
                  <div className="flex items-start gap-3">
                    <button
                      aria-label={isAudioPlaying ? "Pause audio" : "Play audio"}
                      className="grid size-9 shrink-0 place-items-center rounded-md bg-blue-50 text-[#2563EB] transition hover:bg-blue-100"
                      onClick={toggleAudio}
                      type="button"
                    >
                      {isAudioPlaying ? <Pause size={16} /> : <Play size={16} />}
                    </button>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-semibold">{audioAsset.file.name}</p>
                      <p className="text-xs text-slate-500">
                        {formatBytes(audioAsset.file.size)}
                        {audioAsset.duration
                          ? ` - ${Math.round(audioAsset.duration)} sec`
                          : ""}
                      </p>
                      <UploadStatus state={audioUpload} />
                    </div>
                    <button
                      aria-label="Remove audio"
                      className="rounded-md p-1.5 text-slate-500 transition hover:bg-red-50 hover:text-[#DC2626]"
                      onClick={removeAudio}
                      type="button"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                  <audio
                    ref={audioRef}
                    onEnded={() => setIsAudioPlaying(false)}
                    src={audioAsset.url}
                  />
                </div>
              ) : null}
            </section>
          </aside>

          <section className="flex min-h-[520px] flex-col rounded-lg border border-slate-200 bg-[#E5E7EB] shadow-sm">
            <div className="flex items-center justify-between border-b border-slate-300/70 px-4 py-3">
              <div>
                <p className="text-sm font-semibold">Preview</p>
                <p className="text-xs text-slate-600">
                  {outputDimensions} - {formatDuration(duration)} - {fitMode.toUpperCase()}
                </p>
              </div>
              <div className="flex items-center gap-2 rounded-md bg-white px-2.5 py-1.5 text-xs font-medium text-slate-600">
                <Clock size={14} />
                Timeline ready
              </div>
            </div>

            <div className="grid flex-1 place-items-center overflow-hidden p-5">
              <div
                className="relative grid max-h-[min(64vh,560px)] max-w-full place-items-center overflow-hidden rounded-lg bg-slate-900 shadow-xl shadow-slate-300"
                style={{
                  aspectRatio: previewAspectRatio,
                  width: `min(100%, ${previewFrameWidth}px)`,
                }}
              >
                {imageAsset ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    alt="Uploaded composition preview"
                    className={`h-full w-full ${
                      fitMode === "fit" ? "object-contain" : "object-cover"
                    }`}
                    src={imageAsset.url}
                  />
                ) : (
                  <div className="flex max-w-xs flex-col items-center gap-3 px-6 text-center text-white">
                    <Wand2 size={34} />
                    <p className="text-lg font-semibold">Upload an image to begin</p>
                    <p className="text-sm text-slate-300">
                      The preview will match the final video frame without stretching your image.
                    </p>
                  </div>
                )}

                <div className="absolute bottom-0 left-0 right-0 bg-black/45 px-4 py-3 text-white backdrop-blur">
                  <div className="mb-2 flex items-center justify-between text-xs">
                    <span>0:00</span>
                    <span>{formatDuration(duration)}</span>
                  </div>
                  <div className="h-1.5 overflow-hidden rounded-full bg-white/30">
                    <div className="h-full w-1/3 rounded-full bg-white" />
                  </div>
                </div>
              </div>
            </div>
          </section>

          <aside className="space-y-4">
            <section className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
              <h2 className="text-base font-semibold">Output preset</h2>
              <div className="mt-3 grid gap-2">
                {OUTPUT_PRESETS.map((preset) => {
                  const isSelected = preset.id === presetId;

                  return (
                    <button
                      className={`rounded-lg border p-3 text-left transition focus:outline-none focus:ring-2 focus:ring-[#7C3AED] ${
                        isSelected
                          ? "border-[#7C3AED] bg-violet-50 text-[#5B21B6]"
                          : "border-slate-200 bg-white hover:border-slate-300"
                      }`}
                      key={preset.id}
                      onClick={() => {
                        setPresetId(preset.id);
                        setExportStatus("idle");
                        setExportProgress(0);
                        setExportResult(null);
                        setExportError("");
                      }}
                      type="button"
                    >
                      <span className="block text-sm font-semibold">{preset.name}</span>
                      <span className="mt-1 block text-xs text-slate-500">{preset.details}</span>
                    </button>
                  );
                })}
              </div>
            </section>

            <section className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
              <h2 className="text-base font-semibold">Image mode</h2>
              <div className="mt-3 grid grid-cols-2 gap-2">
                {(["fit", "fill"] as FitMode[]).map((mode) => (
                  <button
                    className={`rounded-md border px-3 py-2 text-sm font-semibold uppercase tracking-normal transition focus:outline-none focus:ring-2 focus:ring-[#7C3AED] ${
                      fitMode === mode
                        ? "border-[#7C3AED] bg-violet-50 text-[#5B21B6]"
                        : "border-slate-200 hover:border-slate-300"
                    }`}
                    key={mode}
                    onClick={() => setFitMode(mode)}
                    type="button"
                  >
                    {mode}
                  </button>
                ))}
              </div>
              <p className="mt-3 text-sm text-slate-500">
                Fit shows the full image. Fill crops edges to cover the frame.
              </p>
            </section>

            <section className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
              <h2 className="text-base font-semibold">Duration</h2>
              <div className="mt-3 grid grid-cols-2 gap-2">
                {FIXED_DURATION_SECONDS.map((option) => (
                  <button
                    className={`rounded-md border px-3 py-2 text-sm font-semibold transition focus:outline-none focus:ring-2 focus:ring-[#2563EB] ${
                      duration === option
                        ? "border-[#2563EB] bg-blue-50 text-[#2563EB]"
                        : "border-slate-200 hover:border-slate-300"
                    }`}
                    key={option}
                    onClick={() => {
                      setDuration(option);
                      setExportStatus("idle");
                      setExportProgress(0);
                      setExportResult(null);
                      setExportError("");
                    }}
                    type="button"
                  >
                    {option} seconds
                  </button>
                ))}
                {audioAsset?.duration ? (
                  <button
                    className={`col-span-2 rounded-md border px-3 py-2 text-sm font-semibold transition focus:outline-none focus:ring-2 focus:ring-[#2563EB] ${
                      duration === getAudioFitDuration(audioAsset.duration)
                        ? "border-[#2563EB] bg-blue-50 text-[#2563EB]"
                        : "border-slate-200 hover:border-slate-300"
                    }`}
                    onClick={() => {
                      setDuration(getAudioFitDuration(audioAsset.duration ?? 0));
                      setExportStatus("idle");
                      setExportProgress(0);
                      setExportResult(null);
                      setExportError("");
                    }}
                    type="button"
                  >
                    Fit audio - {formatDuration(getAudioFitDuration(audioAsset.duration))}
                  </button>
                ) : null}
              </div>
            </section>

            <section className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
              <h2 className="text-base font-semibold">Export</h2>
              <dl className="mt-3 grid gap-2 text-sm">
                <div className="flex justify-between gap-3">
                  <dt className="text-slate-500">Preset</dt>
                  <dd className="text-right font-medium">{selectedPreset.name}</dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-slate-500">Output</dt>
                  <dd className="font-medium">{outputDimensions}</dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-slate-500">Audio</dt>
                  <dd className="font-medium">{audioAsset ? "Included" : "Silent"}</dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-slate-500">Duration</dt>
                  <dd className="font-medium">{formatDuration(duration)}</dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-slate-500">Server files</dt>
                  <dd className="text-right font-medium">
                    {imageUpload.status === "saved" &&
                    (!audioAsset || audioUpload.status === "saved")
                      ? "Ready"
                      : "Pending"}
                  </dd>
                </div>
              </dl>

              {exportStatus === "ready" && exportResult ? (
                <a
                  className="mt-4 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-md bg-[#16A34A] px-3 py-2 text-center text-sm font-semibold leading-tight text-white shadow-sm shadow-emerald-200 transition hover:bg-green-700 sm:px-4"
                  download={exportResult.filename}
                  href={exportResult.downloadUrl}
                >
                  <Download size={18} className="shrink-0" />
                  <span className="min-w-0">Download final MP4</span>
                </a>
              ) : (
                <button
                  className="mt-4 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-md bg-[#7C3AED] px-3 py-2 text-center text-sm font-semibold leading-tight text-white shadow-sm shadow-violet-200 transition hover:bg-[#5B21B6] disabled:cursor-not-allowed disabled:bg-slate-300 sm:px-4"
                  disabled={
                    !imageAsset ||
                    imageUpload.status !== "saved" ||
                    (Boolean(audioAsset) && audioUpload.status !== "saved") ||
                    exportStatus === "exporting"
                  }
                  onClick={() => void startExport()}
                  type="button"
                >
                  {exportStatus === "exporting" ? (
                    <>
                      <Loader2 size={18} className="shrink-0 animate-spin" />
                      <span className="min-w-0">Exporting</span>
                    </>
                  ) : (
                    <>
                      <Sparkles size={18} className="shrink-0" />
                      <span className="min-w-0">Export MP4</span>
                    </>
                  )}
                </button>
              )}

              {exportError ? (
                <p className="mt-3 text-sm text-[#DC2626]">{exportError}</p>
              ) : null}

              {exportStatus !== "idle" ? (
                <div className="mt-4">
                  <div className="mb-2 flex justify-between text-xs font-medium text-slate-500">
                    <span>{exportStatus === "ready" ? "Ready" : "Generating"}</span>
                    <span>{exportProgress}%</span>
                  </div>
                  <div className="h-2 overflow-hidden rounded-full bg-slate-100">
                    <div
                      className="h-full rounded-full bg-[#16A34A] transition-all"
                      style={{ width: `${exportProgress}%` }}
                    />
                  </div>
                </div>
              ) : null}
            </section>
          </aside>
        </div>
      </div>
    </main>
  );
}

function UploadStatus({ state }: { state: UploadState }) {
  if (state.status === "idle") {
    return null;
  }

  if (state.status === "uploading") {
    return <p className="mt-1 text-xs text-[#D97706]">Uploading to server...</p>;
  }

  if (state.status === "failed") {
    return <p className="mt-1 text-xs text-[#DC2626]">{state.error}</p>;
  }

  return <p className="mt-1 text-xs text-[#16A34A]">Saved on server</p>;
}

async function uploadSelectedFile(
  endpoint: string,
  file: File,
  setState: (state: UploadState) => void,
) {
  setState({ status: "uploading", upload: null, error: "" });

  try {
    const formData = new FormData();
    formData.append("file", file);

    const response = await fetch(endpoint, {
      method: "POST",
      body: formData,
    });

    const payload = (await response.json()) as {
      upload?: StoredUpload;
      error?: string;
    };

    if (!response.ok || !payload.upload) {
      throw new Error(payload.error ?? "Upload failed.");
    }

    setState({ status: "saved", upload: payload.upload, error: "" });
  } catch (error) {
    setState({
      status: "failed",
      upload: null,
      error: error instanceof Error ? error.message : "Upload failed.",
    });
  }
}

function getAudioFitDuration(duration: number) {
  return Math.min(Math.max(Math.ceil(duration), 1), MAX_VIDEO_DURATION_SECONDS);
}

function formatDuration(duration: number) {
  const roundedDuration = Math.ceil(duration);
  const minutes = Math.floor(roundedDuration / 60);
  const seconds = roundedDuration % 60;

  if (minutes === 0) {
    return `${seconds}s`;
  }

  if (seconds === 0) {
    return `${minutes}m`;
  }

  return `${minutes}m ${seconds}s`;
}

function readImageDimensions(url: string) {
  return new Promise<{ width: number; height: number } | null>((resolve) => {
    const image = new Image();

    image.onload = () => resolve({ width: image.naturalWidth, height: image.naturalHeight });
    image.onerror = () => resolve(null);
    image.src = url;
  });
}

function readAudioDuration(url: string) {
  return new Promise<number | null>((resolve) => {
    const audio = document.createElement("audio");

    audio.onloadedmetadata = () =>
      resolve(Number.isFinite(audio.duration) ? audio.duration : null);
    audio.onerror = () => resolve(null);
    audio.src = url;
  });
}
