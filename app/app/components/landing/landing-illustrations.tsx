import { AudioLines, ImageIcon, Play, Sparkles } from "lucide-react";

type Tone = "violet" | "cyan" | "rose" | "amber" | "emerald" | "blue";

const TONE_CLASSES: Record<Tone, string> = {
  violet: "from-violet-500/30 via-fuchsia-500/20 to-sky-500/25",
  cyan: "from-cyan-400/30 via-blue-500/20 to-violet-500/25",
  rose: "from-rose-400/30 via-fuchsia-500/20 to-orange-400/25",
  amber: "from-amber-300/35 via-orange-400/20 to-pink-500/25",
  emerald: "from-emerald-300/30 via-teal-400/20 to-cyan-500/25",
  blue: "from-blue-400/30 via-indigo-500/20 to-cyan-400/25",
};

type LandingVisualProps = {
  label: string;
  ratio?: string;
  tone?: Tone;
  compact?: boolean;
};

export function LandingVisual({
  label,
  ratio = "9 / 16",
  tone = "violet",
  compact = false,
}: LandingVisualProps) {
  return (
    <div
      className={`relative overflow-hidden rounded-lg border border-[var(--color-border)] bg-gradient-to-br ${TONE_CLASSES[tone]} ${
        compact ? "h-28" : "h-44"
      }`}
    >
      <div className="landing-mock-sheen pointer-events-none absolute inset-0" aria-hidden />
      <div className="absolute left-3 top-3 flex items-center gap-1.5 rounded-md bg-black/35 px-2 py-1 text-[11px] font-semibold text-white backdrop-blur">
        <Sparkles size={12} aria-hidden />
        {label}
      </div>
      <div className="absolute right-3 top-3 grid size-8 place-items-center rounded-full bg-white/18 text-white backdrop-blur">
        <Play size={14} className="ml-0.5" aria-hidden />
      </div>
      <div className="absolute inset-x-5 bottom-4 flex items-end justify-center gap-3">
        <div
          className="relative overflow-hidden rounded-lg border border-white/35 bg-black/18 shadow-2xl shadow-black/20"
          style={{ height: compact ? 76 : 116, aspectRatio: ratio }}
        >
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_35%_25%,rgba(255,255,255,.45),transparent_24%),linear-gradient(145deg,rgba(255,255,255,.18),rgba(255,255,255,.02))]" />
          <div className="absolute inset-x-2 bottom-2 h-1 rounded-full bg-white/55" />
        </div>
        <div className="hidden flex-col gap-1.5 sm:flex" aria-hidden>
          <span className="h-2 w-10 rounded-full bg-white/35" />
          <span className="h-2 w-7 rounded-full bg-white/25" />
          <span className="h-2 w-12 rounded-full bg-white/30" />
        </div>
      </div>
    </div>
  );
}

export function MiniMediaFlow() {
  return (
    <div className="grid gap-3 sm:grid-cols-[1fr_auto_1fr] sm:items-center">
      <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-4">
        <div className="flex items-center gap-3">
          <div className="grid size-10 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
            <ImageIcon size={18} aria-hidden />
          </div>
          <div>
            <p className="text-sm font-semibold">Upload</p>
            <p className="text-xs text-[var(--color-muted)]">Image, clip, or audio</p>
          </div>
        </div>
      </div>
      <div className="mx-auto grid size-10 place-items-center rounded-full bg-[var(--color-primary)] text-[var(--color-primary-text)]">
        <Play size={16} className="ml-0.5" aria-hidden />
      </div>
      <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-4">
        <div className="flex items-center gap-3">
          <div className="grid size-10 place-items-center rounded-lg bg-[var(--color-secondary-soft)] text-[var(--color-secondary-text)]">
            <AudioLines size={18} aria-hidden />
          </div>
          <div>
            <p className="text-sm font-semibold">Export MP4</p>
            <p className="text-xs text-[var(--color-muted)]">Ready for every channel</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export function PlatformPills() {
  const labels = ["Reels", "TikTok", "Shorts", "YouTube", "Square", "Original"];

  return (
    <div className="flex flex-wrap justify-center gap-2">
      {labels.map((label) => (
        <span
          key={label}
          className="rounded-md border border-[var(--color-border)] bg-[var(--color-card)] px-3 py-1.5 text-xs font-semibold text-[var(--color-muted-strong)]"
        >
          {label}
        </span>
      ))}
    </div>
  );
}
