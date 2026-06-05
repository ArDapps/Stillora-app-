import type {
  FitMode,
  OutputPreset,
  OutputPresetId,
  SourceMediaKind,
  StoredUpload,
} from "@/lib/stillora";

export type UploadState = {
  status: "idle" | "uploading" | "saved" | "failed";
  upload: StoredUpload | null;
  error: string;
};

export type SourceAsset = {
  kind: SourceMediaKind;
  file: File;
  url: string;
  width: number;
  height: number;
  duration: number | null;
};

export type ImageSlide = {
  id: string;
  file: File;
  url: string;
  width: number;
  height: number;
  duration: number;
  upload: UploadState;
};

export type AudioAsset = {
  file: File;
  url: string;
  duration: number | null;
};

export type ExportResult = {
  id: string;
  filename: string;
  downloadUrl: string;
};

export type EditorRefs = {
  imageInputRef: React.RefObject<HTMLInputElement | null>;
  addImagesInputRef: React.RefObject<HTMLInputElement | null>;
  audioInputRef: React.RefObject<HTMLInputElement | null>;
  audioRef: React.RefObject<HTMLAudioElement | null>;
};

export type EditorState = {
  imageAsset: SourceAsset | null;
  imageSlides: ImageSlide[];
  selectedSlideId: string;
  selectedSlide: ImageSlide | undefined;
  audioAsset: AudioAsset | null;
  presetId: OutputPresetId;
  selectedPreset: OutputPreset;
  fitMode: FitMode;
  duration: number;
  imageError: string;
  audioError: string;
  imageUpload: UploadState;
  audioUpload: UploadState;
  isAudioPlaying: boolean;
  exportStatus: "idle" | "exporting" | "ready";
  exportProgress: number;
  exportResult: ExportResult | null;
  exportError: string;
  isImageTimeline: boolean;
  timelineDuration: number;
  sourceUploadReady: boolean;
  previewAspectRatio: number;
  previewFrameWidth: number;
  outputDimensions: string;
};

export type EditorActions = {
  handleMediaFiles: (files: FileList | File[] | null | undefined) => Promise<void>;
  handleAdditionalImageFiles: (files: FileList | File[] | null | undefined) => Promise<void>;
  handleAudioFile: (file: File | undefined) => Promise<void>;
  removeImage: () => void;
  removeAudio: () => void;
  onImageDrop: (event: React.DragEvent<HTMLButtonElement>) => void;
  onAudioDrop: (event: React.DragEvent<HTMLButtonElement>) => void;
  startExport: () => Promise<void>;
  resetExportState: () => void;
  handleExportDownload: () => void;
  updateSlideDuration: (slideId: string, nextDuration: number) => void;
  fitTimelineToDuration: (targetDuration: number) => void;
  removeSlide: (slideId: string) => void;
  uploadSlideImage: (slideId: string, file: File) => Promise<void>;
  toggleAudio: () => void;
  handleAudioEnded: () => void;
  setSelectedSlideId: (slideId: string) => void;
  setPresetId: (presetId: OutputPresetId) => void;
  setFitMode: (fitMode: FitMode) => void;
  setDuration: (duration: number) => void;
  setExportStatus: (status: "idle" | "exporting" | "ready") => void;
  setExportProgress: (progress: number) => void;
  setExportResult: (result: ExportResult | null) => void;
  setExportError: (error: string) => void;
};

export type EditorModel = {
  refs: EditorRefs;
  state: EditorState;
  actions: EditorActions;
  user: ReturnType<typeof import("@/app/components/use-session").useSession>["user"];
};
