import { FEATURES } from "@/lib/landing-content";
import { SectionHeading } from "./section-heading";

export function Features() {
  return (
    <section id="features" className="border-t border-[var(--color-border)] scroll-mt-20">
      <div className="mx-auto w-full max-w-7xl px-5 py-20">
        <SectionHeading
          title="Everything you need to ship a post"
          description="A focused toolkit that does the heavy lifting — so a single image becomes a finished video without leaving your browser."
        />
        <ul className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map(({ icon: Icon, title, body }) => (
            <li
              key={title}
              className="rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-6 shadow-sm transition hover:border-[var(--color-primary)]"
            >
              <div className="grid size-11 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                <Icon size={22} aria-hidden />
              </div>
              <h3 className="mt-5 text-lg font-semibold">{title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-[var(--color-muted)]">{body}</p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
