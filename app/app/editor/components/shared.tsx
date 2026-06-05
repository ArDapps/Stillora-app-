import {
  ImagePlus,
  MonitorPlay,
  Music2,
  Play,
  Square,
  type LucideIcon,
} from "lucide-react";
import type { OutputPresetId } from "@/lib/stillora";
import type { UploadState } from "../types";

export const stepBadgeClass =
  "grid size-7 place-items-center rounded-full bg-[linear-gradient(145deg,#a855f7,#6366f1)] text-sm font-bold text-white shadow-[0_0_20px_rgb(168_85_247_/_0.45)]";

export function UploadStatus({ state }: { state: UploadState }) {
  if (state.status === "idle") return null;
  if (state.status === "uploading") {
    return <p className="mt-1 text-xs text-[var(--color-warning)]">Preparing...</p>;
  }
  if (state.status === "failed") {
    return <p className="mt-1 text-xs text-[var(--color-danger)]">{state.error}</p>;
  }
  return <p className="mt-1 text-xs text-[var(--color-success)]">Ready for export</p>;
}

export function PresetIcon({ presetId }: { presetId: OutputPresetId }) {
  const className = "size-4";
  if (presetId === "youtube-shorts" || presetId === "youtube-long") {
    return <Play className={className} />;
  }
  if (presetId === "square") {
    return <ImagePlus className={className} />;
  }
  if (presetId === "original") {
    return <Square className={className} />;
  }
  return <MonitorPlay className={className} />;
}

const socialTargets: Array<{ label: string; icon: LucideIcon }> = [
  { label: "Reels", icon: ImagePlus },
  { label: "Shorts", icon: Play },
  { label: "TikTok", icon: Music2 },
  { label: "Square", icon: Square },
];

export function SocialTargetPills() {
  return (
    <div className="mb-4 flex flex-wrap items-center justify-center gap-2">
      {socialTargets.map(({ label, icon: Icon }) => (
        <span
          className="editor-control-soft inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-semibold"
          key={label}
        >
          <Icon className="size-3.5 text-fuchsia-400" />
          {label}
        </span>
      ))}
    </div>
  );
}
