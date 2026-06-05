"use client";

import { ArrowRight, Menu, X } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import type { NavLink } from "@/lib/landing-content";
import { EDITOR_PATH } from "@/lib/site";

/**
 * Accessible mobile navigation drawer for the landing page. Shown only below
 * the `md` breakpoint; the desktop nav lives directly in SiteHeader.
 */
export function MobileNav({ links }: { links: NavLink[] }) {
  const [open, setOpen] = useState(false);

  // Lock body scroll and support Escape-to-close while the drawer is open.
  useEffect(() => {
    if (!open) return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setOpen(false);
    };
    document.addEventListener("keydown", onKeyDown);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKeyDown);
      document.body.style.overflow = "";
    };
  }, [open]);

  return (
    <div className="md:hidden">
      <button
        type="button"
        aria-label="Open navigation menu"
        aria-expanded={open}
        aria-controls="mobile-nav-drawer"
        onClick={() => setOpen(true)}
        className="grid size-9 place-items-center rounded-md border border-[var(--color-border)] text-[var(--color-foreground)] transition hover:border-[var(--color-primary)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
      >
        <Menu size={18} aria-hidden />
      </button>

      {open ? (
        <div className="fixed inset-0 z-50">
          <button
            type="button"
            aria-label="Close navigation menu"
            tabIndex={-1}
            onClick={() => setOpen(false)}
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
          />
          <div
            id="mobile-nav-drawer"
            role="dialog"
            aria-modal="true"
            aria-label="Site navigation"
            className="absolute right-0 top-0 flex h-full w-72 max-w-[85%] flex-col gap-2 border-l border-[var(--color-border)] bg-[var(--color-card)] p-5 shadow-2xl"
          >
            <div className="mb-2 flex items-center justify-between">
              <span className="text-sm font-semibold text-[var(--color-muted-strong)]">Menu</span>
              <button
                type="button"
                aria-label="Close navigation menu"
                onClick={() => setOpen(false)}
                className="grid size-9 place-items-center rounded-md border border-[var(--color-border)] text-[var(--color-foreground)] transition hover:border-[var(--color-primary)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
              >
                <X size={18} aria-hidden />
              </button>
            </div>

            <nav className="flex flex-col" aria-label="Primary">
              {links.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  onClick={() => setOpen(false)}
                  className="rounded-md px-3 py-3 text-base font-medium text-[var(--color-foreground)] transition hover:bg-[var(--color-surface)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
                >
                  {link.label}
                </a>
              ))}
            </nav>

            <Link
              href={EDITOR_PATH}
              onClick={() => setOpen(false)}
              className="mt-auto inline-flex items-center justify-center gap-2 rounded-md bg-[var(--color-primary)] px-4 py-3 text-sm font-semibold text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
            >
              Open Editor
              <ArrowRight size={16} aria-hidden />
            </Link>
          </div>
        </div>
      ) : null}
    </div>
  );
}
