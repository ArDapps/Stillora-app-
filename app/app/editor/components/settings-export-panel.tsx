import { Crop, Download, Film, Loader2, MonitorPlay, RotateCcw, Sparkles, Timer } from "lucide-react";
import {
  DEFAULT_DURATION_SECONDS,
  FIXED_DURATION_SECONDS,
  FitMode,
  OUTPUT_PRESETS,
} from "@/lib/stillora";
import { startGoogleSignIn } from "@/app/components/use-session";
import { formatDuration, getAudioFitDuration } from "../editor-utils";
import type { EditorModel } from "../types";
import { PresetIcon, stepBadgeClass } from "./shared";

export function SettingsExportPanel({ model }: { model: EditorModel }) {
  return (
    <aside className="editor-animate-in space-y-4">
      <PresetPanel model={model} />
      <ImageModePanel model={model} />
      <DurationPanel model={model} />
      <ExportPanel model={model} />
    </aside>
  );
}

function clearExport(model: EditorModel) {
  model.actions.setExportStatus("idle");
  model.actions.setExportProgress(0);
  model.actions.setExportResult(null);
  model.actions.setExportError("");
}

function PresetPanel({ model }: { model: EditorModel }) {
  const { state, actions } = model;

  return (
    <section className="editor-card rounded-lg border p-4">
      <h2 className="editor-title flex items-center gap-2 text-base font-semibold">
        <MonitorPlay size={18} className="text-fuchsia-300" />
        Output preset
      </h2>
      <div className="mt-3 grid gap-2">
        {OUTPUT_PRESETS.map((preset) => (
          <button
            className={`rounded-lg border p-3 text-left transition focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)] ${
              preset.id === state.presetId ? "editor-active" : "editor-control-soft hover:border-fuchsia-300"
            }`}
            key={preset.id}
            onClick={() => {
              actions.setPresetId(preset.id);
              clearExport(model);
            }}
            type="button"
          >
            <span className="flex items-center gap-2 text-sm font-semibold">
              <span className="grid size-7 place-items-center rounded-md bg-[linear-gradient(145deg,#22d3ee,#a855f7,#ec4899)] text-white">
                <PresetIcon presetId={preset.id} />
              </span>
              {preset.name}
            </span>
            <span className="editor-subtle mt-1 block text-xs">{preset.details}</span>
          </button>
        ))}
      </div>
    </section>
  );
}

function ImageModePanel({ model }: { model: EditorModel }) {
  const { state, actions } = model;

  return (
    <section className="editor-card rounded-lg border p-4">
      <h2 className="editor-title flex items-center gap-2 text-base font-semibold">
        <Crop size={18} className="text-cyan-200" />
        Image mode
      </h2>
      <div className="mt-3 grid grid-cols-2 gap-2">
        {(["fit", "fill"] as FitMode[]).map((mode) => (
          <button
            className={`rounded-md border px-3 py-2 text-sm font-semibold uppercase tracking-normal transition focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)] ${
              state.fitMode === mode ? "editor-active" : "editor-control-soft hover:border-fuchsia-300"
            }`}
            key={mode}
            onClick={() => actions.setFitMode(mode)}
            type="button"
          >
            {mode}
          </button>
        ))}
      </div>
      <p className="editor-subtle mt-3 text-sm">
        Fit shows the full image. Fill crops edges to cover the frame.
      </p>
    </section>
  );
}

function DurationPanel({ model }: { model: EditorModel }) {
  const { state, actions } = model;

  return (
    <section className="editor-card rounded-lg border p-4">
      <div className="mb-3 flex items-center gap-2">
        <span className={stepBadgeClass}>3</span>
        <h2 className="editor-title text-base font-semibold">Duration</h2>
        <Timer size={18} className="ml-auto text-fuchsia-300" />
      </div>
      {state.isImageTimeline ? (
        <div className="mt-3 space-y-2">
          <div className="editor-control-soft rounded-lg border border-cyan-300/40 p-3 text-sm">
            Timeline duration is controlled by each image row:{" "}
            <span className="font-semibold">{formatDuration(state.timelineDuration)}</span>
          </div>
          {state.audioAsset?.duration ? (
            <button
              className="editor-control-soft w-full rounded-md border px-3 py-2 text-sm font-semibold transition hover:border-cyan-300"
              onClick={() => actions.fitTimelineToDuration(getAudioFitDuration(state.audioAsset?.duration ?? 0))}
              type="button"
            >
              Fit image timings to audio - {formatDuration(getAudioFitDuration(state.audioAsset.duration))}
            </button>
          ) : null}
        </div>
      ) : (
        <div className="mt-3 space-y-2">
          {state.audioAsset?.duration ? (
            <button
              className="editor-control-soft w-full rounded-md border px-3 py-2 text-sm font-semibold transition hover:border-cyan-300"
              onClick={() => {
                actions.setDuration(getAudioFitDuration(state.audioAsset?.duration ?? 0));
                clearExport(model);
              }}
              type="button"
            >
              Fit to audio - {formatDuration(getAudioFitDuration(state.audioAsset.duration))}
            </button>
          ) : null}
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {FIXED_DURATION_SECONDS.map((option) => (
              <DurationButton
                isSelected={state.duration === option}
                key={option}
                label={`${option} seconds`}
                onClick={() => {
                  actions.setDuration(option);
                  clearExport(model);
                }}
              />
            ))}
          </div>
        </div>
      )}
    </section>
  );
}

