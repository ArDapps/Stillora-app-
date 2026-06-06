import { SectionHeading } from "./shared";
import { steps } from "./data";

export function HowItWorks() {
  return (
    <section id="how-it-works" className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <SectionHeading
          eyebrow="Simple workflow"
          title="Three steps to a"
          highlight="ready-to-post video"
          body="No timelines, no keyframes. Just your media and the video you need."
        />
        <div className="grid grid-cols-1 gap-6 sm:gap-8 md:grid-cols-3">
          {steps.map((step) => (
            <div key={step.number} className="relative rounded-lg border border-border/60 bg-card/60 p-6 text-center transition hover:-translate-y-2 hover:bg-card sm:p-8 sm:text-left">
              <div className="pointer-events-none absolute right-5 top-4 select-none text-5xl font-black text-foreground/[0.04]">{step.number}</div>
              <div className={`mx-auto mb-5 grid size-14 place-items-center rounded-lg border shadow-xl sm:mx-0 ${step.bg}`}>
                <step.icon className={`size-7 ${step.color}`} />
              </div>
              <div className={`mb-3 inline-flex rounded-full border px-2 py-0.5 font-mono text-[10px] font-bold ${step.bg} ${step.color}`}>
                Step {step.number}
              </div>
              <h3 className="mb-3 text-xl font-bold text-foreground">{step.title}</h3>
              <p className="mb-4 text-sm leading-relaxed text-muted-foreground">{step.description}</p>
              <div className={`inline-flex rounded-full border border-border/60 bg-card px-3 py-1 font-mono text-[11px] ${step.color}`}>
                {step.detail}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
