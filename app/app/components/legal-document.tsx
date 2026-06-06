import { AppNavbar, Logo } from "@/app/components/app-navbar";
import { TECNOBLOCKS_URL } from "@/lib/site";

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
      <AppNavbar />
      <main className="mx-auto w-full max-w-4xl px-4 pb-20 pt-28 sm:px-6 sm:pt-32">
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
