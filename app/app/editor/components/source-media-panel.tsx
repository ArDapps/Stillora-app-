import { ChangeEvent } from "react";
import { FileImage, FileVideo, ImagePlus, Images, Trash2, UploadCloud } from "lucide-react";
import {
  getFileExtension,
  IMAGE_ACCEPT,
  MEDIA_ACCEPT,
  formatBytes,
} from "@/lib/stillora";
import { formatDuration } from "../editor-utils";
import type { EditorModel } from "../types";
import { stepBadgeClass, UploadStatus } from "./shared";

export function SourceMediaPanel({ model }: { model: EditorModel }) {
  const { refs, state, actions } = model;

  return (
    <section className="editor-card rounded-lg border p-4">
      <div className="mb-3 flex items-center gap-2">
        <span className={stepBadgeClass}>1</span>
        <h1 className="editor-title text-base font-semibold">Upload media</h1>
        <Images size={18} className="ml-auto text-fuchsia-300" />
      </div>

      <button
        className="editor-control flex min-h-40 w-full flex-col items-center justify-center gap-3 rounded-lg border border-dashed px-4 text-center transition hover:border-fuchsia-400 hover:bg-fuchsia-500/10 focus:outline-none focus:ring-2 focus:ring-fuchsia-400"
        onClick={() => refs.imageInputRef.current?.click()}
        onDragOver={(event) => event.preventDefault()}
        onDrop={actions.onImageDrop}
        type="button"
      >
        <UploadCloud size={30} className="text-fuchsia-300" />
        <span className="editor-title text-sm font-semibold">
          {state.imageAsset ? "Replace media" : "Drop image, images, or video"}
        </span>
        <span className="editor-subtle text-xs">
          Select multiple images for a slideshow. Use one video at a time.
        </span>
      </button>

      <input
        ref={refs.imageInputRef}
        accept={MEDIA_ACCEPT}
        className="sr-only"
        multiple
        onChange={(event: ChangeEvent<HTMLInputElement>) => {
          void actions.handleMediaFiles(event.target.files);
          event.target.value = "";
        }}
        type="file"
      />
      <input
        // eslint-disable-next-line react-hooks/refs
        ref={refs.addImagesInputRef}
        accept={IMAGE_ACCEPT}
        className="sr-only"
        multiple
        onChange={(event: ChangeEvent<HTMLInputElement>) => {
          void actions.handleAdditionalImageFiles(event.target.files);
          event.target.value = "";
        }}
        type="file"
      />

      {state.imageError ? <p className="mt-3 text-sm text-[var(--color-danger)]">{state.imageError}</p> : null}
      {state.imageAsset ? <SelectedMedia model={model} /> : null}
      {state.imageAsset?.kind === "image" ? (
        <button
          className="mt-3 inline-flex min-h-10 w-full items-center justify-center gap-2 rounded-md border border-[var(--color-border)] px-3 text-sm font-semibold text-[var(--color-foreground)] transition hover:border-[var(--color-primary)] hover:bg-[var(--color-primary-soft)]"
          onClick={() => refs.addImagesInputRef.current?.click()}
          type="button"
        >
          <ImagePlus size={16} />
          <span>{state.isImageTimeline ? "Add more images" : "Add images to slideshow"}</span>
        </button>
      ) : null}
      {state.isImageTimeline ? <ImageTimeline model={model} /> : null}
    </section>
  );
}

function SelectedMedia({ model }: { model: EditorModel }) {
  const { state, actions } = model;
  const asset = state.imageAsset;
  if (!asset) return null;

  return (
    <div className="editor-control-soft mt-4 rounded-lg border p-3">
      <div className="flex items-start gap-3">
        {asset.kind === "video" ? (
          <FileVideo size={18} className="mt-0.5 text-[var(--color-muted-strong)]" />
        ) : (
          <FileImage size={18} className="mt-0.5 text-[var(--color-muted-strong)]" />
        )}
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-semibold">{asset.file.name}</p>
          <p className="text-xs text-[var(--color-muted-strong)]">
            {asset.width} x {asset.height} - {formatBytes(asset.file.size)} -{" "}
            {getFileExtension(asset.file.name)}
            {asset.duration ? ` - ${formatDuration(asset.duration)}` : ""}
          </p>
          <UploadStatus state={state.imageUpload} />
        </div>
        <button
          aria-label="Remove media"
          className="rounded-md p-1.5 text-[var(--color-muted-strong)] transition hover:bg-[var(--color-danger-soft)] hover:text-[var(--color-danger)]"
          onClick={actions.removeImage}
          type="button"
        >
          <Trash2 size={16} />
        </button>
      </div>
    </div>
  );
}

function ImageTimeline({ model }: { model: EditorModel }) {
  const { state, actions } = model;

  return (
    <div className="mt-4 space-y-2">
      <div className="flex items-center justify-between gap-3">
        <p className="text-sm font-semibold">Image order</p>
        <p className="text-xs text-[var(--color-muted-strong)]">{formatDuration(state.timelineDuration)}</p>
      </div>
      {state.imageSlides.map((slide, index) => (
        <div
          className={`rounded-lg border p-2 transition ${
            state.selectedSlideId === slide.id
              ? "border-[var(--color-primary)] bg-[var(--color-primary-soft)]"
              : "border-[var(--color-border)] bg-[var(--color-card)]"
          }`}
          key={slide.id}
        >
          <button
            className="flex w-full items-center gap-2 text-left"
            onClick={() => actions.setSelectedSlideId(slide.id)}
            type="button"
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img alt={`Slide ${index + 1}`} className="size-10 rounded-md object-cover" src={slide.url} />
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
                className="editor-control-soft mt-1 h-9 w-full rounded-md border px-2 text-sm text-[var(--color-foreground)] focus:outline-none focus:ring-2 focus:ring-fuchsia-400"
                min="0.25"
                onChange={(event) => actions.updateSlideDuration(slide.id, Number(event.target.value))}
                step="0.25"
                type="number"
                value={slide.duration}
              />
            </label>
            <button
              aria-label="Remove slide"
              className="mt-5 rounded-md p-2 text-[var(--color-muted-strong)] transition hover:bg-[var(--color-danger-soft)] hover:text-[var(--color-danger)]"
              onClick={() => actions.removeSlide(slide.id)}
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
  );
}