function DurationButton({
  isSelected,
  label,
  onClick,
  wide,
}: {
  isSelected: boolean;
  label: string;
  onClick: () => void;
  wide?: boolean;
}) {
  return (
    <button
      className={`${wide ? "col-span-2" : ""} rounded-md border px-3 py-2 text-sm font-semibold transition focus:outline-none focus:ring-2 focus:ring-[var(--color-secondary)] ${
        isSelected ? "editor-active" : "editor-control-soft hover:border-fuchsia-300"
      }`}
      onClick={onClick}
      type="button"
    >
      {label}
    </button>
  );
}

function ExportPanel({ model }: { model: EditorModel }) {
  const { state, actions, user } = model;
  const disabled =
    !state.imageAsset ||
    !state.sourceUploadReady ||
    (Boolean(state.audioAsset) && state.audioUpload.status !== "saved") ||
    state.exportStatus === "exporting";
  const canReset =
    Boolean(state.imageAsset) ||
    state.isImageTimeline ||
    Boolean(state.audioAsset) ||
    state.presetId !== "reels" ||
    state.fitMode !== "fit" ||
    state.duration !== DEFAULT_DURATION_SECONDS;

  return (
    <section className="editor-card rounded-lg border p-4">
      <h2 className="editor-title flex items-center gap-2 text-base font-semibold">
        <Film size={18} className="text-cyan-200" />
        Export
      </h2>
      <dl className="mt-3 grid gap-2 text-sm">
        <ExportRow label="Preset" value={state.selectedPreset.name} />
        <ExportRow label="Output" value={state.outputDimensions} />
        <ExportRow label="Audio" value={state.audioAsset ? "Added audio" : state.imageAsset?.kind === "video" ? "Source audio" : "Silent"} />
        <ExportRow label="Duration" value={formatDuration(state.duration)} />
        <ExportRow label="Media" value={state.sourceUploadReady && (!state.audioAsset || state.audioUpload.status === "saved") ? "Ready" : "Pending"} />
      </dl>
      {state.exportStatus === "ready" && state.exportResult ? (
        <a
          className="mt-4 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-md bg-[var(--color-success)] px-3 py-2 text-center text-sm font-semibold leading-tight text-[var(--color-success-text)] shadow-sm shadow-[var(--shadow-success)] transition hover:bg-[var(--color-secondary-hover)] sm:px-4"
          download={state.exportResult.filename}
          href={state.exportResult.downloadUrl}
          onClick={actions.handleExportDownload}
        >
          <Download size={18} className="shrink-0" />
          <span className="min-w-0">Download final MP4</span>
        </a>
      ) : !user ? (
        <button
          className="mt-4 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-md bg-[var(--color-primary)] px-3 py-2 text-center text-sm font-semibold leading-tight text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)] sm:px-4"
          onClick={() => startGoogleSignIn("/editor")}
          type="button"
        >
          <Sparkles size={18} className="shrink-0" />
          <span className="min-w-0">Sign in with Google to export</span>
        </button>
      ) : (
        <button
          className="mt-4 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-md bg-[var(--color-primary)] px-3 py-2 text-center text-sm font-semibold leading-tight text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)] disabled:cursor-not-allowed disabled:bg-[var(--color-disabled)] sm:px-4"
          disabled={disabled}
          onClick={() => void actions.startExport()}
          type="button"
        >
          {state.exportStatus === "exporting" ? <Loader2 size={18} className="shrink-0 animate-spin" /> : <Sparkles size={18} className="shrink-0" />}
          <span className="min-w-0">{state.exportStatus === "exporting" ? "Exporting" : "Export MP4"}</span>
        </button>
      )}
      {!user ? <p className="mt-2 text-center text-xs text-[var(--color-muted-strong)]">Set everything up now — you only sign in when you export.</p> : null}
      {state.exportError ? <p className="mt-3 text-sm text-[var(--color-danger)]">{state.exportError}</p> : null}
      {state.exportStatus !== "idle" ? (
        <div className="mt-4">
          <div className="mb-2 flex justify-between text-xs font-medium text-[var(--color-muted-strong)]">
            <span>{state.exportStatus === "ready" ? "Ready" : "Generating"}</span>
            <span>{state.exportProgress}%</span>
          </div>
          <div className="h-2 overflow-hidden rounded-full bg-[var(--color-surface-dim)]">
            <div className="h-full rounded-full bg-[var(--color-success)] transition-all" style={{ width: `${state.exportProgress}%` }} />
          </div>
        </div>
      ) : null}
      {canReset ? (
        <button
          className="mt-3 inline-flex min-h-10 w-full items-center justify-center gap-2 rounded-md border border-[var(--color-border)] px-3 py-2 text-sm font-semibold text-[var(--color-muted-strong)] transition hover:border-[var(--color-danger)] hover:text-[var(--color-danger)] disabled:cursor-not-allowed disabled:opacity-50"
          disabled={state.exportStatus === "exporting"}
          onClick={() => {
            if (window.confirm("Clear all media, audio, and settings and start over?")) actions.resetEditor();
          }}
          type="button"
        >
          <RotateCcw size={16} className="shrink-0" />
          <span>Start over</span>
        </button>
      ) : null}
    </section>
  );
}

function ExportRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-3">
      <dt className="text-[var(--color-muted-strong)]">{label}</dt>
      <dd className="text-right font-medium">{value}</dd>
    </div>
  );
}
