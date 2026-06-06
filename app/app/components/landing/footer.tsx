import { Logo } from "@/app/components/app-navbar";
import { TECNOBLOCKS_URL } from "@/lib/site";

export function Footer() {
  return (
    <footer className="relative overflow-hidden border-t border-border/40 pb-8 pt-12 sm:pt-16">
      <div className="relative z-10 mx-auto w-full max-w-7xl px-4 sm:px-6">
        <div className="mb-10 grid grid-cols-2 gap-8 sm:mb-12 sm:grid-cols-4 sm:gap-12">
          <div className="col-span-2">
            <Logo />
            <p className="mt-4 max-w-xs text-sm leading-relaxed text-muted-foreground">
              Mix images, video clips, and audio tracks into one platform-ready MP4. Free on web, mobile, and desktop soon.
            </p>
          </div>
          <div>
            <h4 className="mb-4 text-sm font-semibold text-foreground">Product</h4>
            <ul className="space-y-2.5">
              {[
                { label: "Features", href: "/#features" },
                { label: "Formats", href: "/#formats" },
                { label: "How it works", href: "/#how-it-works" },
              ].map((link) => (
                <li key={link.href}>
                  <a href={link.href} className="text-sm text-muted-foreground transition-colors hover:text-foreground">
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h4 className="mb-4 text-sm font-semibold text-foreground">Legal</h4>
            <ul className="space-y-2.5">
              {[
                { label: "Privacy Policy", href: "/privacy" },
                { label: "Terms of Service", href: "/terms" },
                { label: "Contact", href: "mailto:support@tecnoblocks.com" },
              ].map((link) => (
                <li key={link.href}>
                  <a href={link.href} className="text-sm text-muted-foreground transition-colors hover:text-foreground">
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>
        <div className="flex flex-col items-center justify-between gap-3 border-t border-border/30 pt-6 sm:flex-row">
          <p className="text-xs text-muted-foreground/70">© {new Date().getFullYear()} Stillora. Free to use. All rights reserved.</p>
          <p className="text-xs text-muted-foreground/70">
            Built by{" "}
            <a href={TECNOBLOCKS_URL} target="_blank" rel="noopener noreferrer" className="font-medium text-primary hover:underline">
              Tecno Blocks
            </a>
          </p>
        </div>
      </div>
    </footer>
  );
}
