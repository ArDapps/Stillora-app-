import { ArrowRight } from "lucide-react";
import Link from "next/link";
import { USE_CASES } from "@/lib/landing-content";
import { EDITOR_PATH } from "@/lib/site";
import { SectionHeading } from "./section-heading";

export function UseCases() {
  return (
    <section id="use-cases" className="border-t border-[var(--color-border)] scroll-mt-20">
      <div className="mx-auto w-full max-w-7xl px-5 py-20">
        <SectionHeading
          title="Made for the content you already create"
          description="One upload, every aspect ratio — built for the posts, clips, and stories you publish every week."
        />
        <ul className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {USE_CASES.map(({ icon: Icon, title, description }) => (
            <li
              key={title}
              className="group flex flex-col rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-6 shadow-sm transition hover:border-[var(--color-primary)]"
            >
              <div className="grid size-11 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                <Icon size={22} aria-hidden />
              </div>
              <h3 className="mt-5 text-lg font-semibold">{title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-[var(--color-muted)]">{description}</p>
              <Link
                href={EDITOR_PATH}
                className="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-[var(--color-primary)] transition group-hover:gap-2.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
              >
                Try it
                <ArrowRight size={15} aria-hidden />
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
