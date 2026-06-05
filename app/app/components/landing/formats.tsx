import { LayoutGrid, Maximize2, MonitorPlay, PlaySquare, Smartphone, Square } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { SectionHeading } from "./section-heading";

type FormatCard = {
  id: string;
  icon: LucideIcon;
  name: string;
  details: string;
  orientation: string;
  ratio: string;
  sizeClass: string;
};

const FORMAT_CARDS: FormatCard[] = [
  {
    id: "reels-stories",
    icon: Smartphone,
    name: "Reels, TikTok, Stories",
    details: "Vertical social posts",
    orientation: "9:16",
    ratio: "9 / 16",
    sizeClass: "h-56",
  },
  {
    id: "youtube-shorts",
    icon: PlaySquare,
    name: "YouTube Shorts",
    details: "Short-form vertical MP4",
    orientation: "9:16",
    ratio: "9 / 16",
    sizeClass: "h-48",
  },
  {
    id: "youtube-long",
    icon: MonitorPlay,
    name: "YouTube Long",
    details: "Landscape HD video",
    orientation: "16:9",
    ratio: "16 / 9",
    sizeClass: "h-32",
  },
  {
    id: "square",
    icon: Square,
    name: "Square Feed",
    details: "Balanced social posts",
    orientation: "1:1",
    ratio: "1 / 1",
    sizeClass: "h-36",
  },
  {
    id: "portrait",
    icon: LayoutGrid,
    name: "Portrait Feed",
    details: "Tall carousel posts",
    orientation: "4:5",
    ratio: "4 / 5",
    sizeClass: "h-44",
  },
  {
    id: "original",
    icon: Maximize2,
    name: "Original Size",
    details: "Keep uploaded dimensions",
    orientation: "Any",
    ratio: "4 / 5",
    sizeClass: "h-40",
  },
];

export function Formats() {
  return (
    <section id="formats" className="landing-section scroll-mt-24">
      <div className="mx-auto grid w-full max-w-7xl gap-10 px-5 py-20 lg:grid-cols-[0.78fr_1.22fr] lg:items-center">
        <div>
          <SectionHeading
            eyebrow="Format studio"
            title="Six exports without six projects"
            description="Choose the shape that matches the platform, or preserve your source dimensions when the original frame matters."
          />
          <div className="mt-8 grid gap-3 sm:grid-cols-3 lg:grid-cols-1">
            {["Upload once", "Pick shape", "Download MP4"].map((step, index) => (
              <div
                key={step}
                className="flex items-center gap-3 rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-3"
              >
                <span className="grid size-8 place-items-center rounded-md bg-[var(--color-primary-soft)] text-sm font-black text-[var(--color-primary)]">
                  {index + 1}
                </span>
                <span className="text-sm font-bold">{step}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="landing-card overflow-hidden rounded-lg p-4 sm:p-6">
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {FORMAT_CARDS.map(({ icon: Icon, ...format }, index) => (
              <article
                key={format.id}
                className={`group rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)]/52 p-4 ${
                  index === 0 ? "sm:row-span-2" : ""
                }`}
              >
                <div className="flex items-center justify-between gap-3">
                  <div className="grid size-10 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                    <Icon size={20} aria-hidden />
                  </div>
                  <span className="rounded-md bg-[var(--color-secondary-soft)] px-2 py-1 text-xs font-black text-[var(--color-secondary-text)]">
                    {format.orientation}
                  </span>
                </div>
                <div className="mt-4 flex min-h-44 items-center justify-center">
                  <div
                    className={`${format.sizeClass} relative max-w-full overflow-hidden rounded-lg border border-white/18 bg-[var(--color-surface-dim)] transition group-hover:scale-[1.04]`}
                    style={{ aspectRatio: format.ratio, background: "var(--landing-mock-bg)" }}
                  >
                    <div className="landing-mock-sheen pointer-events-none absolute inset-0" aria-hidden />
                    <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_24%,rgba(244,114,182,.4),transparent_25%),linear-gradient(150deg,rgba(34,211,238,.25),transparent_42%)]" />
                  </div>
                </div>
                <h3 className="mt-4 text-base font-black">{format.name}</h3>
                <p className="mt-1 text-sm font-semibold text-[var(--color-muted)]">
                  {format.details}
                </p>
              </article>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
