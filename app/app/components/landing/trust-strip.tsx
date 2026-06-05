import { TRUST_METRICS } from "@/lib/landing-content";

export function TrustStrip() {
  return (
    <section
      aria-label="Stillora at a glance"
      className="border-y border-[var(--color-border)] bg-[var(--color-surface)]"
    >
      <ul className="mx-auto flex w-full max-w-7xl flex-wrap items-center justify-center gap-x-8 gap-y-4 px-5 py-6 sm:justify-between">
        {TRUST_METRICS.map(({ icon: Icon, label }) => (
          <li key={label} className="flex items-center gap-2.5 text-sm font-medium">
            <Icon size={18} className="shrink-0 text-[var(--color-primary)]" aria-hidden />
            <span className="text-[var(--color-foreground)]">{label}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}
