"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  AlertTriangle,
  Clapperboard,
  Download,
  Gauge,
  Users,
} from "lucide-react";

const ITEMS = [
  { href: "/admin", label: "Overview", icon: Gauge },
  { href: "/admin/usage", label: "Usage", icon: Users },
  { href: "/admin/exports", label: "Exports", icon: Clapperboard },
  { href: "/admin/errors", label: "Errors", icon: AlertTriangle },
  { href: "/admin/downloads", label: "Downloads", icon: Download },
];

/**
 * Sidebar navigation. Client-side only so the active route can be highlighted —
 * the panel is five pages, and knowing which one you are on matters more than
 * shaving a component off the bundle.
 */
export function AdminNav({
  errorCount = 0,
  orientation = "vertical",
}: {
  errorCount?: number;
  orientation?: "vertical" | "horizontal";
}) {
  const pathname = usePathname();
  const horizontal = orientation === "horizontal";

  return (
    <nav
      className={
        horizontal
          ? "flex gap-1 overflow-x-auto px-3 py-2"
          : "flex flex-1 flex-col gap-1 p-3"
      }
    >
      {ITEMS.map(({ href, label, icon: Icon }) => {
        // "/admin" would otherwise light up on every child route.
        const active = href === "/admin" ? pathname === href : pathname.startsWith(href);
        const badge = href === "/admin/errors" && errorCount > 0 ? errorCount : 0;
        return (
          <Link
            key={href}
            href={href}
            className={`flex items-center gap-2.5 rounded-xl px-3 py-2 text-sm font-medium transition ${
              horizontal ? "shrink-0" : ""
            }`}
            style={
              active
                ? {
                    background: "var(--color-primary-soft)",
                    color: "var(--color-primary)",
                    boxShadow: "inset 0 0 0 1px var(--color-primary-soft)",
                  }
                : { color: "var(--color-muted)" }
            }
          >
            <Icon size={16} className="shrink-0" />
            <span className={horizontal ? "whitespace-nowrap" : "min-w-0 flex-1 truncate"}>{label}</span>
            {badge > 0 ? (
              <span
                className="rounded-full px-1.5 py-0.5 text-[10px] font-bold tabular-nums"
                style={{ background: "var(--color-danger-soft)", color: "var(--color-danger)" }}
              >
                {badge > 99 ? "99+" : badge}
              </span>
            ) : null}
          </Link>
        );
      })}
    </nav>
  );
}
