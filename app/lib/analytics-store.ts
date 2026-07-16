import { createHash } from "node:crypto";

import { query } from "./db";
import type { GeoLocation } from "./geo";

// A session is considered "active" if it has sent a heartbeat within this window.
const ACTIVE_WINDOW_SECONDS = 90;

export type TrackEvent = "start" | "heartbeat" | "end";

export type TrackInput = {
  clientId: string;
  event: TrackEvent;
  platform: string;
  appVersion: string;
  user: { sub: string; email: string; name: string } | null;
  geo: GeoLocation;
  ip: string;
  userAgent: string;
};

const KNOWN_PLATFORMS = new Set([
  "web",
  "ios",
  "android",
  "macos",
  "windows",
  "linux",
]);

function normalizePlatform(value: string): string {
  const p = value.trim().toLowerCase();
  return KNOWN_PLATFORMS.has(p) ? p : "web";
}

/** Coarse OS/browser/device sniffing from a User-Agent string. No dependency. */
function parseUserAgent(ua: string): { os: string; browser: string; device: string } {
  if (!ua) return { os: "", browser: "", device: "" };

  let os = "";
  if (/windows nt/i.test(ua)) os = "Windows";
  else if (/iphone|ipad|ipod/i.test(ua)) os = "iOS";
  else if (/android/i.test(ua)) os = "Android";
  else if (/mac os x/i.test(ua)) os = "macOS";
  else if (/linux/i.test(ua)) os = "Linux";

  let browser = "";
  if (/edg\//i.test(ua)) browser = "Edge";
  else if (/opr\/|opera/i.test(ua)) browser = "Opera";
  else if (/chrome\//i.test(ua) && !/chromium/i.test(ua)) browser = "Chrome";
  else if (/firefox\//i.test(ua)) browser = "Firefox";
  else if (/safari\//i.test(ua) && !/chrome/i.test(ua)) browser = "Safari";

  const device = /mobile|iphone|ipod|android.*mobile/i.test(ua)
    ? "Mobile"
    : /ipad|tablet/i.test(ua)
      ? "Tablet"
      : "Desktop";

  return { os, browser, device };
}

function hashIp(ip: string): string {
  if (!ip) return "";
  const salt = process.env.AUTH_SECRET ?? "stillora";
  return createHash("sha256").update(`${salt}:${ip}`).digest("hex").slice(0, 16);
}

/**
 * Upserts a usage session. `start` creates (or refreshes) the row and fills in
 * location/device details; `heartbeat`/`end` just extend the duration. Errors
 * are swallowed so tracking never breaks the app.
 */
export async function trackSession(input: TrackInput): Promise<void> {
  const clientId = input.clientId.trim();
  if (!clientId) return;

  const platform = normalizePlatform(input.platform);
  const { os, browser, device } = parseUserAgent(input.userAgent);
  const ipHash = hashIp(input.ip);
  const endedClause = input.event === "end" ? "now()" : "NULL";

  try {
    if (input.event === "start") {
      await query(
        `INSERT INTO admin_sessions
           (client_id, user_sub, user_email, user_name, platform, app_version,
            country, country_code, region, city, os, browser, device, user_agent,
            ip_hash, started_at, last_seen_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15, now(), now())
         ON CONFLICT (client_id) DO UPDATE
           SET last_seen_at = now(),
               ended_at = NULL,
               -- Fill user/geo fields once we learn them (e.g. user signs in mid-session).
               user_sub  = COALESCE(admin_sessions.user_sub, EXCLUDED.user_sub),
               user_email = CASE WHEN admin_sessions.user_email = '' THEN EXCLUDED.user_email ELSE admin_sessions.user_email END,
               user_name  = CASE WHEN admin_sessions.user_name = '' THEN EXCLUDED.user_name ELSE admin_sessions.user_name END,
               country      = CASE WHEN admin_sessions.country = '' THEN EXCLUDED.country ELSE admin_sessions.country END,
               country_code = CASE WHEN admin_sessions.country_code = '' THEN EXCLUDED.country_code ELSE admin_sessions.country_code END,
               region       = CASE WHEN admin_sessions.region = '' THEN EXCLUDED.region ELSE admin_sessions.region END,
               city         = CASE WHEN admin_sessions.city = '' THEN EXCLUDED.city ELSE admin_sessions.city END,
               app_version  = CASE WHEN EXCLUDED.app_version <> '' THEN EXCLUDED.app_version ELSE admin_sessions.app_version END,
               duration_seconds = GREATEST(admin_sessions.duration_seconds,
                 CAST(EXTRACT(EPOCH FROM (now() - admin_sessions.started_at)) AS INTEGER))`,
        [
          clientId,
          input.user?.sub ?? null,
          input.user?.email ?? "",
          input.user?.name ?? "",
          platform,
          input.appVersion,
          input.geo.country,
          input.geo.countryCode,
          input.geo.region,
          input.geo.city,
          os,
          browser,
          device,
          input.userAgent.slice(0, 500),
          ipHash,
        ],
      );
      return;
    }

    // heartbeat / end: extend the live session; only touch rows we already have.
    await query(
      `UPDATE admin_sessions
         SET last_seen_at = now(),
             ended_at = ${endedClause},
             user_sub = COALESCE(admin_sessions.user_sub, $2),
             user_email = CASE WHEN admin_sessions.user_email = '' THEN $3 ELSE admin_sessions.user_email END,
             user_name  = CASE WHEN admin_sessions.user_name = '' THEN $4 ELSE admin_sessions.user_name END,
             duration_seconds = CAST(EXTRACT(EPOCH FROM (now() - started_at)) AS INTEGER)
       WHERE client_id = $1`,
      [clientId, input.user?.sub ?? null, input.user?.email ?? "", input.user?.name ?? ""],
    );
  } catch (error) {
    console.error("trackSession failed:", error);
  }
}

// --- Dashboard read models ---

export type AnalyticsOverview = {
  totalSessions: number;
  sessionsToday: number;
  activeNow: number;
  uniqueVisitors: number;
  totalUsageSeconds: number;
  avgSessionSeconds: number;
};

export type CountryStat = {
  country: string;
  countryCode: string;
  sessions: number;
  usageSeconds: number;
};

export type PlatformStat = {
  platform: string;
  sessions: number;
  usageSeconds: number;
};

export type SessionRecord = {
  id: string;
  userName: string;
  userEmail: string;
  platform: string;
  country: string;
  countryCode: string;
  city: string;
  os: string;
  browser: string;
  device: string;
  appVersion: string;
  startedAt: string;
  lastSeenAt: string;
  durationSeconds: number;
  active: boolean;
};

export type AnalyticsRange = "today" | "7d" | "30d" | "all";

export const ANALYTICS_RANGES: { key: AnalyticsRange; label: string }[] = [
  { key: "today", label: "Today" },
  { key: "7d", label: "7 days" },
  { key: "30d", label: "30 days" },
  { key: "all", label: "All time" },
];

export function normalizeRange(value: string | undefined): AnalyticsRange {
  return value === "today" || value === "7d" || value === "30d" || value === "all"
    ? value
    : "7d";
}

/**
 * SQL boolean limiting `started_at` to the selected range. The range keys come
 * from a fixed set (never user text), so inlining the expression is safe.
 */
function rangeFilter(range: AnalyticsRange): string {
  switch (range) {
    case "today":
      return "started_at >= date_trunc('day', now())";
    case "7d":
      return "started_at >= now() - make_interval(days => 7)";
    case "30d":
      return "started_at >= now() - make_interval(days => 30)";
    case "all":
      return "TRUE";
  }
}

export type Paginated<T> = {
  rows: T[];
  total: number;
  page: number;
  pageSize: number;
};

/** Clamps a 1-based page and page size to sane bounds. */
export function normalizePage(
  page: unknown,
  pageSize: number,
): { page: number; pageSize: number; offset: number } {
  const n = typeof page === "string" ? parseInt(page, 10) : Number(page);
  const safePage = Number.isFinite(n) && n >= 1 ? Math.floor(n) : 1;
  return { page: safePage, pageSize, offset: (safePage - 1) * pageSize };
}

export async function getAnalyticsOverview(
  range: AnalyticsRange = "all",
): Promise<AnalyticsOverview> {
  const rf = rangeFilter(range);
  try {
    // Subqueries (not FILTER) so range-scoped and absolute metrics coexist:
    // total/unique/usage/avg follow the range; today/active-now are always live.
    const rows = await query<{
      total_sessions: number;
      sessions_today: number;
      active_now: number;
      unique_visitors: number;
      total_usage: number;
      avg_session: number;
    }>(
      `SELECT
         (SELECT COUNT(*) FROM admin_sessions WHERE ${rf})::int AS total_sessions,
         (SELECT COUNT(*) FROM admin_sessions
            WHERE started_at >= date_trunc('day', now()))::int AS sessions_today,
         (SELECT COUNT(*) FROM admin_sessions
            WHERE last_seen_at >= now() - make_interval(secs => ${ACTIVE_WINDOW_SECONDS})
              AND ended_at IS NULL)::int AS active_now,
         (SELECT COUNT(DISTINCT COALESCE(user_sub, ip_hash))
            FROM admin_sessions WHERE ${rf})::int AS unique_visitors,
         (SELECT COALESCE(SUM(duration_seconds), 0)
            FROM admin_sessions WHERE ${rf})::bigint AS total_usage,
         (SELECT COALESCE(AVG(duration_seconds), 0)
            FROM admin_sessions WHERE ${rf})::int AS avg_session`,
    );
    const r = rows[0];
    return {
      totalSessions: Number(r?.total_sessions) || 0,
      sessionsToday: Number(r?.sessions_today) || 0,
      activeNow: Number(r?.active_now) || 0,
      uniqueVisitors: Number(r?.unique_visitors) || 0,
      totalUsageSeconds: Number(r?.total_usage) || 0,
      avgSessionSeconds: Number(r?.avg_session) || 0,
    };
  } catch (error) {
    console.error("getAnalyticsOverview failed:", error);
    return {
      totalSessions: 0,
      sessionsToday: 0,
      activeNow: 0,
      uniqueVisitors: 0,
      totalUsageSeconds: 0,
      avgSessionSeconds: 0,
    };
  }
}

export async function getCountryStats(
  range: AnalyticsRange = "all",
  limit = 30,
): Promise<CountryStat[]> {
  try {
    const rows = await query<{
      country: string;
      country_code: string;
      sessions: number;
      usage_seconds: number;
    }>(
      `SELECT
         CASE WHEN country = '' THEN 'Unknown' ELSE country END AS country,
         country_code,
         COUNT(*)::int AS sessions,
         COALESCE(SUM(duration_seconds), 0)::bigint AS usage_seconds
       FROM admin_sessions
       WHERE ${rangeFilter(range)}
       GROUP BY country, country_code
       ORDER BY sessions DESC
       LIMIT $1`,
      [limit],
    );
    return rows.map((r) => ({
      country: r.country,
      countryCode: r.country_code,
      sessions: Number(r.sessions) || 0,
      usageSeconds: Number(r.usage_seconds) || 0,
    }));
  } catch (error) {
    console.error("getCountryStats failed:", error);
    return [];
  }
}

export async function getPlatformStats(
  range: AnalyticsRange = "all",
): Promise<PlatformStat[]> {
  try {
    const rows = await query<{
      platform: string;
      sessions: number;
      usage_seconds: number;
    }>(
      `SELECT platform,
              COUNT(*)::int AS sessions,
              COALESCE(SUM(duration_seconds), 0)::bigint AS usage_seconds
       FROM admin_sessions
       WHERE ${rangeFilter(range)}
       GROUP BY platform
       ORDER BY sessions DESC`,
    );
    return rows.map((r) => ({
      platform: r.platform,
      sessions: Number(r.sessions) || 0,
      usageSeconds: Number(r.usage_seconds) || 0,
    }));
  } catch (error) {
    console.error("getPlatformStats failed:", error);
    return [];
  }
}

export async function getRecentSessions(
  range: AnalyticsRange = "all",
  page = 1,
  pageSize = 25,
): Promise<Paginated<SessionRecord>> {
  const rf = rangeFilter(range);
  const { page: safePage, offset } = normalizePage(page, pageSize);
  const empty: Paginated<SessionRecord> = { rows: [], total: 0, page: safePage, pageSize };
  try {
    const [rows, totals] = await Promise.all([
      query<{
        id: string;
        user_name: string;
        user_email: string;
        platform: string;
        country: string;
        country_code: string;
        city: string;
        os: string;
        browser: string;
        device: string;
        app_version: string;
        started_at: Date;
        last_seen_at: Date;
        ended_at: Date | null;
        duration_seconds: number;
      }>(
        `SELECT id, user_name, user_email, platform, country, country_code, city,
                os, browser, device, app_version, started_at, last_seen_at, ended_at,
                duration_seconds
         FROM admin_sessions
         WHERE ${rf}
         ORDER BY last_seen_at DESC
         LIMIT $1 OFFSET $2`,
        [pageSize, offset],
      ),
      query<{ count: number }>(
        `SELECT COUNT(*)::int AS count FROM admin_sessions WHERE ${rf}`,
      ),
    ]);
    const activeThreshold = Date.now() - ACTIVE_WINDOW_SECONDS * 1000;
    return {
      page: safePage,
      pageSize,
      total: Number(totals[0]?.count) || 0,
      rows: rows.map((r) => ({
        id: r.id,
        userName: r.user_name || "Anonymous",
        userEmail: r.user_email,
        platform: r.platform,
        country: r.country,
        countryCode: r.country_code,
        city: r.city,
        os: r.os,
        browser: r.browser,
        device: r.device,
        appVersion: r.app_version,
        startedAt: new Date(r.started_at).toISOString(),
        lastSeenAt: new Date(r.last_seen_at).toISOString(),
        durationSeconds: Number(r.duration_seconds) || 0,
        active:
          r.ended_at === null && new Date(r.last_seen_at).getTime() >= activeThreshold,
      })),
    };
  } catch (error) {
    console.error("getRecentSessions failed:", error);
    return empty;
  }
}

export type UserUsageRecord = {
  userSub: string | null;
  userName: string;
  userEmail: string;
  sessions: number;
  totalSeconds: number;
  lastSeen: string;
  country: string;
  countryCode: string;
  platforms: string[];
};

/** Per-user aggregate usage for the selected range, ranked by total time used. */
export async function getUserUsage(
  range: AnalyticsRange = "all",
  page = 1,
  pageSize = 25,
): Promise<Paginated<UserUsageRecord>> {
  const rf = rangeFilter(range);
  const { page: safePage, offset } = normalizePage(page, pageSize);
  const empty: Paginated<UserUsageRecord> = { rows: [], total: 0, page: safePage, pageSize };
  try {
    const [rows, total] = await Promise.all([
      query<{
        user_sub: string | null;
        user_name: string;
        user_email: string;
        sessions: number;
        total_seconds: number;
        last_seen: Date;
        country: string | null;
        country_code: string | null;
        platforms: string[];
      }>(
        `SELECT
           user_sub,
           MAX(user_name) AS user_name,
           MAX(user_email) AS user_email,
           COUNT(*)::int AS sessions,
           COALESCE(SUM(duration_seconds), 0)::bigint AS total_seconds,
           MAX(last_seen_at) AS last_seen,
           (array_agg(country ORDER BY last_seen_at DESC)
              FILTER (WHERE country <> ''))[1] AS country,
           (array_agg(country_code ORDER BY last_seen_at DESC)
              FILTER (WHERE country_code <> ''))[1] AS country_code,
           array_agg(DISTINCT platform) AS platforms
         FROM admin_sessions
         WHERE ${rf}
         GROUP BY user_sub
         ORDER BY total_seconds DESC
         LIMIT $1 OFFSET $2`,
        [pageSize, offset],
      ),
      countUserGroups(rf),
    ]);
    return {
      page: safePage,
      pageSize,
      total,
      rows: rows.map((r) => ({
        userSub: r.user_sub,
        userName: r.user_name || "Anonymous",
        userEmail: r.user_email || "",
        sessions: Number(r.sessions) || 0,
        totalSeconds: Number(r.total_seconds) || 0,
        lastSeen: new Date(r.last_seen).toISOString(),
        country: r.country ?? "",
        countryCode: r.country_code ?? "",
        platforms: Array.isArray(r.platforms) ? r.platforms : [],
      })),
    };
  } catch (error) {
    console.error("getUserUsage failed:", error);
    return empty;
  }
}

/** Total number of distinct user groups (each user_sub, plus one anon bucket). */
async function countUserGroups(rangeFilterSql: string): Promise<number> {
  const rows = await query<{ count: number }>(
    `SELECT COUNT(*)::int AS count
     FROM (SELECT 1 FROM admin_sessions WHERE ${rangeFilterSql}
           GROUP BY user_sub) g`,
  );
  return Number(rows[0]?.count) || 0;
}
