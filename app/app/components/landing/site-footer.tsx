import { Sparkles } from "lucide-react";
import Link from "next/link";
import {
  FOOTER_PRODUCT_LINKS,
  FOOTER_USE_CASE_LINKS,
  type FooterLink,
} from "@/lib/landing-content";
import { LOOPARA_URL, TECNOBLOCKS_URL } from "@/lib/site";

function FooterLinkItem({ href, label, external }: FooterLink) {
  const className =
    "text-sm text-[var(--color-muted)] transition hover:text-[var(--color-foreground)]";
  if (external || href.startsWith("http")) {
    return (
      <a href={href} className={className} rel="noreferrer" target="_blank">
        {label}
      </a>
    );
  }
  return (
    <Link href={href} className={className}>
      {label}
    </Link>
  );
}

const companyLinks: FooterLink[] = [
  { href: TECNOBLOCKS_URL, label: "Built by Tecno Blocks", external: true },
  { href: LOOPARA_URL, label: "Explore more tools on Loopara", external: true },
  // TODO: point these at dedicated /privacy and /terms pages once they exist.
  { href: "#faq", label: "Privacy" },
  { href: "#faq", label: "Terms" },
];

export function SiteFooter() {
  return (
    <footer className="border-t border-[var(--color-border)] bg-[var(--color-surface)]">
      <div className="mx-auto w-full max-w-7xl px-5 py-14">
        <div className="grid gap-10 lg:grid-cols-[1.4fr_1fr_1fr_1fr]">
          {/* Brand */}
          <div>
            <Link href="/" className="flex items-center gap-3">
              <div className="grid size-9 place-items-center rounded-lg bg-[image:var(--brand-mark)] text-white shadow-[0_0_24px_var(--brand-mark-glow)]">
                <Sparkles size={18} strokeWidth={2.4} aria-hidden />
              </div>
              <span className="text-lg font-semibold text-[var(--color-foreground)]">Stillora</span>
            </Link>
            <p className="mt-4 max-w-xs text-sm leading-relaxed text-[var(--color-muted)]">
              Image-to-video tools for everyday content creation.
            </p>
          </div>

          {/* Product */}
          <nav aria-label="Product">
            <h2 className="text-sm font-semibold text-[var(--color-foreground)]">Product</h2>
            <ul className="mt-4 space-y-3">
              {FOOTER_PRODUCT_LINKS.map((link) => (
                <li key={link.label}>
                  <FooterLinkItem {...link} />
                </li>
              ))}
            </ul>
          </nav>

          {/* Use Cases */}
          <nav aria-label="Use cases">
            <h2 className="text-sm font-semibold text-[var(--color-foreground)]">Use Cases</h2>
            <ul className="mt-4 space-y-3">
              {FOOTER_USE_CASE_LINKS.map((link) => (
                <li key={link.label}>
                  <FooterLinkItem {...link} />
                </li>
              ))}
            </ul>
          </nav>

          {/* Company */}
          <nav aria-label="Company">
            <h2 className="text-sm font-semibold text-[var(--color-foreground)]">Company</h2>
            <ul className="mt-4 space-y-3">
              {companyLinks.map((link) => (
                <li key={link.label}>
                  <FooterLinkItem {...link} />
                </li>
              ))}
            </ul>
          </nav>
        </div>

        <div className="mt-12 flex flex-col items-center justify-between gap-3 border-t border-[var(--color-border)] pt-6 sm:flex-row">
          <p className="text-sm text-[var(--color-muted-strong)]">
            © 2026 Stillora. All rights reserved.
          </p>
          <p className="text-sm text-[var(--color-muted-strong)]">
            Built by{" "}
            <a
              className="font-medium text-[var(--color-foreground)] underline-offset-4 hover:underline"
              href={TECNOBLOCKS_URL}
              rel="noreferrer"
              target="_blank"
            >
              Tecno Blocks
            </a>
          </p>
        </div>
      </div>
    </footer>
  );
}
