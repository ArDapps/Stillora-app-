import { ArrowRight, Sparkles } from "lucide-react";
import Link from "next/link";
import { AuthControls } from "@/app/components/auth-controls";
import { MobileNav } from "@/app/components/mobile-nav";
import { ThemeToggle } from "@/app/components/theme-toggle";
import { NAV_LINKS } from "@/lib/landing-content";
import { EDITOR_PATH } from "@/lib/site";

/**
 * Single site header used by both the landing page and the editor.
 * Pass `showNav`/`showCta` to surface the marketing links and CTA (landing),
 * or leave them off for the minimal app bar (editor).
 */
export function SiteHeader({
  showNav = false,
  showCta = false,
}: {
  showNav?: boolean;
  showCta?: boolean;
}) {
  return (
    <header className="sticky top-0 z-30 border-b border-[var(--color-border)] bg-[var(--color-header)] backdrop-blur supports-[backdrop-filter]:bg-[var(--color-header)]">
      <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-4 px-5 py-4">
        <Link href="/" className="flex items-center gap-3">
          <div className="grid size-10 place-items-center rounded-lg bg-[image:var(--brand-mark)] text-white shadow-[0_0_24px_var(--brand-mark-glow)]">
            <Sparkles size={20} strokeWidth={2.4} aria-hidden />
          </div>
          <div>
            <p className="text-lg font-semibold leading-tight text-[var(--color-foreground)]">
              Stillora
            </p>
            <p className="text-sm text-[var(--color-muted-strong)]">Built by Tecno Blocks</p>
          </div>
        </Link>

        {showNav ? (
          <nav
            aria-label="Primary"
            className="hidden items-center gap-7 text-sm font-medium text-[var(--color-muted)] md:flex"
          >
            {NAV_LINKS.map((link) => (
              <a
                className="transition hover:text-[var(--color-foreground)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
                href={link.href}
                key={link.href}
              >
                {link.label}
              </a>
            ))}
          </nav>
        ) : null}

        <div className="flex items-center gap-2 sm:gap-3">
          <ThemeToggle />
          <AuthControls callbackUrl={EDITOR_PATH} />
          {showCta ? (
            <Link
              href={EDITOR_PATH}
              className="hidden items-center gap-2 rounded-md bg-[var(--color-primary)] px-4 py-2 text-sm font-semibold text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] sm:inline-flex"
            >
              Open Editor
              <ArrowRight size={16} aria-hidden />
            </Link>
          ) : null}
          {showNav ? <MobileNav links={NAV_LINKS} /> : null}
        </div>
      </div>
    </header>
  );
}
