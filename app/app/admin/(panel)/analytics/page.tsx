import {
  getAnalyticsOverview,
  getCountryStats,
  getPlatformStats,
  getRecentSessions,
  getTopScreens,
  getUserUsage,
  normalizeRange,
} from "@/lib/analytics-store";
import type {
  CountryStat,
  PlatformStat,
  ScreenStat,
  SessionRecord,
  UserUsageRecord,
} from "@/lib/analytics-store";
import { Pagination } from "../pagination";
import { RangeTabs } from "../range-tabs";

export const dynamic = "force-dynamic";

const BASE = "/admin/analytics";
const PAGE_SIZE = 25;

type SearchParams = Promise<{ [key: string]: string | string[] | undefined }>;

export default async function AdminAnalyticsPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const sp = await searchParams;
  const spRange = first(sp.range);
  const spSessions = first(sp.sp);
  const spUsers = first(sp.up);
  const range = normalizeRange(spRange);
  const sessionsPage = toInt(spSessions);
  const usersPage = toInt(spUsers);

  const [overview, countries, platforms, screens, sessions, users] = await Promise.all([
    getAnalyticsOverview(range),
    getCountryStats(range, 30),
    getPlatformStats(range),
    getTopScreens(range, 15),
    getRecentSessions(range, sessionsPage, PAGE_SIZE),
    getUserUsage(range, usersPage, PAGE_SIZE),
  ]);

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold" style={{ color: "var(--color-foreground)" }}>
          Analytics
        </h1>
        <div className="flex items-center gap-4">
          <span className="flex items-center gap-2 text-sm" style={{ color: "var(--color-muted)" }}>
            <span className="inline-block size-2 rounded-full" style={{ background: "var(--color-success)" }} />
            <b style={{ color: "var(--color-success)" }}>{overview.activeNow}</b> active now
          </span>
          <RangeTabs basePath={BASE} active={range} />
        </div>
      </div>

      {/* Overview cards */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
        <StatCard label="Sessions" value={overview.totalSessions.toLocaleString()} color="var(--color-primary)" />
        <StatCard label="Today" value={overview.sessionsToday.toLocaleString()} color="var(--color-secondary)" />
        <StatCard label="Unique visitors" value={overview.uniqueVisitors.toLocaleString()} color="var(--color-primary)" />
        <StatCard label="Active now" value={overview.activeNow.toLocaleString()} color="var(--color-success)" />
        <StatCard label="Total time used" value={fmtDuration(overview.totalUsageSeconds)} color="var(--color-secondary)" />
        <StatCard label="Avg session" value={fmtDuration(overview.avgSessionSeconds)} color="var(--color-primary)" />
      </div>

      <div className="grid grid-cols-1 gap-8 lg:grid-cols-2">
        <CountriesCard countries={countries} />
        <PlatformsCard platforms={platforms} />
      </div>

      <ScreensCard screens={screens} />

      <section>
        <h2 className="mb-3 text-lg font-semibold" style={{ color: "var(--color-foreground)" }}>
          Time used per user
        </h2>
        <UserUsageTable users={users.rows} />
        <Pagination
          basePath={BASE}
          params={{ range, sp: spSessions }}
          pageParam="up"
          page={users.page}
          pageSize={users.pageSize}
          total={users.total}
        />
      </section>

      <section>
        <h2 className="mb-3 text-lg font-semibold" style={{ color: "var(--color-foreground)" }}>
          Sessions
        </h2>
        <SessionsTable sessions={sessions.rows} />
        <Pagination
          basePath={BASE}
          params={{ range, up: spUsers }}
          pageParam="sp"
          page={sessions.page}
          pageSize={sessions.pageSize}
          total={sessions.total}
        />
      </section>
    </div>
  );
}

