"use client";

import { DragEvent, useEffect, useMemo, useRef, useState } from "react";
import { startGoogleSignIn, useSession } from "@/app/components/use-session";
import {
  AUDIO_MIME_TYPES,
  DEFAULT_DURATION_SECONDS,
  FIXED_DURATION_SECONDS,
  FitMode,
  getPreviewAspectRatio,
  IMAGE_MIME_TYPES,
  MAX_AUDIO_BYTES,
  MAX_IMAGE_BYTES,
  MAX_SOURCE_VIDEO_BYTES,
  MAX_UPLOAD_BYTES,
  OUTPUT_PRESETS,
  OutputPresetId,
  SOURCE_MEDIA_MIME_TYPES,
  VIDEO_MIME_TYPES,
} from "@/lib/stillora";
import {
  getAudioFitDuration,
  readAudioDuration,
  readImageDimensions,
  readVideoMetadata,
  uploadFile,
} from "./editor-utils";
import type { EditorModel, ExportResult, ImageSlide, SourceAsset, UploadState } from "./types";

const emptyUploadState: UploadState = { status: "idle", upload: null, error: "" };
const EXPORT_RESULT_TTL_MS = 20 * 60 * 1000;

export function useEditorModel(): EditorModel {
  const { user } = useSession();
  const imageInputRef = useRef<HTMLInputElement>(null);
  const addImagesInputRef = useRef<HTMLInputElement>(null);
  const audioInputRef = useRef<HTMLInputElement>(null);
  const audioRef = useRef<HTMLAudioElement>(null);
  const [imageAsset, setImageAsset] = useState<SourceAsset | null>(null);
  const [imageSlides, setImageSlides] = useState<ImageSlide[]>([]);
  const [selectedSlideId, setSelectedSlideId] = useState("");
  const [audioAsset, setAudioAsset] = useState<EditorModel["state"]["audioAsset"]>(null);
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
    selectedSlide ? selectedSlide : imageAsset,
  );
  const previewFrameWidth = useMemo(
    () => Math.max(48, Math.min(760, Math.round(560 * previewAspectRatio))),
    [previewAspectRatio],
  );
  const outputDimensions = useMemo(() => {
    if (selectedPreset.id !== "original") {
      return `${selectedPreset.width} x ${selectedPreset.height}`;
    }

    const dimensions = selectedSlide ?? imageAsset;
    if (!dimensions) return "Upload media";
    const width = dimensions.width % 2 === 0 ? dimensions.width : dimensions.width + 1;
    const height = dimensions.height % 2 === 0 ? dimensions.height : dimensions.height + 1;
    return `${width} x ${height}`;
  }, [imageAsset, selectedPreset, selectedSlide]);

  useEffect(() => {
    return () => {
      if (imageAsset) URL.revokeObjectURL(imageAsset.url);
    };
  }, [imageAsset]);
  useEffect(() => {
    return () => {
      if (audioAsset) URL.revokeObjectURL(audioAsset.url);
    };
  }, [audioAsset]);
  useEffect(() => {
    if (!exportResult) return;
    const timeout = window.setTimeout(() => {
      setExportResult((current) => (current?.id === exportResult.id ? null : current));
      setExportStatus((current) => (current === "ready" ? "idle" : current));
    }, EXPORT_RESULT_TTL_MS);
    return () => {
      window.clearTimeout(timeout);
      URL.revokeObjectURL(exportResult.downloadUrl);
    };
  }, [exportResult]);

  function resetExportState() {
    setExportStatus("idle");
    setExportProgress(0);
    setExportResult(null);
    setExportError("");
  }

  async function handleMediaFiles(files: FileList | File[] | null | undefined) {
    const selectedFiles = Array.from(files ?? []);
    if (selectedFiles.length === 0) return;
    if (selectedFiles.length > 1) return handleImageTimelineFiles(selectedFiles);
    return handleImageFile(selectedFiles[0]);
  }

  async function handleAdditionalImageFiles(files: FileList | File[] | null | undefined) {
    const selectedFiles = Array.from(files ?? []);
    if (selectedFiles.length === 0) return;
    const nextFiles = [
      ...(isImageTimeline ? imageSlides.map((slide) => slide.file) : imageAsset?.kind === "image" ? [imageAsset.file] : []),
      ...selectedFiles,
    ];
    return nextFiles.length === selectedFiles.length && selectedFiles.length === 1
      ? handleImageFile(selectedFiles[0])
      : handleImageTimelineFiles(nextFiles);
  }

  async function handleImageTimelineFiles(files: File[]) {
    resetExportState();
    setImageError("");
    setImageUpload(emptyUploadState);
    if (files.some((file) => !file.type.startsWith("image/"))) {
      setImageError("Multiple-file timelines support images only. Use one video at a time.");
      return;
    }
    if (files.reduce((sum, file) => sum + file.size, 0) > MAX_UPLOAD_BYTES) {
      setImageError("Total image timeline media must be 200 MB or smaller.");
      return;
    }
    const slides: ImageSlide[] = [];
    for (const file of files) {
      if (!IMAGE_MIME_TYPES.has(file.type) || file.size > MAX_IMAGE_BYTES) {
        setImageError("Use JPG, PNG, or WebP images up to 200 MB each.");
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
      slides.push({ id: crypto.randomUUID(), file, url, ...metadata, duration: 1, upload: emptyUploadState });
    }
    if (isImageTimeline) revokeSlideUrls();
    else revokeSourceUrls();
    setImageSlides(slides);
    setSelectedSlideId(slides[0]?.id ?? "");
    setImageAsset({ kind: "image", file: slides[0].file, url: slides[0].url, width: slides[0].width, height: slides[0].height, duration: null });
    setDuration(slides.reduce((sum, slide) => sum + slide.duration, 0));
    slides.forEach((slide) => void uploadSlideImage(slide.id, slide.file));
  }

  async function handleImageFile(file: File | undefined) {
    setImageError("");
    if (isImageTimeline) revokeSlideUrls();
    else revokeSourceUrls();
    setImageSlides([]);
    setSelectedSlideId("");
    setImageUpload(emptyUploadState);
    resetExportState();
    if (!file) return;
    if (!SOURCE_MEDIA_MIME_TYPES.has(file.type)) {
      setImageError("Use a JPG, PNG, WebP, MP4, MOV, M4V, or WebM file.");
      return;
    }
    const isVideo = VIDEO_MIME_TYPES.has(file.type);
    if (file.size > (isVideo ? MAX_SOURCE_VIDEO_BYTES : MAX_IMAGE_BYTES)) {
      setImageError(isVideo ? "Video must be 200 MB or smaller." : "Image must be 200 MB or smaller.");
      return;
    }
    const url = URL.createObjectURL(file);
    const metadata = isVideo ? await readVideoMetadata(url) : await readImageDimensions(url);
    if (!metadata) {
      URL.revokeObjectURL(url);
      setImageError("This media file could not be read. Try another file.");
      return;
    }
    const assetDuration =
      isVideo && "duration" in metadata && typeof metadata.duration === "number"
        ? metadata.duration
        : null;

    setImageAsset({
      kind: isVideo ? "video" : "image",
      file,
      url,
      ...metadata,
      duration: assetDuration,
    });
    if (assetDuration) setDuration(getAudioFitDuration(assetDuration));
    void uploadSelectedFile(isVideo ? "/api/uploads/video" : "/api/uploads/image", file, setImageUpload);
  }

  async function handleAudioFile(file: File | undefined) {
    setAudioError("");
    setAudioUpload(emptyUploadState);
    setIsAudioPlaying(false);
    if (!file) return;
    if (!AUDIO_MIME_TYPES.has(file.type)) return setAudioError("Use an MP3, WAV, M4A, AAC, or OGG audio file.");
    if (file.size > MAX_AUDIO_BYTES) return setAudioError("Audio must be 200 MB or smaller.");
    const url = URL.createObjectURL(file);
    const audioDuration = await readAudioDuration(url);
    if (audioAsset) URL.revokeObjectURL(audioAsset.url);
    setAudioAsset({ file, url, duration: audioDuration });
    if (audioDuration) {
      if (isImageTimeline) fitTimelineToDuration(getAudioFitDuration(audioDuration));
      else setDuration(getAudioFitDuration(audioDuration));
      resetExportState();
    }
    void uploadSelectedFile("/api/uploads/audio", file, setAudioUpload);
  }

  function removeImage() {
    if (isImageTimeline) revokeSlideUrls();
    else revokeSourceUrls();
    setImageAsset(null);
    setImageSlides([]);
    setSelectedSlideId("");
    setImageUpload(emptyUploadState);
    resetExportState();
  }

  function removeAudio() {
    if (audioAsset) URL.revokeObjectURL(audioAsset.url);
    setAudioAsset(null);
    setAudioUpload(emptyUploadState);
    setIsAudioPlaying(false);
    if (!FIXED_DURATION_SECONDS.includes(duration as 10 | 30)) {
      setDuration(imageAsset?.kind === "video" && imageAsset.duration ? getAudioFitDuration(imageAsset.duration) : DEFAULT_DURATION_SECONDS);
    }
    resetExportState();
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
    if ((!imageAsset && !isImageTimeline) || !sourceUploadReady || (audioAsset && audioUpload.status !== "saved") || exportStatus === "exporting") return;
    setExportProgress(20);
    setExportStatus("exporting");
    setExportResult(null);
    setExportError("");
    try {
      const formData = new FormData();
      formData.append("metadata", JSON.stringify({ sourceKind: imageAsset?.kind ?? "image", slides: isImageTimeline ? imageSlides.map(({ duration, width, height }) => ({ duration, width, height })) : undefined, transition: isImageTimeline ? "fade" : undefined, presetId, fitMode, duration, imageWidth: imageAsset?.width ?? selectedSlide?.width ?? 1080, imageHeight: imageAsset?.height ?? selectedSlide?.height ?? 1920 }));
      if (isImageTimeline) imageSlides.forEach((slide, index) => formData.append(`slide-${index}`, slide.file));
      else if (imageAsset) formData.append("source", imageAsset.file);
      if (audioAsset) formData.append("audio", audioAsset.file);
      const response = await fetch("/api/exports", { method: "POST", body: formData });
      if (response.status === 401) return startGoogleSignIn("/editor");
      if (!response.ok) {
        const payload = (await response.json().catch(() => null)) as { error?: string } | null;
        throw new Error(payload?.error ?? "Export failed.");
      }
      const video = await response.blob();
      const downloadUrl = URL.createObjectURL(video);
      const filename = response.headers.get("X-Export-Filename") ?? `stillora-${crypto.randomUUID()}.mp4`;
      setExportProgress(100);
      setExportResult({ id: crypto.randomUUID(), filename, downloadUrl });
      setExportStatus("ready");
    } catch (error) {
      setExportStatus("idle");
      setExportProgress(0);
      setExportError(error instanceof Error ? error.message : "Export failed.");
    }
  }

  function handleExportDownload() {
    const downloadedExportId = exportResult?.id;
    window.setTimeout(() => {
      setExportResult((current) => (current?.id === downloadedExportId ? null : current));
      setExportStatus((current) => (current === "ready" ? "idle" : current));
    }, 1000);
  }

  function revokeSourceUrls() {
    if (imageAsset) URL.revokeObjectURL(imageAsset.url);
  }

  function revokeSlideUrls() {
    imageSlides.forEach((slide) => URL.revokeObjectURL(slide.url));
  }

  function updateSlideDuration(slideId: string, nextDuration: number) {
    const normalizedDuration = Math.min(Math.max(nextDuration || 0.25, 0.25), 60);
    setImageSlides((slides) => {
      const nextSlides = slides.map((slide) => (slide.id === slideId ? { ...slide, duration: normalizedDuration } : slide));
      setDuration(nextSlides.reduce((sum, slide) => sum + slide.duration, 0));
      return nextSlides;
    });
    resetExportState();
  }

  function fitTimelineToDuration(targetDuration: number) {
    setImageSlides((slides) => {
      if (slides.length === 0) return slides;
      const currentDuration = slides.reduce((sum, slide) => sum + slide.duration, 0);
      const nextSlides = slides.map((slide) => ({ ...slide, duration: currentDuration > 0 ? Math.max(0.25, Number(((slide.duration / currentDuration) * targetDuration).toFixed(2))) : Number((targetDuration / slides.length).toFixed(2)) }));
      setDuration(nextSlides.reduce((sum, slide) => sum + slide.duration, 0));
      return nextSlides;
    });
    resetExportState();
  }

  function removeSlide(slideId: string) {
    setImageSlides((slides) => {
      const removedSlide = slides.find((slide) => slide.id === slideId);
      const nextSlides = slides.filter((slide) => slide.id !== slideId);
      if (removedSlide) URL.revokeObjectURL(removedSlide.url);
      if (nextSlides.length === 0) {
        setImageAsset(null);
        setSelectedSlideId("");
        setImageUpload(emptyUploadState);
        setDuration(DEFAULT_DURATION_SECONDS);
      } else {
        const nextSelected = nextSlides.find((slide) => slide.id === selectedSlideId) ?? nextSlides[0];
        setSelectedSlideId(nextSelected.id);
        setImageAsset({ kind: "image", file: nextSelected.file, url: nextSelected.url, width: nextSelected.width, height: nextSelected.height, duration: null });
        setDuration(nextSlides.reduce((sum, slide) => sum + slide.duration, 0));
      }
      resetExportState();
      return nextSlides;
    });
  }

  async function uploadSlideImage(slideId: string, file: File) {
    setImageSlides((slides) => slides.map((slide) => (slide.id === slideId ? { ...slide, upload: { status: "uploading", upload: null, error: "" } } : slide)));
    try {
      const upload = await uploadFile("/api/uploads/image", file);
      setImageSlides((slides) => slides.map((slide) => (slide.id === slideId ? { ...slide, upload: { status: "saved", upload, error: "" } } : slide)));
    } catch (error) {
      setImageSlides((slides) => slides.map((slide) => (slide.id === slideId ? { ...slide, upload: { status: "failed", upload: null, error: error instanceof Error ? error.message : "Upload failed." } } : slide)));
    }
  }

  function toggleAudio() {
    if (!audioRef.current) return;
    if (audioRef.current.paused) {
      void audioRef.current.play();
      setIsAudioPlaying(true);
      return;
    }
    audioRef.current.pause();
    setIsAudioPlaying(false);
  }

  function handleAudioEnded() {
    setIsAudioPlaying(false);
  }

  return {
    refs: { imageInputRef, addImagesInputRef, audioInputRef, audioRef },
    user,
    state: { imageAsset, imageSlides, selectedSlideId, selectedSlide, audioAsset, presetId, selectedPreset, fitMode, duration, imageError, audioError, imageUpload, audioUpload, isAudioPlaying, exportStatus, exportProgress, exportResult, exportError, isImageTimeline, timelineDuration, sourceUploadReady, previewAspectRatio, previewFrameWidth, outputDimensions },
    actions: { handleMediaFiles, handleAdditionalImageFiles, handleAudioFile, removeImage, removeAudio, onImageDrop, onAudioDrop, startExport, resetExportState, handleExportDownload, updateSlideDuration, fitTimelineToDuration, removeSlide, uploadSlideImage, toggleAudio, handleAudioEnded, setSelectedSlideId, setPresetId, setFitMode, setDuration, setExportStatus, setExportProgress, setExportResult, setExportError },
  };
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
    setState({ status: "failed", upload: null, error: error instanceof Error ? error.message : "Upload failed." });
  }
}
