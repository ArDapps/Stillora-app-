"use client";

import { ChevronDown } from "lucide-react";
import { useId, useState } from "react";
import { FAQ_ITEMS } from "@/lib/landing-content";
import { SectionHeading } from "./section-heading";

export function Faq() {
  const [open, setOpen] = useState<number | null>(0);
  const baseId = useId();

  return (
    <section id="faq" className="border-t border-[var(--color-border)] scroll-mt-20">
      <div className="mx-auto w-full max-w-3xl px-5 py-20">
        <SectionHeading title="Frequently asked questions" centered />
        <ul className="mt-12 space-y-3">
          {FAQ_ITEMS.map((item, index) => {
            const isOpen = open === index;
            const buttonId = `${baseId}-q-${index}`;
            const panelId = `${baseId}-a-${index}`;
            return (
              <li
                key={item.question}
                className="overflow-hidden rounded-xl border border-[var(--color-border)] bg-[var(--color-card)]"
              >
                <h3>
                  <button
                    id={buttonId}
                    type="button"
                    aria-expanded={isOpen}
                    aria-controls={panelId}
                    onClick={() => setOpen(isOpen ? null : index)}
                    className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left text-base font-semibold transition hover:text-[var(--color-primary)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
                  >
                    {item.question}
                    <ChevronDown
                      size={20}
                      aria-hidden
                      className={`shrink-0 text-[var(--color-muted-strong)] transition-transform duration-200 ${
                        isOpen ? "rotate-180" : ""
                      }`}
                    />
                  </button>
                </h3>
                <div
                  id={panelId}
                  role="region"
                  aria-labelledby={buttonId}
                  hidden={!isOpen}
                  className="px-5 pb-5 text-sm leading-relaxed text-[var(--color-muted)]"
                >
                  {item.answer}
                </div>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
