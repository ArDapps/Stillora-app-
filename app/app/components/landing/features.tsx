import { FEATURES } from "@/lib/landing-content";
import { LandingVisual } from "./landing-illustrations";
import { SectionHeading } from "./section-heading";

export function Features() {
  return (
    <section id="features" className="landing-section scroll-mt-24">
      <div className="mx-auto grid w-full max-w-7xl gap-10 px-5 py-20 lg:grid-cols-[1fr_1fr] lg:items-start">
        <div className="lg:sticky lg:top-28">
          <SectionHeading
            eyebrow="Toolkit"
            title="A focused control room, not a timeline maze"
            description="The editor keeps the important controls close: source media, audio, format, framing, duration, and export."
          />
          <div className="landing-card mt-10 overflow-hidden rounded-lg p-5">
            <LandingVisual label="Preview" ratio="9 / 16" tone="cyan" />
            <div className="mt-4 grid grid-cols-3 gap-2 text-center text-xs font-black text-[var(--color-muted-strong)]">
              <span className="rounded-md bg-[var(--color-primary-soft)] px-2 py-2 text-[var(--color-primary)]">
                Fit
              </span>
              <span className="rounded-md border border-[var(--color-border)] px-2 py-2">Fill</span>
              <span className="rounded-md border border-[var(--color-border)] px-2 py-2">MP4</span>
            </div>
          </div>
        </div>

        <div className="space-y-3">
          {FEATURES.map(({ icon: Icon, title, body }, index) => (
            <article
              key={title}
              className="group flex gap-4 rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-4 transition hover:border-[var(--color-primary)]"
            >
              <div className="landing-float-icon grid size-12 shrink-0 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                <Icon size={23} aria-hidden />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-black text-[var(--color-muted-strong)]">
                    0{index + 1}
                  </span>
                  <h3 className="text-lg font-black">{title}</h3>
                </div>
                <p className="mt-2 text-sm leading-relaxed text-[var(--color-muted)]">{body}</p>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
