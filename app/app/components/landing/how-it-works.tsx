import { HOW_STEPS } from "@/lib/landing-content";
import { SectionHeading } from "./section-heading";

export function HowItWorks() {
  return (
    <section id="how-it-works" className="border-t border-[var(--color-border)] scroll-mt-20">
      <div className="mx-auto w-full max-w-7xl px-5 py-20">
        <SectionHeading
          title="Three steps to done"
          description="No complicated timeline to learn. Upload, choose your settings, and export."
        />
        <ol className="mt-12 grid gap-6 md:grid-cols-3">
          {HOW_STEPS.map(({ icon: Icon, title, body }, index) => (
            <li
              key={title}
              className="relative rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-6 shadow-sm"
            >
              <div className="flex items-center justify-between">
                <span className="text-sm font-semibold text-[var(--color-muted-strong)]">
                  Step {index + 1}
                </span>
                <span
                  aria-hidden
                  className="bg-[image:var(--brand-gradient)] bg-clip-text text-4xl font-bold leading-none text-transparent opacity-40"
                >
                  {index + 1}
                </span>
              </div>
              <div className="mt-4 grid size-11 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                <Icon size={22} aria-hidden />
              </div>
              <h3 className="mt-5 text-lg font-semibold">{title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-[var(--color-muted)]">{body}</p>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
