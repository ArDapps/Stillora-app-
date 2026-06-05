import { ArrowRight, ImageIcon, Play } from "lucide-react";
import { SHOWCASES } from "@/lib/landing-content";
import { SectionHeading } from "./section-heading";

export function Showcase() {
  return (
    <section
      aria-label="Before and after showcase"
      className="border-t border-[var(--color-border)]"
    >
      <div className="mx-auto w-full max-w-7xl px-5 py-20">
        <SectionHeading
          title="From static image to ready-to-post video"
          description="See how a simple upload becomes content you can publish across social platforms."
        />
        <div className="mt-12 grid gap-6 md:grid-cols-3">
          {SHOWCASES.map((item) => (
            <article
              key={item.output}
              className="group flex flex-col gap-4 rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-5 shadow-sm transition hover:border-[var(--color-primary)]"
            >
              <div className="flex items-center gap-3">
                {/* Input preview (CSS mockup) */}
                <div className="grid size-12 shrink-0 place-items-center rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] text-[var(--color-muted-strong)]">
                  <ImageIcon size={20} aria-hidden />
                </div>
                <ArrowRight size={18} className="shrink-0 text-[var(--color-primary)]" aria-hidden />
                {/* Output-style video frame */}
                <div
                  className="relative grid flex-1 place-items-center overflow-hidden rounded-lg"
                  style={{ background: "var(--landing-mock-bg)", aspectRatio: item.ratio }}
                >
                  <div className="grid size-9 place-items-center rounded-full bg-white/15 text-white backdrop-blur">
                    <Play size={16} className="ml-0.5" aria-hidden />
                  </div>
                  <span className="absolute left-1.5 top-1.5 rounded bg-black/40 px-1.5 py-0.5 text-[10px] font-medium text-white backdrop-blur">
                    {item.platform}
                  </span>
                </div>
              </div>

              <p className="text-sm leading-relaxed text-[var(--color-muted)]">{item.outcome}</p>

              <div className="mt-auto flex flex-wrap items-center gap-2 text-xs text-[var(--color-muted-strong)]">
                <span className="rounded-md bg-[var(--color-secondary-soft)] px-2 py-1 font-semibold text-[var(--color-secondary-text)]">
                  {item.platform}
                </span>
                <span className="rounded-md border border-[var(--color-border)] px-2 py-1">
                  {item.duration}
                </span>
                <span className="rounded-md border border-[var(--color-border)] px-2 py-1">
                  {item.resolution}
                </span>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
