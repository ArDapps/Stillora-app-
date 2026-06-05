import { HOW_STEPS } from "@/lib/landing-content";
import { MiniMediaFlow } from "./landing-illustrations";
import { SectionHeading } from "./section-heading";

export function HowItWorks() {
  return (
    <section id="how-it-works" className="landing-section scroll-mt-24">
      <div className="mx-auto w-full max-w-7xl px-5 py-20">
        <div className="grid gap-10 lg:grid-cols-[0.78fr_1.22fr] lg:items-start">
          <SectionHeading
            eyebrow="Fast flow"
            title="The whole job in three moves"
            description="No timeline to manage and no duplicate projects for every social platform."
          />

          <div className="landing-card rounded-lg p-5 sm:p-6">
            <MiniMediaFlow />
            <ol className="mt-8 divide-y divide-[var(--color-border)]">
              {HOW_STEPS.map(({ icon: Icon, title, body }, index) => (
                <li key={title} className="grid gap-4 py-6 first:pt-0 last:pb-0 sm:grid-cols-[84px_1fr]">
                  <div className="flex items-center gap-3 sm:block">
                    <span className="block bg-[image:var(--brand-gradient)] bg-clip-text text-5xl font-black leading-none text-transparent">
                      {index + 1}
                    </span>
                    <div className="mt-0 grid size-11 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)] sm:mt-3">
                      <Icon size={22} aria-hidden />
                    </div>
                  </div>
                  <div>
                    <h3 className="text-xl font-black">{title}</h3>
                    <p className="mt-2 text-sm leading-relaxed text-[var(--color-muted)]">{body}</p>
                  </div>
                </li>
              ))}
            </ol>
          </div>
        </div>
      </div>
    </section>
  );
}
