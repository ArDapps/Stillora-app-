import { ArrowRight, Clock, Film, ImageIcon, Maximize2, Play, Sparkles } from "lucide-react";
import { SHOWCASES } from "@/lib/landing-content";
import { SectionHeading } from "./section-heading";

const OUTPUT_COLORS = [
  "from-cyan-400/28 via-violet-500/18 to-pink-500/24",
  "from-blue-400/28 via-cyan-500/16 to-violet-500/22",
  "from-fuchsia-400/26 via-rose-500/18 to-orange-400/22",
];

export function Showcase() {
  return (
    <section aria-label="Image to video transformation" className="landing-section">
      <div className="mx-auto w-full max-w-7xl px-5 py-20">
        <div className="grid gap-8 lg:grid-cols-[0.82fr_1.18fr] lg:items-end">
          <SectionHeading
            eyebrow="Conversion lab"
            title="Upload once. Ship the same idea everywhere."
            description="A single source image can become vertical shorts, landscape videos, or feed-ready posts without rebuilding the project."
          />
          <div className="hidden justify-end lg:flex">
            <div className="landing-glass flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-bold text-[var(--color-muted)]">
              <span className="landing-float-icon grid size-9 place-items-center rounded-lg bg-[var(--color-secondary-soft)] text-[var(--color-secondary-text)]">
                <Sparkles size={18} aria-hidden />
              </span>
              Smart resize, audio merge, MP4 export
            </div>
          </div>
        </div>

        <div className="landing-card mt-12 grid gap-5 rounded-lg p-5 lg:grid-cols-[0.9fr_auto_1.35fr] lg:items-stretch">
          <div className="relative overflow-hidden rounded-lg border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface)]/64 p-5">
            <div className="landing-mock-sheen pointer-events-none absolute inset-0" aria-hidden />
            <div className="relative flex items-center gap-3">
              <div className="grid size-12 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                <ImageIcon size={24} aria-hidden />
              </div>
              <div>
                <p className="text-sm font-black">Source media</p>
                <p className="text-xs font-semibold text-[var(--color-muted)]">Image, slideshow, or clip</p>
              </div>
            </div>
            <div className="relative mt-5 aspect-[4/5] overflow-hidden rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-dim)]">
              <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_24%,rgba(244,114,182,.38),transparent_26%),linear-gradient(160deg,rgba(34,211,238,.32),transparent_42%),var(--landing-mock-bg)]" />
              <div className="absolute inset-x-4 bottom-4 space-y-2">
                <span className="block h-2 rounded-full bg-white/55" />
                <span className="block h-2 w-2/3 rounded-full bg-white/35" />
              </div>
            </div>
          </div>

          <div className="flex items-center justify-center">
            <div className="landing-pulse-ring grid size-16 place-items-center rounded-full bg-[var(--color-primary)] text-[var(--color-primary-text)] shadow-[var(--shadow-primary)]">
              <ArrowRight size={26} aria-hidden />
            </div>
          </div>

          <div className="grid gap-3">
            {SHOWCASES.map((item, index) => (
              <article
                key={item.output}
                className="group grid gap-4 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)]/54 p-4 transition hover:border-[var(--color-primary)] sm:grid-cols-[118px_1fr]"
              >
                <div
                  className={`relative mx-auto grid h-32 place-items-center overflow-hidden rounded-lg border border-white/14 bg-gradient-to-br ${OUTPUT_COLORS[index]} sm:mx-0`}
                  style={{ aspectRatio: item.ratio }}
                >
                  <div className="landing-mock-sheen pointer-events-none absolute inset-0" aria-hidden />
                  <span className="grid size-10 place-items-center rounded-full bg-white/16 text-white backdrop-blur">
                    <Play size={17} className="ml-0.5" aria-hidden />
                  </span>
                </div>
                <div className="min-w-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <h3 className="text-base font-black">{item.output}</h3>
                    <span className="rounded-md bg-[var(--color-secondary-soft)] px-2 py-1 text-xs font-bold text-[var(--color-secondary-text)]">
                      {item.platform}
                    </span>
                  </div>
                  <p className="mt-2 text-sm leading-relaxed text-[var(--color-muted)]">
                    {item.outcome}
                  </p>
                  <div className="mt-3 flex flex-wrap gap-2 text-xs font-bold text-[var(--color-muted-strong)]">
                    <span className="inline-flex items-center gap-1 rounded-md border border-[var(--color-border)] px-2 py-1">
                      <Clock size={13} aria-hidden />
                      {item.duration}
                    </span>
                    <span className="inline-flex items-center gap-1 rounded-md border border-[var(--color-border)] px-2 py-1">
                      <Maximize2 size={13} aria-hidden />
                      {item.resolution}
                    </span>
                    <span className="inline-flex items-center gap-1 rounded-md border border-[var(--color-border)] px-2 py-1">
                      <Film size={13} aria-hidden />
                      MP4
                    </span>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
