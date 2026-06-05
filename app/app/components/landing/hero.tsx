import {
  ArrowRight,
  Check,
  Download,
  ImageIcon,
  Layers3,
  Music2,
  Play,
  Sparkles,
} from "lucide-react";
import Link from "next/link";
import { EDITOR_PATH } from "@/lib/site";

const trustNotes = ["No timeline", "1080p MP4", "Audio ready", "Six social formats"];
const frames = [
  { label: "9:16", className: "h-36 w-20 sm:h-52 sm:w-29", active: true },
  { label: "1:1", className: "h-24 w-24 sm:h-34 sm:w-34", active: false },
  { label: "16:9", className: "h-20 w-36 sm:h-26 sm:w-48", active: false },
];

export function Hero() {
  return (
    <section className="landing-section overflow-hidden px-5 pb-16 pt-12 sm:pb-20 lg:pb-28 lg:pt-20">
      <div className="mx-auto grid w-full max-w-7xl gap-10 lg:grid-cols-[0.88fr_1.12fr] lg:items-center">
        <div>
          <span className="landing-kicker">
            <Sparkles size={14} className="text-[var(--color-secondary)]" aria-hidden />
            Image to MP4 studio
          </span>
          <h1 className="mt-6 max-w-3xl text-5xl font-black leading-none sm:text-6xl lg:text-7xl">
            One upload.
            <span className="block bg-[image:var(--brand-gradient)] bg-clip-text text-transparent">
              Every video format.
            </span>
          </h1>
          <p className="mt-6 max-w-2xl text-lg leading-8 text-[var(--color-muted)] sm:text-xl">
            Turn photos, slideshows, clips, and audio into polished MP4 posts for Reels, TikTok,
            Shorts, YouTube, square feeds, and original-size exports.
          </p>
          <div className="mt-9 flex flex-col gap-3 sm:flex-row">
            <Link
              href={EDITOR_PATH}
              className="inline-flex items-center justify-center gap-2 rounded-md bg-[var(--color-primary)] px-6 py-3.5 text-base font-bold text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
            >
              Open editor
              <ArrowRight size={18} aria-hidden />
            </Link>
            <a
              href="#formats"
              className="inline-flex items-center justify-center gap-2 rounded-md border border-[var(--color-border)] bg-[var(--color-card)] px-6 py-3.5 text-base font-bold text-[var(--color-foreground)] transition hover:border-[var(--color-primary)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
            >
              View formats
            </a>
          </div>
          <ul className="mt-8 grid gap-2 text-sm font-semibold text-[var(--color-muted-strong)] sm:grid-cols-2">
            {trustNotes.map((note) => (
              <li key={note} className="flex items-center gap-2">
                <Check size={16} className="shrink-0 text-[var(--color-secondary)]" aria-hidden />
                {note}
              </li>
            ))}
          </ul>
        </div>

        <div className="relative min-h-[520px] lg:min-h-[620px]">
          <div className="landing-glass absolute inset-x-0 top-4 rounded-lg p-4 sm:p-5">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-[var(--color-border)] pb-4">
              <div className="flex items-center gap-3">
                <div className="grid size-10 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                  <Layers3 size={20} aria-hidden />
                </div>
                <div>
                  <p className="text-sm font-bold">Stillora workspace</p>
                  <p className="text-xs text-[var(--color-muted)]">photo + music + export presets</p>
                </div>
              </div>
              <span className="rounded-md bg-[var(--color-secondary-soft)] px-3 py-1.5 text-xs font-bold text-[var(--color-secondary-text)]">
                Rendering preview
              </span>
            </div>

            <div className="mt-5 grid gap-4 lg:grid-cols-[0.9fr_1.1fr]">
              <div className="space-y-3">
                <div className="rounded-lg border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface)]/60 p-4">
                  <div className="flex items-center gap-3">
                    <div className="grid size-11 place-items-center rounded-lg bg-[var(--color-card-highest)] text-[var(--color-secondary)]">
                      <ImageIcon size={22} aria-hidden />
                    </div>
                    <div>
                      <p className="text-sm font-bold">mountain-cover.webp</p>
                      <p className="text-xs text-[var(--color-muted)]">Drag, drop, done</p>
                    </div>
                  </div>
                </div>
                <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)]/60 p-4">
                  <div className="flex items-center gap-3">
                    <div className="grid size-11 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                      <Music2 size={21} aria-hidden />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-bold">summer-lofi-beat.mp3</p>
                      <div className="mt-2 flex h-5 items-end gap-1" aria-hidden>
                        {Array.from({ length: 18 }).map((_, index) => (
                          <span
                            key={index}
                            className="w-full rounded-full bg-[var(--color-secondary)]/70"
                            style={{ height: `${32 + ((index * 17) % 60)}%` }}
                          />
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
                <div className="grid grid-cols-3 gap-2">
                  {["5s", "10s", "30s"].map((duration, index) => (
                    <span
                      key={duration}
                      className={`rounded-md border px-3 py-2 text-center text-sm font-bold ${
                        index === 1
                          ? "border-[var(--color-primary)] bg-[var(--color-primary-soft)] text-[var(--color-primary)]"
                          : "border-[var(--color-border)] text-[var(--color-muted-strong)]"
                      }`}
                    >
                      {duration}
                    </span>
                  ))}
                </div>
              </div>

              <div className="relative overflow-hidden rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-dim)] p-5">
                <div className="landing-mock-sheen pointer-events-none absolute inset-0" aria-hidden />
                <div className="relative flex min-h-[300px] items-center justify-center gap-4">
                  {frames.map((frame) => (
                    <div
                      key={frame.label}
                      className={`${frame.className} relative overflow-hidden rounded-lg border ${
                        frame.active
                          ? "border-[var(--color-secondary)] shadow-[0_0_32px_rgb(34_211_238_/_24%)]"
                          : "border-[var(--color-border)] opacity-75"
                      }`}
                      style={{ background: "var(--landing-mock-bg)" }}
                    >
                      <div className="absolute inset-0 bg-[linear-gradient(160deg,rgba(255,255,255,.18),transparent_38%),radial-gradient(circle_at_50%_28%,rgba(244,114,182,.45),transparent_26%)]" />
                      <span className="absolute left-2 top-2 rounded-md bg-black/35 px-2 py-1 text-[10px] font-bold text-white backdrop-blur">
                        {frame.label}
                      </span>
                      {frame.active ? (
                        <div className="absolute inset-0 grid place-items-center">
                          <span className="grid size-14 place-items-center rounded-full bg-white/16 text-white backdrop-blur">
                            <Play size={24} className="ml-1" aria-hidden />
                          </span>
                        </div>
                      ) : null}
                    </div>
                  ))}
                </div>
              </div>
            </div>

            <div className="mt-4 flex flex-wrap items-center justify-between gap-3 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)]/62 px-4 py-3">
              <div className="flex items-center gap-2 text-sm font-bold">
                <Download size={17} className="text-[var(--color-secondary)]" aria-hidden />
                stillora-export.mp4
              </div>
              <div className="h-2 min-w-36 flex-1 overflow-hidden rounded-full bg-[var(--color-overlay-track)]">
                <div className="landing-progress h-full rounded-full bg-[image:var(--brand-gradient)]" />
              </div>
              <span className="text-xs font-bold text-[var(--color-muted-strong)]">1080p</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
