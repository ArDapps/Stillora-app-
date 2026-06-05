import { ArrowRight } from "lucide-react";
import Link from "next/link";
import { USE_CASES } from "@/lib/landing-content";
import { EDITOR_PATH } from "@/lib/site";
import { SectionHeading } from "./section-heading";

const TILE_CLASSES = [
  "lg:col-span-2 lg:row-span-2",
  "lg:row-span-2",
  "",
  "",
  "lg:col-span-2",
  "",
];

export function UseCases() {
  return (
    <section id="use-cases" className="landing-section scroll-mt-24">
      <div className="mx-auto w-full max-w-7xl px-5 py-20">
        <div className="grid gap-8 lg:grid-cols-[0.9fr_1.1fr] lg:items-end">
          <SectionHeading
            eyebrow="Creator workflows"
            title="Not another generic converter"
            description="Stillora is built around the real jobs creators do every week: shorts, covers, slideshows, artwork loops, and feed posts."
          />
          <Link
            href={EDITOR_PATH}
            className="hidden justify-self-end rounded-md border border-[var(--color-border)] bg-[var(--color-card)] px-5 py-3 text-sm font-black text-[var(--color-foreground)] transition hover:border-[var(--color-primary)] lg:inline-flex"
          >
            Start a workflow
            <ArrowRight size={16} className="ml-2" aria-hidden />
          </Link>
        </div>

        <ul className="mt-12 grid auto-rows-[minmax(190px,auto)] gap-4 md:grid-cols-2 lg:grid-cols-4">
          {USE_CASES.map(({ icon: Icon, title, description }, index) => (
            <li
              key={title}
              className={`landing-card group relative overflow-hidden rounded-lg p-5 ${TILE_CLASSES[index]}`}
            >
              <div className="absolute inset-0 opacity-0 transition group-hover:opacity-100">
                <div className="landing-mock-sheen absolute inset-0" aria-hidden />
              </div>
              <div className="relative flex h-full flex-col">
                <div className="grid size-12 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                  <Icon size={23} aria-hidden />
                </div>
                <div className="mt-auto pt-10">
                  <h3 className="text-xl font-black leading-tight">{title}</h3>
                  <p className="mt-3 text-sm leading-relaxed text-[var(--color-muted)]">
                    {description}
                  </p>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
