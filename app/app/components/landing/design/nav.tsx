"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { EDITOR_PATH } from "@/lib/site";
import stilloraIcon from "@/public/logo/stillora-icon.svg";

const NAV_LINKS = [
  { href: "#features", label: "Features" },
  { href: "#formats", label: "Formats" },
  { href: "#how", label: "How it works" },
  { href: "#platforms", label: "Apps" },
  { href: "#faq", label: "FAQ" },
];

// The real Stillora mark (matches the mobile app icon). viewBox aspect ≈ 312/190.
export function BrandMark({ size = 30 }: { size?: number }) {
  return (
    <Image
      src={stilloraIcon}
      alt="Stillora"
      height={size}
      width={Math.round((size * 312) / 190)}
      priority
      className="flex-shrink-0"
    />
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
