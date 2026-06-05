import { ArrowRight, Check, Download, Play, Sparkles } from "lucide-react";
import Link from "next/link";
import { EDITOR_PATH } from "@/lib/site";

const trustNotes = [
  "No complicated timeline",
  "No software installation",
  "1080p export",
  "Up to 5-minute videos",
];

const formatPills = ["Reels", "Shorts", "Square", "YouTube"];

export function Hero() {
  return (
    <section className="relative overflow-hidden">
      <div
        aria-hidden
        className="landing-hero-glow pointer-events-none absolute inset-0"
        style={{ background: "var(--landing-hero-glow)" }}
      />
      <div className="relative mx-auto grid w-full max-w-7xl items-center gap-12 px-5 py-20 lg:grid-cols-[1.05fr_0.95fr] lg:py-28">
        {/* Left column */}
        <div>
          <span className="inline-flex items-center gap-2 rounded-full border border-[var(--color-border)] bg-[var(--color-card)] px-3 py-1 text-xs font-medium tracking-wide text-[var(--color-muted)]">
            <Sparkles size={14} className="text-[var(--color-primary)]" />
            Professional video, without the editor
          </span>
          <h1 className="mt-6 text-4xl font-bold leading-[1.05] tracking-tight sm:text-5xl lg:text-6xl">
            Turn any image into a
            <span className="block bg-[image:var(--brand-gradient)] bg-clip-text text-transparent">
              share-ready video
            </span>
          </h1>
          <p className="mt-6 max-w-xl text-lg leading-relaxed text-[var(--color-muted)]">
            Create polished MP4 videos for Reels, TikTok, Stories, YouTube Shorts, and more. Upload
            an image, add optional audio, choose your format, and export in seconds.
          </p>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <Link
              href={EDITOR_PATH}
              className="inline-flex items-center gap-2 rounded-md bg-[var(--color-primary)] px-6 py-3 text-base font-semibold text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--color-background)]"
            >
              Create a video — free
              <ArrowRight size={18} />
            </Link>
            <a
              href="#how-it-works"
              className="inline-flex items-center gap-2 rounded-md border border-[var(--color-border)] px-6 py-3 text-base font-semibold text-[var(--color-foreground)] transition hover:border-[var(--color-primary)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
            >
              See how it works
            </a>
          </div>
          <ul className="mt-8 flex flex-wrap gap-x-6 gap-y-2">
            {trustNotes.map((note) => (
              <li
                key={note}
                className="flex items-center gap-2 text-sm text-[var(--color-muted-strong)]"
              >
                <Check size={16} className="shrink-0 text-[var(--color-primary)]" />
                {note}
              </li>
            ))}
          </ul>
        </div>

        {/* Right column — editor-style demo mockup (marketing illustration only) */}
        <div className="relative mx-auto w-full max-w-sm">
          <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-4 shadow-2xl shadow-[var(--shadow-card)]">
            <div className="mb-3 flex items-center justify-between px-1">
              <span className="text-sm font-semibold">Preview</span>
              <span className="rounded-md bg-[var(--color-primary-soft)] px-2 py-1 text-xs font-medium text-[var(--color-primary)]">
                Reels · 9:16
              </span>
            </div>

            {/* 9:16 preview frame */}
            <div
              className="relative grid aspect-[9/16] w-full place-items-center overflow-hidden rounded-xl"
              style={{ background: "var(--landing-mock-bg)" }}
            >
              <div className="landing-mock-sheen pointer-events-none absolute inset-0" aria-hidden />
              <div className="flex flex-col items-center gap-3 text-[var(--color-overlay-text)]">
                <div className="grid size-16 place-items-center rounded-full bg-white/10 backdrop-blur">
                  <Play size={26} className="ml-1" />
                </div>
                <p className="text-sm font-medium opacity-80">Your story, in motion</p>
              </div>

              {/* Fit / Fill controls (visual only) */}
              <div className="absolute left-3 top-3 flex gap-1.5">
                <span className="rounded-md bg-white/15 px-2 py-1 text-[11px] font-semibold text-white backdrop-blur">
                  Fit
                </span>
                <span className="rounded-md bg-white/5 px-2 py-1 text-[11px] font-medium text-white/70 backdrop-blur">
                  Fill
                </span>
              </div>

              {/* Audio waveform + progress */}
              <div className="absolute inset-x-0 bottom-0 bg-[var(--color-overlay)] px-4 py-3 backdrop-blur">
                <div
                  className="mb-2 flex h-6 items-end justify-between gap-[3px]"
                  aria-hidden
                >
                  {Array.from({ length: 22 }).map((_, i) => (
                    <span
                      key={i}
                      className="landing-wave-bar w-full rounded-full bg-[var(--color-overlay-fill)]"
                      style={{ animationDelay: `${(i % 11) * 0.12}s` }}
                    />
                  ))}
                </div>
                <div className="mb-1.5 flex justify-between text-xs text-[var(--color-overlay-text)]">
                  <span>0:00</span>
                  <span>0:30</span>
                </div>
                <div className="h-1.5 overflow-hidden rounded-full bg-[var(--color-overlay-track)]">
                  <div className="landing-progress h-full rounded-full bg-[var(--color-overlay-fill)]" />
                </div>
              </div>
            </div>

            {/* Format pills */}
            <div className="mt-3 flex flex-wrap gap-1.5">
              {formatPills.map((pill, i) => (
                <span
                  key={pill}
                  className={`rounded-md px-2.5 py-1 text-xs font-medium ${
                    i === 0
                      ? "bg-[var(--color-primary-soft)] text-[var(--color-primary)]"
                      : "border border-[var(--color-border)] text-[var(--color-muted-strong)]"
                  }`}
                >
                  {pill}
                </span>
              ))}
            </div>

            {/* Export result */}
            <div className="mt-3 flex items-center justify-between gap-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-2.5">
              <span className="flex items-center gap-2 text-sm font-medium">
                <Download size={16} className="text-[var(--color-primary)]" />
                final.mp4
              </span>
              <span className="text-xs text-[var(--color-muted-strong)]">1080 × 1920</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
