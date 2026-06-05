"use client";

import {
  Clock,
  Download,
  FileAudio,
  FileImage,
  FileVideo,
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
  MEDIA_ACCEPT,
  MAX_AUDIO_BYTES,
  MAX_IMAGE_BYTES,
  MAX_SOURCE_VIDEO_BYTES,
  MAX_VIDEO_DURATION_SECONDS,
  OUTPUT_PRESETS,
  OutputPresetId,
  SOURCE_MEDIA_MIME_TYPES,
  SourceMediaKind,
  StoredUpload,
  VIDEO_MIME_TYPES,
  formatBytes,
} from "@/lib/stillora";

type SourceAsset = {
  kind: SourceMediaKind;
  file: File;
  url: string;
  width: number;
  height: number;
  duration: number | null;
};

type ImageSlide = {
  id: string;
  file: File;
  url: string;
  width: number;
  height: number;
  duration: number;
  upload: UploadState;
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
  const [imageAsset, setImageAsset] = useState<SourceAsset | null>(null);
  const [imageSlides, setImageSlides] = useState<ImageSlide[]>([]);
  const [selectedSlideId, setSelectedSlideId] = useState("");
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
  const isImageTimeline = imageSlides.length > 1;
  const timelineDuration = imageSlides.reduce((sum, slide) => sum + slide.duration, 0);
  const selectedSlide = imageSlides.find((slide) => slide.id === selectedSlideId) ?? imageSlides[0];
  const sourceUploadReady = isImageTimeline
    ? imageSlides.every((slide) => slide.upload.status === "saved")
    : imageUpload.status === "saved";

  const selectedPreset = useMemo(
    () => OUTPUT_PRESETS.find((preset) => preset.id === presetId) ?? OUTPUT_PRESETS[0],
    [presetId],
  );

  const previewAspectRatio = getPreviewAspectRatio(
    selectedPreset,
    selectedSlide
      ? { width: selectedSlide.width, height: selectedSlide.height }
      : imageAsset
        ? { width: imageAsset.width, height: imageAsset.height }
        : null,
  );
  const previewFrameWidth = useMemo(
    () => Math.max(48, Math.min(760, Math.round(560 * previewAspectRatio))),
    [previewAspectRatio],
  );

  const outputDimensions = useMemo(() => {
    if (selectedPreset.id !== "original") {
      return `${selectedPreset.width} x ${selectedPreset.height}`;
    }

    if (!imageAsset && !selectedSlide) {
      return "Upload media";
    }

    const dimensions = selectedSlide ?? imageAsset;

    if (!dimensions) {
      return "Upload media";
    }

    const width = dimensions.width % 2 === 0 ? dimensions.width : dimensions.width + 1;
    const height = dimensions.height % 2 === 0 ? dimensions.height : dimensions.height + 1;

    return `${width} x ${height}`;
  }, [imageAsset, selectedPreset, selectedSlide]);

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

  async function handleMediaFiles(files: FileList | File[] | null | undefined) {
    const selectedFiles = Array.from(files ?? []);

    if (selectedFiles.length === 0) {
      return;
    }

    if (selectedFiles.length > 1) {
      await handleImageTimelineFiles(selectedFiles);
      return;
    }

    await handleImageFile(selectedFiles[0]);
  }

  async function handleImageTimelineFiles(files: File[]) {
    resetExportState();
    setImageError("");
    setImageUpload(emptyUploadState);

    const invalidFile = files.find((file) => !file.type.startsWith("image/"));

    if (invalidFile) {
      setImageError("Multiple-file timelines support images only. Use one video at a time.");
      return;
    }

    const slides: ImageSlide[] = [];

    for (const file of files) {
      if (!SOURCE_MEDIA_MIME_TYPES.has(file.type) || file.size > MAX_IMAGE_BYTES) {
        setImageError("Use JPG, PNG, or WebP images up to 20 MB each.");
        slides.forEach((slide) => URL.revokeObjectURL(slide.url));
        return;
      }

      const url = URL.createObjectURL(file);
      const metadata = await readImageDimensions(url);

      if (!metadata) {
        URL.revokeObjectURL(url);
        slides.forEach((slide) => URL.revokeObjectURL(slide.url));
        setImageError("One of these images could not be read. Try another file.");
        return;
      }

      slides.push({
        id: crypto.randomUUID(),
        file,
        url,
        width: metadata.width,
        height: metadata.height,
        duration: 1,
        upload: emptyUploadState,
      });
    }

    if (isImageTimeline) {
      revokeSlideUrls();
    } else {
      revokeSourceUrls();
    }
    setImageSlides(slides);
    setSelectedSlideId(slides[0]?.id ?? "");
    setImageAsset({
      kind: "image",
      file: slides[0].file,
      url: slides[0].url,
      width: slides[0].width,
      height: slides[0].height,
      duration: null,
    });
    setDuration(slides.reduce((sum, slide) => sum + slide.duration, 0));

    slides.forEach((slide) => {
      void uploadSlideImage(slide.id, slide.file);
    });
  }

  async function handleImageFile(file: File | undefined) {
    setImageError("");
    if (isImageTimeline) {
      revokeSlideUrls();
    } else {
      revokeSourceUrls();
    }
    setImageSlides([]);
    setSelectedSlideId("");
    setImageUpload(emptyUploadState);
    resetExportState();

    if (!file) {
      return;
    }

    if (!SOURCE_MEDIA_MIME_TYPES.has(file.type)) {
      setImageError("Use a JPG, PNG, WebP, MP4, MOV, M4V, or WebM file.");
      return;
    }

    const isVideo = VIDEO_MIME_TYPES.has(file.type);
    const maxBytes = isVideo ? MAX_SOURCE_VIDEO_BYTES : MAX_IMAGE_BYTES;

    if (file.size > maxBytes) {
      setImageError(isVideo ? "Video must be 200 MB or smaller." : "Image must be 20 MB or smaller.");
      return;
    }

    const url = URL.createObjectURL(file);
    const metadata = isVideo
      ? await readVideoMetadata(url)
      : await readImageDimensions(url);

    if (!metadata) {
      URL.revokeObjectURL(url);
      setImageError("This media file could not be read. Try another file.");
      return;
    }

    setImageAsset({
      kind: isVideo ? "video" : "image",
      file,
      url,
      ...metadata,
    });
    if (isVideo && metadata.duration) {
      setDuration(getAudioFitDuration(metadata.duration));
    }
    void uploadSelectedFile(
      isVideo ? "/api/uploads/video" : "/api/uploads/image",
      file,
      setImageUpload,
    );
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
      if (isImageTimeline) {
        fitTimelineToDuration(getAudioFitDuration(audioDuration));
      } else {
        setDuration(getAudioFitDuration(audioDuration));
      }
      setExportStatus("idle");
      setExportProgress(0);
      setExportResult(null);
      setExportError("");
    }
    void uploadSelectedFile("/api/uploads/audio", file, setAudioUpload);
  }

  function removeImage() {
    if (isImageTimeline) {
      revokeSlideUrls();
    } else {
      revokeSourceUrls();
    }
    setImageAsset(null);
    setImageSlides([]);
    setSelectedSlideId("");
    setImageUpload(emptyUploadState);
    resetExportState();
  }

  function removeAudio() {
    if (audioAsset) {
      URL.revokeObjectURL(audioAsset.url);
    }

    setAudioAsset(null);
    setAudioUpload(emptyUploadState);
    setIsAudioPlaying(false);
    if (!FIXED_DURATION_SECONDS.includes(duration as 10 | 30)) {
      setDuration(
        imageAsset?.kind === "video" && imageAsset.duration
          ? getAudioFitDuration(imageAsset.duration)
          : DEFAULT_DURATION_SECONDS,
      );
    }
    setExportStatus("idle");
    setExportProgress(0);
    setExportResult(null);
    setExportError("");
  }

  function onImageDrop(event: DragEvent<HTMLButtonElement>) {
    event.preventDefault();
    void handleMediaFiles(event.dataTransfer.files);
  }

  function onAudioDrop(event: DragEvent<HTMLButtonElement>) {
    event.preventDefault();
    void handleAudioFile(event.dataTransfer.files[0]);
  }

  async function startExport() {
    if (
      (!imageAsset && !isImageTimeline) ||
      !sourceUploadReady ||
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
          sourcePath: imageUpload.upload?.relativePath,
          sourceKind: imageAsset?.kind ?? "image",
          slides: isImageTimeline
            ? imageSlides.map((slide) => ({
                path: slide.upload.upload?.relativePath,
                duration: slide.duration,
                width: slide.width,
                height: slide.height,
              }))
            : undefined,
          transition: isImageTimeline ? "fade" : undefined,
          audioPath: audioUpload.upload?.relativePath ?? null,
          presetId,
          fitMode,
          duration,
          imageWidth: imageAsset?.width ?? selectedSlide?.width ?? 1080,
          imageHeight: imageAsset?.height ?? selectedSlide?.height ?? 1920,
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

  function resetExportState() {
    setExportStatus("idle");
    setExportProgress(0);
    setExportResult(null);
    setExportError("");
  }

  function revokeSourceUrls() {
    if (imageAsset) {
      URL.revokeObjectURL(imageAsset.url);
    }
  }

  function revokeSlideUrls() {
    imageSlides.forEach((slide) => URL.revokeObjectURL(slide.url));
  }

  function updateSlideDuration(slideId: string, nextDuration: number) {
    const normalizedDuration = Math.min(Math.max(nextDuration || 0.25, 0.25), 60);

    setImageSlides((slides) => {
      const nextSlides = slides.map((slide) =>
        slide.id === slideId ? { ...slide, duration: normalizedDuration } : slide,
      );
      setDuration(nextSlides.reduce((sum, slide) => sum + slide.duration, 0));
      return nextSlides;
    });
    resetExportState();
  }

  function fitTimelineToDuration(targetDuration: number) {
    setImageSlides((slides) => {
      if (slides.length === 0) {
        return slides;
      }

      const currentDuration = slides.reduce((sum, slide) => sum + slide.duration, 0);
      const nextSlides = slides.map((slide) => ({
        ...slide,
        duration:
          currentDuration > 0
            ? Math.max(0.25, Number(((slide.duration / currentDuration) * targetDuration).toFixed(2)))
            : Number((targetDuration / slides.length).toFixed(2)),
      }));
      setDuration(nextSlides.reduce((sum, slide) => sum + slide.duration, 0));
      return nextSlides;
    });
    resetExportState();
  }

  function removeSlide(slideId: string) {
    setImageSlides((slides) => {
      const removedSlide = slides.find((slide) => slide.id === slideId);
      const nextSlides = slides.filter((slide) => slide.id !== slideId);

      if (removedSlide) {
        URL.revokeObjectURL(removedSlide.url);
      }

      if (nextSlides.length === 0) {
        setImageAsset(null);
        setSelectedSlideId("");
        setImageUpload(emptyUploadState);
        setDuration(DEFAULT_DURATION_SECONDS);
      } else {
        const nextSelected =
          nextSlides.find((slide) => slide.id === selectedSlideId) ?? nextSlides[0];
        setSelectedSlideId(nextSelected.id);
        setImageAsset({
          kind: "image",
          file: nextSelected.file,
          url: nextSelected.url,
          width: nextSelected.width,
          height: nextSelected.height,
          duration: null,
        });
        setDuration(nextSlides.reduce((sum, slide) => sum + slide.duration, 0));
      }

      return nextSlides;
    });
    resetExportState();
  }

  async function uploadSlideImage(slideId: string, file: File) {
    setImageSlides((slides) =>
      slides.map((slide) =>
        slide.id === slideId
          ? { ...slide, upload: { status: "uploading", upload: null, error: "" } }
          : slide,
      ),
    );

    try {
      const upload = await uploadFile("/api/uploads/image", file);
      setImageSlides((slides) =>
        slides.map((slide) =>
          slide.id === slideId
            ? { ...slide, upload: { status: "saved", upload, error: "" } }
            : slide,
        ),
      );
    } catch (error) {
      setImageSlides((slides) =>
        slides.map((slide) =>
          slide.id === slideId
            ? {
                ...slide,
                upload: {
                  status: "failed",
                  upload: null,
                  error: error instanceof Error ? error.message : "Upload failed.",
                },
              }
            : slide,
        ),
      );
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
    <main className="min-h-screen bg-[var(--color-background)] text-[var(--color-foreground)]">
      <div className="flex min-h-screen flex-col">
        <header className="border-b border-[var(--color-border)] bg-[var(--color-header)] px-5 py-4 backdrop-blur">
          <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="grid size-10 place-items-center rounded-lg bg-[var(--color-primary)] text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)]">
                <Sparkles size={20} strokeWidth={2.4} />
              </div>
              <div>
                <p className="text-lg font-semibold leading-tight">Stillora</p>
                <p className="text-sm text-[var(--color-muted-strong)]">Built by Tecno Blocks</p>
              </div>
            </div>
            <a
              className="hidden rounded-md border border-[var(--color-border)] px-3 py-2 text-sm font-medium text-[var(--color-muted)] transition hover:border-[var(--color-primary)] hover:text-[var(--color-primary-text)] sm:inline-flex"
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
            <section className="rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-4 shadow-sm">
              <div className="mb-3 flex items-center gap-2">
                <ImagePlus size={18} className="text-[var(--color-primary)]" />
                <h1 className="text-base font-semibold">Source media</h1>
              </div>

              <button
                className="flex min-h-44 w-full flex-col items-center justify-center gap-3 rounded-lg border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface)] px-4 text-center transition hover:border-[var(--color-primary)] hover:bg-[var(--color-primary-soft)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]"
                onClick={() => imageInputRef.current?.click()}
                onDragOver={(event) => event.preventDefault()}
                onDrop={onImageDrop}
                type="button"
              >
                <UploadCloud size={30} className="text-[var(--color-primary)]" />
                <span className="text-sm font-semibold">
                  {imageAsset ? "Replace media" : "Drop image or video"}
                </span>
                <span className="text-xs text-[var(--color-muted-strong)]">
                  JPG, PNG, WebP, MP4, MOV, M4V, or WebM
                </span>
              </button>
              <input
                ref={imageInputRef}
                accept={MEDIA_ACCEPT}
                className="sr-only"
                multiple
                onChange={(event: ChangeEvent<HTMLInputElement>) =>
                  void handleMediaFiles(event.target.files)
                }
                type="file"
              />
              {imageError ? <p className="mt-3 text-sm text-[var(--color-danger)]">{imageError}</p> : null}

              {imageAsset ? (
                <div className="mt-4 rounded-lg border border-[var(--color-border)] p-3">
                  <div className="flex items-start gap-3">
                    {imageAsset.kind === "video" ? (
                      <FileVideo size={18} className="mt-0.5 text-[var(--color-muted-strong)]" />
                    ) : (
                      <FileImage size={18} className="mt-0.5 text-[var(--color-muted-strong)]" />
                    )}
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-semibold">{imageAsset.file.name}</p>
                      <p className="text-xs text-[var(--color-muted-strong)]">
                        {imageAsset.width} x {imageAsset.height} -{" "}
                        {formatBytes(imageAsset.file.size)} -{" "}
                        {getFileExtension(imageAsset.file.name)}
                        {imageAsset.duration
                          ? ` - ${formatDuration(imageAsset.duration)}`
                          : ""}
                      </p>
                      <UploadStatus state={imageUpload} />
                    </div>
                    <button
                      aria-label="Remove media"
                      className="rounded-md p-1.5 text-[var(--color-muted-strong)] transition hover:bg-[var(--color-danger-soft)] hover:text-[var(--color-danger)]"
                      onClick={removeImage}
                      type="button"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>
              ) : null}

              {isImageTimeline ? (
                <div className="mt-4 space-y-2">
                  <div className="flex items-center justify-between gap-3">
                    <p className="text-sm font-semibold">Image order</p>
                    <p className="text-xs text-[var(--color-muted-strong)]">{formatDuration(timelineDuration)}</p>
                  </div>
                  {imageSlides.map((slide, index) => (
                    <div
                      className={`rounded-lg border p-2 transition ${
                        selectedSlideId === slide.id
                          ? "border-[var(--color-primary)] bg-[var(--color-primary-soft)]"
                          : "border-[var(--color-border)] bg-[var(--color-card)]"
                      }`}
                      key={slide.id}
                    >
                      <button
                        className="flex w-full items-center gap-2 text-left"
                        onClick={() => setSelectedSlideId(slide.id)}
                        type="button"
                      >
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          alt={`Slide ${index + 1}`}
                          className="size-10 rounded-md object-cover"
                          src={slide.url}
                        />
                        <div className="min-w-0 flex-1">
                          <p className="truncate text-xs font-semibold">
                            {index + 1}. {slide.file.name}
                          </p>
                          <UploadStatus state={slide.upload} />
                        </div>
                      </button>
                      <div className="mt-2 grid grid-cols-[1fr_auto] items-center gap-2">
                        <label className="text-xs font-medium text-[var(--color-muted-strong)]">
                          Seconds on screen
                          <input
                            className="mt-1 h-9 w-full rounded-md border border-[var(--color-border)] px-2 text-sm text-[var(--color-foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]"
                            min="0.25"
                            onChange={(event) =>
                              updateSlideDuration(slide.id, Number(event.target.value))
                            }
                            step="0.25"
                            type="number"
                            value={slide.duration}
                          />
                        </label>
                        <button
                          aria-label="Remove slide"
                          className="mt-5 rounded-md p-2 text-[var(--color-muted-strong)] transition hover:bg-[var(--color-danger-soft)] hover:text-[var(--color-danger)]"
                          onClick={() => removeSlide(slide.id)}
                          type="button"
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </div>
                  ))}
                  <p className="text-xs text-[var(--color-muted-strong)]">
                    Smooth fade transitions are added between images during export.
                  </p>
                </div>
              ) : null}
            </section>

            <section className="rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-4 shadow-sm">
              <div className="mb-3 flex items-center gap-2">
                <FileAudio size={18} className="text-[var(--color-secondary-text)]" />
                <h2 className="text-base font-semibold">Audio</h2>
              </div>

              <button
                className="flex min-h-28 w-full flex-col items-center justify-center gap-2 rounded-lg border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface)] px-4 text-center transition hover:border-[var(--color-secondary)] hover:bg-[var(--color-secondary-soft)] focus:outline-none focus:ring-2 focus:ring-[var(--color-secondary)]"
                onClick={() => audioInputRef.current?.click()}
                onDragOver={(event) => event.preventDefault()}
                onDrop={onAudioDrop}
                type="button"
              >
                <UploadCloud size={24} className="text-[var(--color-secondary-text)]" />
                <span className="text-sm font-semibold">
                  {audioAsset ? "Replace audio" : "Add optional audio"}
                </span>
                <span className="text-xs text-[var(--color-muted-strong)]">MP3, WAV, M4A, AAC, or OGG</span>
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
              {audioError ? <p className="mt-3 text-sm text-[var(--color-danger)]">{audioError}</p> : null}

              {audioAsset ? (
                <div className="mt-4 rounded-lg border border-[var(--color-border)] p-3">
                  <div className="flex items-start gap-3">
                    <button
                      aria-label={isAudioPlaying ? "Pause audio" : "Play audio"}
                      className="grid size-9 shrink-0 place-items-center rounded-md bg-[var(--color-secondary-soft)] text-[var(--color-secondary-text)] transition hover:bg-[var(--color-secondary)]"
                      onClick={toggleAudio}
                      type="button"
                    >
                      {isAudioPlaying ? <Pause size={16} /> : <Play size={16} />}
                    </button>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-semibold">{audioAsset.file.name}</p>
                      <p className="text-xs text-[var(--color-muted-strong)]">
                        {formatBytes(audioAsset.file.size)}
                        {audioAsset.duration
                          ? ` - ${Math.round(audioAsset.duration)} sec`
                          : ""}
                      </p>
                      <UploadStatus state={audioUpload} />
                    </div>
                    <button
                      aria-label="Remove audio"
                      className="rounded-md p-1.5 text-[var(--color-muted-strong)] transition hover:bg-[var(--color-danger-soft)] hover:text-[var(--color-danger)]"
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

          <section className="flex min-h-[520px] flex-col rounded-lg border border-[var(--color-border)] bg-[var(--color-preview)] shadow-sm">
            <div className="flex items-center justify-between border-b border-[var(--color-border-subtle)] px-4 py-3">
              <div>
                <p className="text-sm font-semibold">Preview</p>
                <p className="text-xs text-[var(--color-muted)]">
                  {outputDimensions} - {formatDuration(duration)} - {fitMode.toUpperCase()}
                </p>
              </div>
              <div className="flex items-center gap-2 rounded-md bg-[var(--color-card)] px-2.5 py-1.5 text-xs font-medium text-[var(--color-muted)]">
                <Clock size={14} />
                Timeline ready
              </div>
            </div>

            <div className="grid flex-1 place-items-center overflow-hidden p-5">
              <div
                className="relative grid max-h-[min(64vh,560px)] max-w-full place-items-center overflow-hidden rounded-lg bg-[var(--color-preview-panel)] shadow-xl shadow-[var(--shadow-card)]"
                style={{
                  aspectRatio: previewAspectRatio,
                  width: `min(100%, ${previewFrameWidth}px)`,
                }}
              >
                {selectedSlide ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    alt="Selected timeline slide preview"
                    className={`h-full w-full ${
                      fitMode === "fit" ? "object-contain" : "object-cover"
                    }`}
                    src={selectedSlide.url}
                  />
                ) : imageAsset?.kind === "image" ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    alt="Uploaded composition preview"
                    className={`h-full w-full ${
                      fitMode === "fit" ? "object-contain" : "object-cover"
                    }`}
                    src={imageAsset.url}
                  />
                ) : imageAsset?.kind === "video" ? (
                  <video
                    className={`h-full w-full ${
                      fitMode === "fit" ? "object-contain" : "object-cover"
                    }`}
                    controls
                    muted
                    playsInline
                    src={imageAsset.url}
                  />
                ) : (
                  <div className="flex max-w-xs flex-col items-center gap-3 px-6 text-center text-[var(--color-primary-text)]">
                    <Wand2 size={34} />
                    <p className="text-lg font-semibold">Upload media to begin</p>
                    <p className="text-sm text-[var(--color-muted)]">
                      The preview will match the final video frame without stretching your media.
                    </p>
                  </div>
                )}

                <div className="absolute bottom-0 left-0 right-0 bg-[var(--color-overlay)] px-4 py-3 text-[var(--color-primary-text)] backdrop-blur">
                  <div className="mb-2 flex items-center justify-between text-xs">
                    <span>0:00</span>
                    <span>{formatDuration(duration)}</span>
                  </div>
                  <div className="h-1.5 overflow-hidden rounded-full bg-[var(--color-overlay-track)]">
                    <div className="h-full w-1/3 rounded-full bg-[var(--color-overlay-fill)]" />
                  </div>
                </div>
              </div>
            </div>
          </section>

          <aside className="space-y-4">
            <section className="rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-4 shadow-sm">
              <h2 className="text-base font-semibold">Output preset</h2>
              <div className="mt-3 grid gap-2">
                {OUTPUT_PRESETS.map((preset) => {
                  const isSelected = preset.id === presetId;

                  return (
                    <button
                      className={`rounded-lg border p-3 text-left transition focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)] ${
                        isSelected
                          ? "border-[var(--color-primary)] bg-[var(--color-primary-soft)] text-[var(--color-primary-text)]"
                          : "border-[var(--color-border)] bg-[var(--color-card)] hover:border-[var(--color-border-strong)]"
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
                      <span className="mt-1 block text-xs text-[var(--color-muted-strong)]">{preset.details}</span>
                    </button>
                  );
                })}
              </div>
            </section>

            <section className="rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-4 shadow-sm">
              <h2 className="text-base font-semibold">Image mode</h2>
              <div className="mt-3 grid grid-cols-2 gap-2">
                {(["fit", "fill"] as FitMode[]).map((mode) => (
                  <button
                    className={`rounded-md border px-3 py-2 text-sm font-semibold uppercase tracking-normal transition focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)] ${
                      fitMode === mode
                        ? "border-[var(--color-primary)] bg-[var(--color-primary-soft)] text-[var(--color-primary-text)]"
                        : "border-[var(--color-border)] hover:border-[var(--color-border-strong)]"
                    }`}
                    key={mode}
                    onClick={() => setFitMode(mode)}
                    type="button"
                  >
                    {mode}
                  </button>
                ))}
              </div>
              <p className="mt-3 text-sm text-[var(--color-muted-strong)]">
                Fit shows the full image. Fill crops edges to cover the frame.
              </p>
            </section>

            <section className="rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-4 shadow-sm">
              <h2 className="text-base font-semibold">Duration</h2>
              {isImageTimeline ? (
                <div className="mt-3 space-y-2">
                  <div className="rounded-lg border border-[var(--color-secondary)] bg-[var(--color-secondary-soft)] p-3 text-sm text-[var(--color-secondary-text)]">
                    Timeline duration is controlled by each image row:{" "}
                    <span className="font-semibold">{formatDuration(timelineDuration)}</span>
                  </div>
                  {audioAsset?.duration ? (
                    <button
                      className="w-full rounded-md border border-[var(--color-secondary)] bg-[var(--color-card)] px-3 py-2 text-sm font-semibold text-[var(--color-secondary-text)] transition hover:bg-[var(--color-secondary-soft)]"
                      onClick={() => fitTimelineToDuration(getAudioFitDuration(audioAsset.duration ?? 0))}
                      type="button"
                    >
                      Fit image timings to audio -{" "}
                      {formatDuration(getAudioFitDuration(audioAsset.duration))}
                    </button>
                  ) : null}
                </div>
              ) : (
                <div className="mt-3 grid grid-cols-2 gap-2">
                  {FIXED_DURATION_SECONDS.map((option) => (
                    <button
                      className={`rounded-md border px-3 py-2 text-sm font-semibold transition focus:outline-none focus:ring-2 focus:ring-[var(--color-secondary)] ${
                        duration === option
                          ? "border-[var(--color-secondary)] bg-[var(--color-secondary-soft)] text-[var(--color-secondary-text)]"
                          : "border-[var(--color-border)] hover:border-[var(--color-border-strong)]"
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
                      className={`col-span-2 rounded-md border px-3 py-2 text-sm font-semibold transition focus:outline-none focus:ring-2 focus:ring-[var(--color-secondary)] ${
                        duration === getAudioFitDuration(audioAsset.duration)
                          ? "border-[var(--color-secondary)] bg-[var(--color-secondary-soft)] text-[var(--color-secondary-text)]"
                          : "border-[var(--color-border)] hover:border-[var(--color-border-strong)]"
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
                  {imageAsset?.kind === "video" && imageAsset.duration ? (
                    <button
                      className={`col-span-2 rounded-md border px-3 py-2 text-sm font-semibold transition focus:outline-none focus:ring-2 focus:ring-[var(--color-secondary)] ${
                        duration === getAudioFitDuration(imageAsset.duration)
                          ? "border-[var(--color-secondary)] bg-[var(--color-secondary-soft)] text-[var(--color-secondary-text)]"
                          : "border-[var(--color-border)] hover:border-[var(--color-border-strong)]"
                      }`}
                      onClick={() => {
                        setDuration(getAudioFitDuration(imageAsset.duration ?? 0));
                        setExportStatus("idle");
                        setExportProgress(0);
                        setExportResult(null);
                        setExportError("");
                      }}
                      type="button"
                    >
                      Fit video - {formatDuration(getAudioFitDuration(imageAsset.duration))}
                    </button>
                  ) : null}
                </div>
              )}
            </section>

            <section className="rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-4 shadow-sm">
              <h2 className="text-base font-semibold">Export</h2>
              <dl className="mt-3 grid gap-2 text-sm">
                <div className="flex justify-between gap-3">
                  <dt className="text-[var(--color-muted-strong)]">Preset</dt>
                  <dd className="text-right font-medium">{selectedPreset.name}</dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-[var(--color-muted-strong)]">Output</dt>
                  <dd className="font-medium">{outputDimensions}</dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-[var(--color-muted-strong)]">Audio</dt>
                  <dd className="font-medium">
                    {audioAsset
                      ? "Added audio"
                      : imageAsset?.kind === "video"
                        ? "Source audio"
                        : "Silent"}
                  </dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-[var(--color-muted-strong)]">Duration</dt>
                  <dd className="font-medium">{formatDuration(duration)}</dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-[var(--color-muted-strong)]">Server files</dt>
                  <dd className="text-right font-medium">
                    {sourceUploadReady && (!audioAsset || audioUpload.status === "saved")
                      ? "Ready"
                      : "Pending"}
                  </dd>
                </div>
              </dl>

              {exportStatus === "ready" && exportResult ? (
                <a
                  className="mt-4 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-md bg-[var(--color-success)] px-3 py-2 text-center text-sm font-semibold leading-tight text-[var(--color-success-text)] shadow-sm shadow-[var(--shadow-success)] transition hover:bg-[var(--color-secondary-hover)] sm:px-4"
                  download={exportResult.filename}
                  href={exportResult.downloadUrl}
                >
                  <Download size={18} className="shrink-0" />
                  <span className="min-w-0">Download final MP4</span>
                </a>
              ) : (
                <button
                  className="mt-4 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-md bg-[var(--color-primary)] px-3 py-2 text-center text-sm font-semibold leading-tight text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)] disabled:cursor-not-allowed disabled:bg-[var(--color-disabled)] sm:px-4"
                  disabled={
                    !imageAsset ||
                    !sourceUploadReady ||
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
                <p className="mt-3 text-sm text-[var(--color-danger)]">{exportError}</p>
              ) : null}

              {exportStatus !== "idle" ? (
                <div className="mt-4">
                  <div className="mb-2 flex justify-between text-xs font-medium text-[var(--color-muted-strong)]">
                    <span>{exportStatus === "ready" ? "Ready" : "Generating"}</span>
                    <span>{exportProgress}%</span>
                  </div>
                  <div className="h-2 overflow-hidden rounded-full bg-[var(--color-surface-dim)]">
                    <div
                      className="h-full rounded-full bg-[var(--color-success)] transition-all"
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
    return <p className="mt-1 text-xs text-[var(--color-warning)]">Uploading to server...</p>;
  }

  if (state.status === "failed") {
    return <p className="mt-1 text-xs text-[var(--color-danger)]">{state.error}</p>;
  }

  return <p className="mt-1 text-xs text-[var(--color-success)]">Saved on server</p>;
}

async function uploadSelectedFile(
  endpoint: string,
  file: File,
  setState: (state: UploadState) => void,
) {
  setState({ status: "uploading", upload: null, error: "" });

  try {
    const upload = await uploadFile(endpoint, file);

    setState({ status: "saved", upload, error: "" });
  } catch (error) {
    setState({
      status: "failed",
      upload: null,
      error: error instanceof Error ? error.message : "Upload failed.",
    });
  }
}

async function uploadFile(endpoint: string, file: File) {
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

  return payload.upload;
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
  return new Promise<{ width: number; height: number; duration: null } | null>((resolve) => {
    const image = new Image();

    image.onload = () =>
      resolve({
        width: image.naturalWidth,
        height: image.naturalHeight,
        duration: null,
      });
    image.onerror = () => resolve(null);
    image.src = url;
  });
}

function readVideoMetadata(url: string) {
  return new Promise<{ width: number; height: number; duration: number | null } | null>(
    (resolve) => {
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
    },
  );
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
