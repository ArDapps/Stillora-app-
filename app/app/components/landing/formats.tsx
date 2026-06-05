import { OUTPUT_PRESETS } from "@/lib/stillora";
import { SectionHeading } from "./section-heading";

// Visual aspect ratio for each preset frame. `original` has no fixed ratio, so
// we show a representative portrait-ish frame with a dashed "any size" border.
const RATIO_STYLE: Record<string, string> = {
  reels: "9 / 16",
  "youtube-shorts": "9 / 16",
  "youtube-long": "16 / 9",
  square: "1 / 1",
  original: "4 / 5",
};

export function Formats() {
  return (
    <section
      id="formats"
      className="border-t border-[var(--color-border)] bg-[var(--color-surface)] scroll-mt-20"
    >
      <div className="mx-auto w-full max-w-7xl px-5 py-20">
        <SectionHeading
          title="One upload, every aspect ratio"
          description="Choose the format that fits your platform, or preserve your original uploaded dimensions."
        />
        <ul className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {OUTPUT_PRESETS.map((preset) => {
            const isOriginal = preset.id === "original";
            return (
              <li
                key={preset.id}
                className="group flex flex-col items-center gap-5 rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-6 text-center shadow-sm transition hover:border-[var(--color-primary)]"
              >
                {/* Frame with a visibly different aspect ratio */}
                <div className="grid h-44 w-full place-items-center">
                  <div
                    className={`relative w-auto max-w-full overflow-hidden rounded-lg border transition-transform duration-300 group-hover:scale-[1.04] ${
                      isOriginal
                        ? "border-dashed border-[var(--color-border-strong)]"
                        : "border-[var(--color-border)]"
                    }`}
                    style={{
                      height: "100%",
                      aspectRatio: RATIO_STYLE[preset.id],
                      background: "var(--landing-mock-bg)",
                    }}
                  >
                    <div className="landing-mock-sheen pointer-events-none absolute inset-0" aria-hidden />
                    <span className="absolute inset-x-0 bottom-0 bg-black/35 px-2 py-1 text-[11px] font-semibold text-white backdrop-blur">
                      {preset.orientation}
                    </span>
                  </div>
                </div>
                <div>
                  <p className="font-semibold">{preset.name}</p>
                  <p className="mt-1 text-sm text-[var(--color-muted-strong)]">{preset.details}</p>
                </div>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
