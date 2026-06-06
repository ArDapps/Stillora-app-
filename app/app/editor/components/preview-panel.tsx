import { Clock, ImagePlus, Music2, Play, Square, Wand2 } from "lucide-react";
import { formatDuration } from "../editor-utils";
import type { EditorModel } from "../types";
import { SocialTargetPills } from "./shared";

export function PreviewPanel({ model }: { model: EditorModel }) {
  const { state } = model;

  return (
    <section className="editor-preview-panel editor-animate-in relative flex min-h-[600px] flex-col rounded-lg border border-[var(--editor-card-border)] lg:h-full lg:min-h-0">
      <div className="flex-shrink-0 border-b border-[var(--editor-card-border)] px-4 py-3">
        <div className="flex items-center justify-between">
          <div>
            <p className="editor-title text-sm font-semibold">MP4 Preview</p>
            <p className="editor-subtle text-xs">
              {state.outputDimensions} · {formatDuration(state.duration)} · {state.fitMode.toUpperCase()}
            </p>
          </div>
          <div className="editor-control-soft flex items-center gap-2 rounded-md border px-2.5 py-1.5 text-xs font-medium">
            <Clock size={14} />
            Timeline ready
          </div>
        </div>
        <SocialTargetPills className="mt-3" />
      </div>

      <div className="grid min-h-0 flex-1 place-items-center overflow-hidden p-4 sm:p-6">
        <div className="editor-preview-glow-shell relative grid w-full max-w-full place-items-center">
          <div
            className="editor-preview-frame relative grid max-h-[min(70dvh,720px)] max-w-full place-items-center overflow-hidden rounded-[18px] border border-cyan-300/70 shadow-[0_0_0_1px_rgb(255_255_255_/_0.08),0_0_44px_rgb(34_211_238_/_0.34),0_0_90px_rgb(217_70_239_/_0.2),0_30px_70px_rgb(0_0_0_/_0.46)]"
            style={{ aspectRatio: state.previewAspectRatio, width: `min(100%, ${state.previewFrameWidth}px)` }}
          >
            <PreviewMedia model={model} />
            <div className="absolute bottom-0 left-0 right-0 bg-[var(--color-overlay)] px-4 py-3 text-[var(--color-primary-text)] backdrop-blur">
              <div className="mb-2 flex items-center justify-between text-xs">
                <span>0:00</span>
                <span>{formatDuration(state.duration)}</span>
              </div>
              <div className="h-1.5 overflow-hidden rounded-full bg-[var(--color-overlay-track)]">
                <div className="h-full w-1/3 rounded-full bg-[var(--color-overlay-fill)]" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function PreviewMedia({ model }: { model: EditorModel }) {
  const { state } = model;
  const className = `h-full w-full ${state.fitMode === "fit" ? "object-contain" : "object-cover"}`;

  if (state.selectedSlide) {
    if (state.selectedSlide.kind === "video") {
      return <video className={className} controls muted playsInline src={state.selectedSlide.url} />;
    }
    // eslint-disable-next-line @next/next/no-img-element
    return <img alt="Selected timeline slide preview" className={className} src={state.selectedSlide.url} />;
  }

  if (state.imageAsset?.kind === "image") {
    // eslint-disable-next-line @next/next/no-img-element
    return <img alt="Uploaded composition preview" className={className} src={state.imageAsset.url} />;
  }

  if (state.imageAsset?.kind === "video") {
    return <video className={className} controls muted playsInline src={state.imageAsset.url} />;
  }

  return (
    <div className="flex max-w-[200px] flex-col items-center gap-3 px-4 text-center text-[var(--color-primary-text)]">
      <Wand2 size={34} />
      <p className="text-base font-semibold">Upload media to begin</p>
      <p className="text-xs text-[var(--color-muted)]">
        The preview will match the final video frame without stretching your media.
      </p>
      <div className="mt-1 flex items-center gap-2 text-xs">
        <ImagePlus size={14} />
        <Play size={14} />
        <Music2 size={14} />
        <Square size={14} />
      </div>
    </div>
  );
}
