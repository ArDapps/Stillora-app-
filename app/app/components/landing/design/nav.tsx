"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { EDITOR_PATH } from "@/lib/site";

const NAV_LINKS = [
  { href: "#features", label: "Features" },
  { href: "#formats", label: "Formats" },
  { href: "#how", label: "How it works" },
  { href: "#platforms", label: "Apps" },
  { href: "#faq", label: "FAQ" },
];

export function BrandMark({ size = 32 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 116 116" aria-hidden="true">
      <rect x="8" y="8" width="100" height="100" rx="26" fill="#7c3aed" />
      <path d="M48 41.5 L78 58 L48 74.5 Z" fill="#fff" />
      <circle cx="40" cy="41" r="3.6" fill="#facc15" />
    </svg>
  );
}

export function DesignNav() {
  const [stuck, setStuck] = useState(false);

  useEffect(() => {
    const onScroll = () => setStuck(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header className={`nav${stuck ? " stuck" : ""}`}>
      <div className="wrap">
        <a className="brand" href="#top" aria-label="Stillora home">
          <BrandMark />
          <span className="word">Stillora</span>
        </a>
        <nav className="nav-links" aria-label="Primary">
          {NAV_LINKS.map((l) => (
            <a key={l.href} href={l.href}>
              {l.label}
            </a>
          ))}
        </nav>
        <div className="nav-cta">
          <Link
            href={EDITOR_PATH}
            className="btn btn-primary"
            style={{ height: 42, fontSize: 14, padding: "0 18px" }}
          >
            Start Free
          </Link>
        </div>
      </div>
    </header>
  );
}
