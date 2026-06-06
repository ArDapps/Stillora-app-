import { SectionHeading } from "./shared";
import { features } from "./data";

export function Features() {
  return (
    <section id="features" className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <SectionHeading
          eyebrow="Everything included - free"
          title="No fluff."
          highlight="Just the essentials."
          body="All features are free. No plans, no paywalls - just the tools creators need to ship great content."
        />
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:grid-cols-4">
          {features.map((feature) => (
            <div key={feature.title} className="rounded-lg border border-border/60 bg-card/60 p-5 transition hover:-translate-y-1.5 hover:border-primary/30 hover:bg-card sm:p-6">
              <div className="mb-4 flex items-start justify-between gap-3">
                <div className={`grid size-11 flex-shrink-0 place-items-center rounded-md border ${feature.bg}`}>
                  <feature.icon className={`size-5 ${feature.color}`} />
                </div>
                <span className={`rounded-full border border-border/60 bg-card px-2 py-0.5 text-[10px] font-semibold ${feature.color}`}>
                  {feature.tag}
                </span>
              </div>
              <h3 className="mb-2 text-base font-bold text-foreground">{feature.title}</h3>
              <p className="text-sm leading-relaxed text-muted-foreground">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
