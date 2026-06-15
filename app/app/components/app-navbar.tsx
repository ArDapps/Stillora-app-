"use client";

import { Menu, X } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { EDITOR_PATH } from "@/lib/site";
import stilloraIcon from "@/public/logo/stillora-icon.svg";
import { AuthControls } from "./auth-controls";
import { ThemeToggle } from "./theme-toggle";

export type NavLink = {
  href: string;
  label: string;
};

export const MARKETING_NAV_LINKS: NavLink[] = [
  { href: "/#features", label: "Features" },
  { href: "/#formats", label: "Formats" },
  { href: "/#how", label: "How it works" },
  { href: "/#platforms", label: "Apps" },
  { href: "/#faq", label: "FAQ" },
];

export function Logo() {
  return (
    <div className="flex items-center gap-2">
      <Image
        src={stilloraIcon}
        alt="Stillora"
        priority
        width={56}
        height={34}
        className="flex-shrink-0"
      />
      <span className="font-display text-xl font-bold tracking-tight text-foreground">Stillora</span>
    </div>
  );
}

export function PrimaryCta({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <Link
      href={EDITOR_PATH}
      className={`inline-flex items-center justify-center rounded-full bg-primary px-7 py-3.5 text-sm font-bold text-primary-foreground shadow-xl shadow-primary/30 transition-all duration-300 hover:-translate-y-1 hover:scale-[1.03] hover:bg-primary/90 hover:shadow-primary/50 focus:outline-none focus:ring-2 focus:ring-primary ${className}`}
    >
      {children}
    </Link>
  );
}

export function AppNavbar() {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 transition-all duration-300 ${
        scrolled
          ? "border-b border-border/60 bg-background/90 shadow-lg shadow-black/10 backdrop-blur-xl"
          : "bg-transparent"
      }`}
    >
      <div className="mx-auto flex h-16 w-full max-w-7xl items-center justify-between px-4 sm:h-20 sm:px-6">
        <Link href="/" className="transition-opacity hover:opacity-80">
          <Logo />
        </Link>

        <nav className="hidden items-center gap-1 md:flex" aria-label="Primary">
          {MARKETING_NAV_LINKS.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="rounded-md px-4 py-2 text-sm font-semibold text-muted-foreground transition-all hover:bg-foreground/5 hover:text-foreground"
            >
              {link.label}
            </Link>
          ))}
        </nav>

        <div className="hidden items-center gap-2 md:flex">
          <Link
            href="/batch"
            className="rounded-md px-3 py-2 text-sm font-semibold text-muted-foreground transition-all hover:bg-foreground/5 hover:text-foreground"
          >
            Batch
          </Link>
          <Link
            href="/html-to-video"
            className="rounded-md px-3 py-2 text-sm font-semibold text-muted-foreground transition-all hover:bg-foreground/5 hover:text-foreground"
          >
            HTML → Video
          </Link>
          <span className="rounded-full border border-green-500/25 bg-green-500/15 px-2.5 py-1 text-xs font-bold text-green-400">
            100% Free
          </span>
          <ThemeToggle />
          <AuthControls callbackUrl={EDITOR_PATH} />
          <PrimaryCta className="px-5 py-2.5">Get Started Free</PrimaryCta>
        </div>

        <div className="flex items-center gap-2 md:hidden">
          <ThemeToggle />
          <button
            type="button"
            aria-label="Toggle menu"
            aria-expanded={menuOpen}
            onClick={() => setMenuOpen((open) => !open)}
            className="grid size-10 place-items-center rounded-md border border-border text-muted-foreground transition hover:border-primary hover:text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
          >
            {menuOpen ? <X className="size-5" /> : <Menu className="size-5" />}
          </button>
        </div>
      </div>

      {menuOpen ? (
        <div className="border-b border-border/60 bg-background/95 px-4 pb-4 backdrop-blur-xl md:hidden">
          <nav className="mb-4 flex flex-col gap-1" aria-label="Mobile primary">
            {MARKETING_NAV_LINKS.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => setMenuOpen(false)}
                className="rounded-md px-4 py-3 text-sm font-semibold text-muted-foreground transition hover:bg-foreground/5 hover:text-foreground"
              >
                {link.label}
              </Link>
            ))}
          </nav>
          <div className="flex flex-col gap-3">
            <Link
              href="/batch"
              onClick={() => setMenuOpen(false)}
              className="rounded-md px-4 py-3 text-sm font-semibold text-muted-foreground transition hover:bg-foreground/5 hover:text-foreground"
            >
              Batch · Loop images
            </Link>
            <Link
              href="/html-to-video"
              onClick={() => setMenuOpen(false)}
              className="rounded-md px-4 py-3 text-sm font-semibold text-muted-foreground transition hover:bg-foreground/5 hover:text-foreground"
            >
              HTML → Video
            </Link>
            <div className="text-center text-xs font-bold text-green-400">
              100% Free - Web - Mobile - Desktop soon
            </div>
            <AuthControls callbackUrl={EDITOR_PATH} />
            <PrimaryCta className="w-full">Get Started Free</PrimaryCta>
          </div>
        </div>
      ) : null}
    </header>
  );
}
