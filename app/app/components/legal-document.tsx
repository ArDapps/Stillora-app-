import Link from "next/link";

import { TECNOBLOCKS_URL } from "@/lib/site";

/**
 * Brand lockup, also the way back to the landing page. Deliberately standalone:
 * the landing page is one self-contained design component, and the legal pages
 * should not have to mount all of it just to show a header.
 */
function Logo() {
  return (
    <Link href="/" className="flex items-center gap-2.5">
      <span
        aria-hidden
        className="size-7 rounded-lg"
        style={{ background: "var(--brand-mark)" }}
      />
      <span className="text-sm font-extrabold" style={{ color: "var(--color-foreground)" }}>
        Stillora
      </span>
    </Link>
  );
}

type LegalSection = {
  title: string;
  body: string[];
};

export function LegalDocument({
  title,
  intro,
  sections,
}: {
  title: string;
  intro: string;
  sections: LegalSection[];
}) {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <header
        className="border-b"
        style={{ borderColor: "var(--color-border)", background: "var(--color-header)" }}
      >
        <div className="mx-auto flex w-full max-w-4xl items-center px-4 py-4 sm:px-6">
          <Logo />
        </div>
      </header>
      <main className="mx-auto w-full max-w-4xl px-4 pb-20 pt-12 sm:px-6 sm:pt-16">
        <div className="mb-10">
          <p className="mb-4 text-sm font-semibold text-primary">Stillora apps</p>
          <h1 className="mb-4 text-4xl font-extrabold tracking-tight sm:text-5xl">{title}</h1>
          <p className="max-w-2xl text-base leading-relaxed text-muted-foreground sm:text-lg">{intro}</p>
          <p className="mt-4 text-sm text-muted-foreground">Last updated: June 6, 2026</p>
        </div>

        <div className="space-y-6">
          {sections.map((section) => (
            <section key={section.title} className="rounded-lg border border-border/60 bg-card/60 p-5 sm:p-6">
              <h2 className="mb-3 text-xl font-bold text-foreground">{section.title}</h2>
              <div className="space-y-3">
                {section.body.map((paragraph) => (
                  <p key={paragraph} className="text-sm leading-7 text-muted-foreground sm:text-base">
                    {paragraph}
                  </p>
                ))}
              </div>
            </section>
          ))}
        </div>
      </main>

      <footer className="border-t border-border/40 px-4 py-8 sm:px-6">
        <div className="mx-auto flex w-full max-w-4xl flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <Logo />
          <p className="text-sm text-muted-foreground">
            Built by{" "}
            <a href={TECNOBLOCKS_URL} target="_blank" rel="noopener noreferrer" className="font-medium text-primary hover:underline">
              Tecno Blocks
            </a>
          </p>
        </div>
      </footer>
    </div>
  );
}
