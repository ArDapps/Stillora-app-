import { SocialBadge } from "./shared";
import { platforms } from "./data";

export function PlatformPresets() {
  return (
    <section className="relative overflow-hidden border-y border-border/40 py-10 sm:py-14">
      <div className="pointer-events-none absolute inset-0 bg-gradient-to-r from-primary/5 via-transparent to-accent/5" />
      <div className="relative z-10 mx-auto w-full max-w-7xl px-4 sm:px-6">
        <p className="mb-8 text-center text-xs font-semibold uppercase tracking-widest text-muted-foreground sm:text-sm">
          Perfect presets for every platform
        </p>
        <div className="mx-auto grid max-w-4xl grid-cols-2 gap-3 sm:gap-4 md:grid-cols-4">
          {platforms.map((platform) => (
            <div key={platform.name} className="group flex cursor-default flex-col items-center gap-3 rounded-lg border border-border/60 bg-card/60 p-4 text-center transition hover:-translate-y-1 hover:border-primary/40 hover:bg-card sm:p-5">
              <SocialBadge {...platform} label={platform.name} />
              <div>
                <p className="text-sm font-semibold leading-tight text-foreground">{platform.name}</p>
                <p className="mt-0.5 text-xs text-muted-foreground">{platform.sub}</p>
                <p className="mt-1 font-mono text-[10px] text-primary/70">{platform.dims}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
