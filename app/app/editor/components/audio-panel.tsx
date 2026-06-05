import { ChangeEvent } from "react";
import { Music2, Pause, Play, Trash2, UploadCloud } from "lucide-react";
import { AUDIO_ACCEPT, formatBytes } from "@/lib/stillora";
import { formatDuration } from "../editor-utils";
import type { EditorModel } from "../types";
import { stepBadgeClass, UploadStatus } from "./shared";

export function AudioPanel({ model }: { model: EditorModel }) {
  const { refs, state, actions } = model;

  return (
    <section className="editor-card rounded-lg border p-4">
      <div className="mb-3 flex items-center gap-2">
        <span className={stepBadgeClass}>2</span>
        <h2 className="editor-title text-base font-semibold">Add audio</h2>
        <span className="ml-auto text-xs font-medium text-[var(--color-muted-strong)]">Optional</span>
        <Music2 size={18} className="text-cyan-200" />
      </div>
      <button
        className="editor-control flex min-h-28 w-full flex-col items-center justify-center gap-2 rounded-lg border border-dashed px-4 text-center transition hover:border-cyan-300 hover:bg-cyan-400/10 focus:outline-none focus:ring-2 focus:ring-cyan-300"
        onClick={() => refs.audioInputRef.current?.click()}
        onDragOver={(event) => event.preventDefault()}
        onDrop={actions.onAudioDrop}
        type="button"
      >
        <UploadCloud size={24} className="text-cyan-200" />
        <span className="editor-title text-sm font-semibold">
          {state.audioAsset ? "Replace audio" : "Add optional audio"}
        </span>
        <span className="editor-subtle text-xs">MP3, WAV, M4A, AAC, or OGG</span>
      </button>
      <input
        // eslint-disable-next-line react-hooks/refs
        ref={refs.audioInputRef}
        accept={AUDIO_ACCEPT}
        className="sr-only"
        onChange={(event: ChangeEvent<HTMLInputElement>) => void actions.handleAudioFile(event.target.files?.[0])}
        type="file"
      />
      {state.audioError ? <p className="mt-3 text-sm text-[var(--color-danger)]">{state.audioError}</p> : null}
      {state.audioAsset ? <SelectedAudio model={model} /> : null}
    </section>
  );
}

function SelectedAudio({ model }: { model: EditorModel }) {
  const { refs, state, actions } = model;
  const asset = state.audioAsset;
  if (!asset) return null;

  return (
    <div className="editor-control-soft mt-4 rounded-lg border p-3">
      <div className="flex items-start gap-3">
        <button
          aria-label={state.isAudioPlaying ? "Pause audio" : "Play audio"}
          className="grid size-9 shrink-0 place-items-center rounded-md bg-[var(--color-secondary-soft)] text-[var(--color-secondary-text)] transition hover:bg-[var(--color-secondary)]"
          onClick={actions.toggleAudio}
          type="button"
        >
          {state.isAudioPlaying ? <Pause size={16} /> : <Play size={16} />}
        </button>
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-semibold">{asset.file.name}</p>
          <p className="text-xs text-[var(--color-muted-strong)]">
            {formatBytes(asset.file.size)}
            {asset.duration ? ` - ${formatDuration(asset.duration)}` : ""}
          </p>
          <UploadStatus state={state.audioUpload} />
        </div>
        <button
          aria-label="Remove audio"
          className="rounded-md p-1.5 text-[var(--color-muted-strong)] transition hover:bg-[var(--color-danger-soft)] hover:text-[var(--color-danger)]"
          onClick={actions.removeAudio}
          type="button"
        >
          <Trash2 size={16} />
        </button>
      </div>
      <audio
        // eslint-disable-next-line react-hooks/refs
        ref={refs.audioRef}
        onEnded={actions.handleAudioEnded}
        src={asset.url}
      />
    </div>
  );
}
