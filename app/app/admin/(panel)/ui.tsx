import { Apple, Globe, Laptop, Monitor, Smartphone, Terminal } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import Link from "next/link";
import type { ReactNode } from "react";

/* ---------------------------------------------------------------- formatting */

/** "3d 4h" / "2h 15m" / "45s" — compact enough for a table cell. */
export function fmtDuration(totalSeconds: number): string {
  const s = Math.max(0, Math.round(totalSeconds));
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ${s % 60}s`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ${m % 60}m`;
  const d = Math.floor(h / 24);
  return `${d}d ${h % 24}h`;
}

export function fmtDate(iso: string): string {
  return new Date(iso).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/** "3m ago" — for anything where recency matters more than the clock time. */
export function fmtAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  if (!Number.isFinite(diff)) return "—";
  const s = Math.max(0, Math.round(diff / 1000));
  if (s < 60) return "just now";
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  return d < 30 ? `${d}d ago` : new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

export function fmtNumber(value: number): string {
  return (Number(value) || 0).toLocaleString("en-US");
}

/** Turns an ISO 3166 alpha-2 code into its flag emoji (regional indicators). */
export function flagEmoji(code: string): string {
  const upper = (code ?? "").toUpperCase();
  if (!/^[A-Z]{2}$/.test(upper)) return "🌐";
  return String.fromCodePoint(...[...upper].map((c) => 0x1f1e6 + c.charCodeAt(0) - 65));
}

/**
 * The surfaces Stillora actually ships on. Web appears only because the
 * landing page and this dashboard are themselves web pages — no creating
 * happens there any more.
 */
const PLATFORM_ICON: Record<string, LucideIcon> = {
  ios: Smartphone,
  android: Smartphone,
  macos: Apple,
  windows: Monitor,
  linux: Terminal,
  web: Globe,
};

/** Icon for a platform id, falling back to a generic device. */
export function PlatformIcon({ platform, size = 14 }: { platform: string; size?: number }) {
  const Icon = PLATFORM_ICON[platform] ?? Laptop;
  return <Icon size={size} className="shrink-0" aria-hidden />;
}

/** Platform name with its icon — the form every table and ranking uses. */
export function PlatformTag({ platform }: { platform: string }) {
  return (
    <span className="inline-flex items-center gap-1.5">
      <PlatformIcon platform={platform} />
      {platformLabel(platform)}
    </span>
  );
}

export function platformLabel(platform: string): string {
  const labels: Record<string, string> = {
    web: "Web",
    ios: "iOS",
    android: "Android",
    macos: "macOS",
    windows: "Windows",
    linux: "Linux",
  };
  return labels[platform] ?? platform ?? "Unknown";
}

export function toolLabel(tool: string): string {
  const labels: Record<string, string> = {
    create: "Create",
    html: "HTML → Video",
    loop: "Loop Images",
    watermark: "Watermark",
    silence: "Remove Silence",
    speed: "Speed",
    convert: "Convert",
  };
  return labels[tool] ?? tool;
}

/** Friendlier label for a route/path (e.g. "/" -> "Home"). */
export function screenLabel(screen: string): string {
  if (screen === "/" || screen === "") return "Home";
  return screen;
}

/** A device id is a UUID or an IP hash — show enough to recognise, not all of it. */
export function shortId(id: string): string {
  if (!id) return "unknown";
  const trimmed = id.replace(/^d-/, "");
  return trimmed.length <= 12 ? trimmed : `${trimmed.slice(0, 8)}…${trimmed.slice(-4)}`;
}

/* -------------------------------------------------------------------- layout */

export function PageHeader({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children?: ReactNode;
}) {
  return (
    <header className="flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 className="text-2xl font-bold tracking-tight" style={{ color: "var(--color-foreground)" }}>
          {title}
        </h1>
        {subtitle ? (
          <p className="mt-1 text-sm" style={{ color: "var(--color-muted)" }}>
            {subtitle}
          </p>
        ) : null}
      </div>
      {children ? <div className="flex flex-wrap items-center gap-3">{children}</div> : null}
    </header>
  );
}

export function Card({
  children,
  className = "",
  padded = true,
}: {
  children: ReactNode;
  className?: string;
  padded?: boolean;
}) {
  return (
    <div
      className={`rounded-2xl border ${padded ? "p-5" : ""} ${className}`}
      style={{
        background: "var(--color-card)",
        borderColor: "var(--color-border)",
        boxShadow: "var(--shadow-card)",
      }}
    >
      {children}
    </div>
  );
}

export function Section({
  title,
  hint,
  action,
  children,
}: {
  title: string;
  hint?: string;
  action?: { href: string; label: string };
  children: ReactNode;
}) {
  return (
    <section className="space-y-3">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <h2 className="text-sm font-bold uppercase tracking-[0.14em]" style={{ color: "var(--color-muted)" }}>
          {title}
        </h2>
        {action ? (
          <Link
            href={action.href}
            className="text-xs font-semibold transition hover:underline"
            style={{ color: "var(--color-primary)" }}
          >
            {action.label} →
          </Link>
        ) : hint ? (
          <span className="text-xs" style={{ color: "var(--color-muted)" }}>
            {hint}
          </span>
        ) : null}
      </div>
      {children}
    </section>
  );
}

export function Empty({ text }: { text: string }) {
  return (
    <div
      className="rounded-2xl border border-dashed px-4 py-12 text-center text-sm"
      style={{ borderColor: "var(--color-border)", color: "var(--color-muted)" }}
    >
      {text}
    </div>
  );
}

/* ---------------------------------------------------------------------- stats */

export type StatTone = "primary" | "secondary" | "success" | "danger" | "neutral";

const TONE_COLOR: Record<StatTone, string> = {
  primary: "var(--color-primary)",
  secondary: "var(--color-secondary)",
  success: "var(--color-success)",
  danger: "var(--color-danger)",
  neutral: "var(--color-foreground)",
};

/**
 * One headline number. The tinted hairline at the top is the only chrome — it
 * keeps a row of six cards readable at a glance without six competing fills.
 */
export function StatCard({
  label,
  value,
  hint,
  tone = "primary",
  href,
  icon: Icon,
}: {
  label: string;
  value: string | number;
  hint?: string;
  tone?: StatTone;
  href?: string;
  icon?: LucideIcon;
}) {
  const color = TONE_COLOR[tone];
  const body = (
    <div
      className="relative h-full overflow-hidden rounded-2xl border p-4 transition"
      style={{
        background: "var(--color-card)",
        borderColor: "var(--color-border)",
        boxShadow: "var(--shadow-card)",
      }}
    >
      <span
        aria-hidden
        className="absolute inset-x-0 top-0 h-0.5"
        style={{ background: `linear-gradient(90deg, ${color}, transparent)` }}
      />
      <p
        className="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-[0.12em]"
        style={{ color: "var(--color-muted)" }}
      >
        {Icon ? <Icon size={13} className="shrink-0" style={{ color }} aria-hidden /> : null}
        {label}
      </p>
      <p className="mt-2 text-2xl font-bold tabular-nums" style={{ color }}>
        {typeof value === "number" ? fmtNumber(value) : value}
      </p>
      {hint ? (
        <p className="mt-1 text-xs" style={{ color: "var(--color-muted)" }}>
          {hint}
        </p>
      ) : null}
    </div>
  );

  return href ? (
    <Link href={href} className="block h-full">
      {body}
    </Link>
  ) : (
    body
  );
}

export function Badge({
  children,
  tone = "primary",
}: {
  children: ReactNode;
  tone?: "primary" | "secondary" | "success" | "danger" | "muted";
}) {
  const styles: Record<string, { background: string; color: string }> = {
    primary: { background: "var(--color-primary-soft)", color: "var(--color-primary)" },
    secondary: { background: "var(--color-secondary-soft)", color: "var(--color-secondary)" },
    success: { background: "var(--color-success-soft)", color: "var(--color-success)" },
    danger: { background: "var(--color-danger-soft)", color: "var(--color-danger)" },
    muted: { background: "var(--color-surface-bright)", color: "var(--color-muted)" },
  };
  return (
    <span
      className="inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold whitespace-nowrap"
      style={styles[tone]}
    >
      {children}
    </span>
  );
}

export function LiveDot({ label }: { label: string }) {
  return (
    <span className="inline-flex items-center gap-2 text-sm" style={{ color: "var(--color-muted)" }}>
      <span className="relative flex size-2">
        <span
          className="absolute inline-flex size-full animate-ping rounded-full opacity-60"
          style={{ background: "var(--color-success)" }}
        />
        <span className="relative inline-flex size-2 rounded-full" style={{ background: "var(--color-success)" }} />
      </span>
      {label}
    </span>
  );
}

/* --------------------------------------------------------------- bar rankings */

export type BarRow = {
  key: string;
  label: ReactNode;
  value: number;
  /** Right-aligned secondary text, e.g. "12 devices · 4h 20m". */
  meta?: string;
};

/**
 * Ranked horizontal bars — the workhorse of this dashboard (countries, tools,
 * platforms, screens all read the same way). Bars are scaled to the largest
 * row, so the shape of the ranking is legible even when totals are tiny.
 */
export function BarList({
  rows,
  emptyText,
  tone = "primary",
}: {
  rows: BarRow[];
  emptyText: string;
  tone?: "primary" | "secondary";
}) {
  const color = tone === "secondary" ? "var(--color-secondary)" : "var(--color-primary)";
  const max = Math.max(1, ...rows.map((r) => r.value));

  if (rows.length === 0) {
    return (
      <p className="py-8 text-center text-sm" style={{ color: "var(--color-muted)" }}>
        {emptyText}
      </p>
    );
  }

  return (
    <ul className="space-y-3">
      {rows.map((row) => (
        <li key={row.key}>
          <div className="flex items-center justify-between gap-3 text-sm">
            <span className="min-w-0 truncate" style={{ color: "var(--color-foreground)" }}>
              {row.label}
            </span>
            <span className="shrink-0 tabular-nums text-xs" style={{ color: "var(--color-muted)" }}>
              {row.meta ?? fmtNumber(row.value)}
            </span>
          </div>
          <div
            className="mt-1.5 h-1.5 w-full overflow-hidden rounded-full"
            style={{ background: "var(--color-border-subtle)" }}
          >
            <div
              className="h-full rounded-full"
              style={{ width: `${Math.max(2, (row.value / max) * 100)}%`, background: color }}
            />
          </div>
        </li>
      ))}
    </ul>
  );
}

/* --------------------------------------------------------------------- tables */

export function Table({ headers, children }: { headers: string[]; children: ReactNode }) {
  return (
    <div
      className="overflow-x-auto rounded-2xl border"
      style={{ borderColor: "var(--color-border)", boxShadow: "var(--shadow-card)" }}
    >
      <table className="w-full text-sm" style={{ background: "var(--color-card)" }}>
        <thead>
          <tr style={{ borderBottom: "1px solid var(--color-border)" }}>
            {headers.map((h) => (
              <th
                key={h}
                className="px-4 py-3 text-left text-[11px] font-bold uppercase tracking-[0.1em] whitespace-nowrap"
                style={{ color: "var(--color-muted)" }}
              >
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>{children}</tbody>
      </table>
    </div>
  );
}

export function Row({ children }: { children: ReactNode }) {
  return <tr style={{ borderBottom: "1px solid var(--color-border-subtle)" }}>{children}</tr>;
}

export function Cell({
  children,
  muted = false,
  nowrap = false,
  mono = false,
}: {
  children: ReactNode;
  muted?: boolean;
  nowrap?: boolean;
  mono?: boolean;
}) {
  return (
    <td
      className={`px-4 py-3 ${nowrap ? "whitespace-nowrap" : ""} ${mono ? "font-mono text-xs" : ""}`}
      style={{ color: muted ? "var(--color-muted)" : "var(--color-foreground)" }}
    >
      {children}
    </td>
  );
}