/** Search-param values can be string | string[]; take the first string. */
function first(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

function toInt(value: string | undefined): number {
  const n = value ? parseInt(value, 10) : 1;
  return Number.isFinite(n) && n >= 1 ? n : 1;
}

function ScreensCard({ screens }: { screens: ScreenStat[] }) {
  const max = Math.max(1, ...screens.map((s) => s.views));
  return (
    <section>
      <h2 className="mb-3 text-lg font-semibold" style={{ color: "var(--color-foreground)" }}>
        Top screens &amp; features
      </h2>
      <div className="rounded-xl border p-4" style={{ background: "var(--color-card)", borderColor: "var(--color-border)" }}>
        {screens.length === 0 ? (
          <p className="py-6 text-center text-sm" style={{ color: "var(--color-muted)" }}>
            No screen views in this range yet.
          </p>
        ) : (
          <ul className="space-y-2.5">
            {screens.map((s) => (
              <li key={s.screen} className="flex items-center gap-3">
                <span className="w-40 shrink-0 truncate font-mono text-xs" style={{ color: "var(--color-foreground)" }} title={s.screen}>
                  {screenLabel(s.screen)}
                </span>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between text-sm">
                    <span className="tabular-nums" style={{ color: "var(--color-muted)" }}>{s.views.toLocaleString()} views</span>
                    <span className="ml-2 shrink-0 tabular-nums" style={{ color: "var(--color-muted)" }}>{s.users.toLocaleString()} users</span>
                  </div>
                  <div className="mt-1 h-1.5 w-full overflow-hidden rounded-full" style={{ background: "var(--color-border-subtle)" }}>
                    <div className="h-full rounded-full" style={{ width: `${(s.views / max) * 100}%`, background: "var(--color-primary)" }} />
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </section>
  );
}

/** Friendlier label for a route/path (e.g. "/" -> "Home"). */
function screenLabel(screen: string): string {
  if (screen === "/" || screen === "") return "Home";
  return screen;
}

function UserUsageTable({ users }: { users: UserUsageRecord[] }) {
  if (users.length === 0) {
    return <Empty text="No usage in this range yet." />;
  }
  return (
    <div className="overflow-x-auto rounded-xl border" style={{ borderColor: "var(--color-border)" }}>
      <table className="w-full text-sm" style={{ background: "var(--color-card)" }}>
        <thead>
          <tr style={{ borderBottom: "1px solid var(--color-border)" }}>
            {["User", "Platforms", "Location", "Sessions", "Total time", "Last seen"].map((h) => (
              <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide" style={{ color: "var(--color-muted)" }}>
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {users.map((u, i) => (
            <tr key={u.userSub ?? `anon-${i}`} style={{ borderBottom: "1px solid var(--color-border-subtle)" }}>
              <td className="px-4 py-3">
                <div className="min-w-0">
                  <div className="truncate font-medium" style={{ color: "var(--color-foreground)" }}>{u.userName}</div>
                  {u.userEmail && <div className="truncate text-xs" style={{ color: "var(--color-muted)" }}>{u.userEmail}</div>}
                </div>
              </td>
              <td className="px-4 py-3">
                <div className="flex flex-wrap gap-1">
                  {u.platforms.map((p) => (
                    <span key={p} className="rounded-full px-2 py-0.5 text-xs font-semibold capitalize" style={{ background: "var(--color-primary-soft)", color: "var(--color-primary)" }}>
                      {platformLabel(p)}
                    </span>
                  ))}
                </div>
              </td>
              <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>
                {u.country ? `${flagEmoji(u.countryCode)} ${u.country}` : "Unknown"}
              </td>
              <td className="px-4 py-3 tabular-nums" style={{ color: "var(--color-muted)" }}>{u.sessions}</td>
              <td className="px-4 py-3 tabular-nums font-semibold" style={{ color: "var(--color-secondary)" }}>{fmtDuration(u.totalSeconds)}</td>
              <td className="px-4 py-3 whitespace-nowrap" style={{ color: "var(--color-muted)" }}>{fmtDate(u.lastSeen)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function Empty({ text }: { text: string }) {
  return (
    <p className="rounded-xl border px-4 py-12 text-center text-sm" style={{ borderColor: "var(--color-border)", color: "var(--color-muted)" }}>
      {text}
    </p>
  );
}

function StatCard({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <div
      className="rounded-xl border p-4"
      style={{ background: "var(--color-card)", borderColor: "var(--color-border)" }}
    >
      <p className="text-xs font-medium" style={{ color: "var(--color-muted)" }}>{label}</p>
      <p className="mt-1 text-2xl font-bold" style={{ color }}>{value}</p>
    </div>
  );
}

function CountriesCard({ countries }: { countries: CountryStat[] }) {
  const max = Math.max(1, ...countries.map((c) => c.sessions));
  return (
    <section>
      <h2 className="mb-3 text-lg font-semibold" style={{ color: "var(--color-foreground)" }}>
        Top countries
      </h2>
      <div className="rounded-xl border p-4" style={{ background: "var(--color-card)", borderColor: "var(--color-border)" }}>
        {countries.length === 0 ? (
          <p className="py-6 text-center text-sm" style={{ color: "var(--color-muted)" }}>No location data yet.</p>
        ) : (
          <ul className="space-y-2.5">
            {countries.map((c) => (
              <li key={`${c.country}-${c.countryCode}`} className="flex items-center gap-3">
                <span className="w-6 shrink-0 text-base" title={c.countryCode}>{flagEmoji(c.countryCode)}</span>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between text-sm">
                    <span className="truncate" style={{ color: "var(--color-foreground)" }}>{c.country}</span>
                    <span className="ml-2 shrink-0 tabular-nums" style={{ color: "var(--color-muted)" }}>
                      {c.sessions} · {fmtDuration(c.usageSeconds)}
                    </span>
                  </div>
                  <div className="mt-1 h-1.5 w-full overflow-hidden rounded-full" style={{ background: "var(--color-border-subtle)" }}>
                    <div className="h-full rounded-full" style={{ width: `${(c.sessions / max) * 100}%`, background: "var(--color-primary)" }} />
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </section>
  );
}

function PlatformsCard({ platforms }: { platforms: PlatformStat[] }) {
  const max = Math.max(1, ...platforms.map((p) => p.sessions));
  return (
    <section>
      <h2 className="mb-3 text-lg font-semibold" style={{ color: "var(--color-foreground)" }}>
        Platforms
      </h2>
      <div className="rounded-xl border p-4" style={{ background: "var(--color-card)", borderColor: "var(--color-border)" }}>
        {platforms.length === 0 ? (
          <p className="py-6 text-center text-sm" style={{ color: "var(--color-muted)" }}>No sessions yet.</p>
        ) : (
          <ul className="space-y-2.5">
            {platforms.map((p) => (
              <li key={p.platform} className="flex items-center gap-3">
                <span className="w-16 shrink-0 text-sm capitalize" style={{ color: "var(--color-foreground)" }}>
                  {platformLabel(p.platform)}
                </span>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between text-sm">
                    <span className="tabular-nums" style={{ color: "var(--color-muted)" }}>{p.sessions} sessions</span>
                    <span className="ml-2 shrink-0 tabular-nums" style={{ color: "var(--color-muted)" }}>{fmtDuration(p.usageSeconds)}</span>
                  </div>
                  <div className="mt-1 h-1.5 w-full overflow-hidden rounded-full" style={{ background: "var(--color-border-subtle)" }}>
                    <div className="h-full rounded-full" style={{ width: `${(p.sessions / max) * 100}%`, background: "var(--color-secondary)" }} />
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </section>
  );
}

function SessionsTable({ sessions }: { sessions: SessionRecord[] }) {
  if (sessions.length === 0) {
    return (
      <p className="rounded-xl border px-4 py-12 text-center text-sm" style={{ borderColor: "var(--color-border)", color: "var(--color-muted)" }}>
        No sessions recorded yet. Open the app to generate the first one.
      </p>
    );
  }

  return (
    <div className="overflow-x-auto rounded-xl border" style={{ borderColor: "var(--color-border)" }}>
      <table className="w-full text-sm" style={{ background: "var(--color-card)" }}>
        <thead>
          <tr style={{ borderBottom: "1px solid var(--color-border)" }}>
            {["User", "Platform", "Location", "Device", "Duration", "Last seen"].map((h) => (
              <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide" style={{ color: "var(--color-muted)" }}>
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {sessions.map((s) => (
            <tr key={s.id} style={{ borderBottom: "1px solid var(--color-border-subtle)" }}>
              <td className="px-4 py-3">
                <div className="flex items-center gap-2">
                  {s.active && <span className="inline-block size-2 shrink-0 rounded-full" style={{ background: "var(--color-success)" }} title="Active" />}
                  <div className="min-w-0">
                    <div className="truncate font-medium" style={{ color: "var(--color-foreground)" }}>{s.userName}</div>
                    {s.userEmail && <div className="truncate text-xs" style={{ color: "var(--color-muted)" }}>{s.userEmail}</div>}
                  </div>
                </div>
              </td>
              <td className="px-4 py-3">
                <span className="rounded-full px-2 py-0.5 text-xs font-semibold capitalize" style={{ background: "var(--color-primary-soft)", color: "var(--color-primary)" }}>
                  {platformLabel(s.platform)}
                </span>
              </td>
              <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>
                {s.country ? (
                  <span>{flagEmoji(s.countryCode)} {[s.city, s.country].filter(Boolean).join(", ")}</span>
                ) : (
                  <span style={{ color: "var(--color-muted)" }}>Unknown</span>
                )}
              </td>
              <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>
                {[s.os, s.browser].filter(Boolean).join(" · ") || s.device || "—"}
                {s.appVersion ? ` · v${s.appVersion}` : ""}
              </td>
              <td className="px-4 py-3 tabular-nums font-medium" style={{ color: "var(--color-secondary)" }}>{fmtDuration(s.durationSeconds)}</td>
              <td className="px-4 py-3 whitespace-nowrap" style={{ color: "var(--color-muted)" }}>{fmtDate(s.lastSeenAt)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function platformLabel(platform: string): string {
  const labels: Record<string, string> = {
    web: "Web",
    ios: "iOS",
    android: "Android",
    macos: "macOS",
    windows: "Windows",
    linux: "Linux",
  };
  return labels[platform] ?? platform;
}

/** Turns an ISO 3166 alpha-2 code into its flag emoji (regional indicators). */
function flagEmoji(code: string): string {
  if (!code || code.length !== 2) return "🌐";
  const upper = code.toUpperCase();
  if (!/^[A-Z]{2}$/.test(upper)) return "🌐";
  return String.fromCodePoint(...[...upper].map((c) => 0x1f1e6 + c.charCodeAt(0) - 65));
}

function fmtDuration(totalSeconds: number): string {
  const s = Math.max(0, Math.round(totalSeconds));
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ${s % 60}s`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ${m % 60}m`;
  const d = Math.floor(h / 24);
  return `${d}d ${h % 24}h`;
}

function fmtDate(iso: string): string {
  return new Date(iso).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
