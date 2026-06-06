import Image from "next/image";
import showcaseApp from "@/public/marketing/stillora-showcase-app.png";
import { SectionHeading } from "./shared";
import { formats } from "./data";

export function Formats() {
  return (
    <section id="formats" className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <SectionHeading
          eyebrow="Platform presets"
          title="Built for"
          highlight="every feed"
          body="Stop guessing dimensions. Every major platform preset is built in."
        />
        <div className="mx-auto grid max-w-5xl grid-cols-1 items-center gap-8 lg:grid-cols-2 lg:gap-12">
          <div className="flex flex-col gap-2.5">
            {formats.map((format) => (
              <div key={format.label} className="flex items-center gap-4 rounded-lg border border-border/50 bg-card/40 p-4">
                <div className={`grid size-10 flex-shrink-0 place-items-center rounded-md border ${format.bg}`}>
                  <format.icon className={`size-5 ${format.color}`} />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold leading-tight text-foreground">{format.label}</p>
                  <p className="mt-0.5 font-mono text-xs text-muted-foreground">
                    {format.dims} - {format.ratio}
                  </p>
                </div>
              </div>
            ))}
          </div>
          <div className="relative overflow-hidden rounded-lg border border-border/60 bg-card/60 p-2 shadow-2xl shadow-primary/10">
            <Image
              src={showcaseApp}
              alt="Stillora upload and format selection interface"
              placeholder="blur"
              className="h-auto w-full rounded-md"
            />
          </div>
        </div>
      </div>
    </section>
  );
}
