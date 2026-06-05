import { Check, Minus } from "lucide-react";
import { COMPARISON_ROWS } from "@/lib/landing-content";
import { LandingVisual, MiniMediaFlow } from "./landing-illustrations";
import { SectionHeading } from "./section-heading";

export function Comparison() {
  return (
    <section
      aria-label="Stillora compared to a traditional video editor"
      className="landing-section"
    >
      <div className="mx-auto w-full max-w-7xl px-5 py-20">
        <SectionHeading eyebrow="Why it feels faster" title="Create the video, not the editing project" />

        <div className="mt-10 grid gap-5 lg:grid-cols-[1fr_1.15fr] lg:items-stretch">
          <LandingVisual label="Stillora output" ratio="16 / 9" tone="blue" />
          <div className="landing-card rounded-lg p-5">
            <MiniMediaFlow />
            <p className="mt-5 text-sm leading-relaxed text-[var(--color-muted)]">
              Stillora keeps the work close to the goal: upload media, choose the right format, render,
              and download the finished MP4.
            </p>
          </div>
        </div>

        {/* Desktop / tablet: table */}
        <div className="landing-card mt-12 hidden overflow-hidden rounded-lg md:block">
          <table className="w-full border-collapse text-left">
            <caption className="sr-only">
              Capability comparison between Stillora and a traditional video editor
            </caption>
            <thead>
              <tr className="bg-[var(--color-card-high)]">
                <th scope="col" className="px-6 py-4 text-sm font-semibold">
                  Capability
                </th>
                <th scope="col" className="px-6 py-4 text-sm font-semibold text-[var(--color-primary)]">
                  Stillora
                </th>
                <th scope="col" className="px-6 py-4 text-sm font-semibold text-[var(--color-muted-strong)]">
                  Traditional video editor
                </th>
              </tr>
            </thead>
            <tbody>
              {COMPARISON_ROWS.map((row, i) => (
                <tr
                  key={row.capability}
                  className={i % 2 === 0 ? "bg-transparent" : "bg-[var(--color-card)]/40"}
                >
                  <th scope="row" className="border-t border-[var(--color-border)] px-6 py-4 text-sm font-medium">
                    {row.capability}
                  </th>
                  <td className="border-t border-[var(--color-border)] px-6 py-4 text-sm">
                    <span className="inline-flex items-center gap-2">
                      <Check size={16} className="shrink-0 text-[var(--color-primary)]" aria-hidden />
                      {row.stillora}
                    </span>
                  </td>
                  <td className="border-t border-[var(--color-border)] px-6 py-4 text-sm text-[var(--color-muted-strong)]">
                    <span className="inline-flex items-center gap-2">
                      <Minus size={16} className="shrink-0 opacity-60" aria-hidden />
                      {row.traditional}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Mobile: stacked cards */}
        <ul className="mt-10 grid gap-4 md:hidden">
          {COMPARISON_ROWS.map((row) => (
            <li
              key={row.capability}
              className="landing-card rounded-lg p-5"
            >
              <p className="text-sm font-semibold">{row.capability}</p>
              <dl className="mt-3 space-y-2 text-sm">
                <div className="flex items-start gap-2">
                  <Check size={16} className="mt-0.5 shrink-0 text-[var(--color-primary)]" aria-hidden />
                  <dt className="sr-only">Stillora</dt>
                  <dd>
                    <span className="font-medium text-[var(--color-primary)]">Stillora:</span>{" "}
                    {row.stillora}
                  </dd>
                </div>
                <div className="flex items-start gap-2">
                  <Minus size={16} className="mt-0.5 shrink-0 opacity-60" aria-hidden />
                  <dt className="sr-only">Traditional video editor</dt>
                  <dd className="text-[var(--color-muted-strong)]">
                    <span className="font-medium">Traditional editor:</span> {row.traditional}
                  </dd>
                </div>
              </dl>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
