import { query } from "../db";
import {
  ACTIVE_WINDOW_SECONDS,
  normalizePage,
  rangeFilter,
  type AnalyticsRange,
  type Paginated,
} from "./range";

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
