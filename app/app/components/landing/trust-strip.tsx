import { TRUST_METRICS } from "@/lib/landing-content";

export function TrustStrip() {
  return (
    <section
      aria-label="Stillora at a glance"
      className="landing-section px-5"
    >
      <ul className="landing-glass mx-auto grid w-full max-w-7xl gap-3 rounded-lg p-3 sm:grid-cols-2 lg:grid-cols-5">
        {TRUST_METRICS.map(({ icon: Icon, label }) => (
          <li
            key={label}
            className="flex items-center gap-2.5 rounded-lg px-4 py-3 text-sm font-bold"
          >
            <span className="grid size-9 shrink-0 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
              <Icon size={18} aria-hidden />
            </span>
            <span className="text-[var(--color-foreground)]">{label}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}
