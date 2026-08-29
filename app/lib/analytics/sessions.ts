import { query } from "../db";
import { logError } from "../error-log";
import {
  ACTIVE_WINDOW_SECONDS,
  normalizePage,
  rangeFilter,
  type AnalyticsRange,
  type Paginated,
} from "./range";

export type SessionRecord = {
  id: string;
  deviceId: string;
  platform: string;
  country: string;
  countryCode: string;
  city: string;
  os: string;
  browser: string;
  device: string;
  appVersion: string;
  isPro: boolean;
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
        device_key: string;
        platform: string;
        country: string;
        country_code: string;
        city: string;
        os: string;
        browser: string;
        device: string;
        app_version: string;
        is_pro: boolean;
        started_at: Date;
        last_seen_at: Date;
        ended_at: Date | null;
        duration_seconds: number;
      }>(
        `SELECT id, COALESCE(NULLIF(device_id, ''), ip_hash) AS device_key, platform,
                country, country_code, city, os, browser, device, app_version, is_pro,
                started_at, last_seen_at, ended_at, duration_seconds
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
        deviceId: r.device_key ?? "",
        platform: r.platform,
        country: r.country,
        countryCode: r.country_code,
        city: r.city,
        os: r.os,
        browser: r.browser,
        device: r.device,
        appVersion: r.app_version,
        isPro: Boolean(r.is_pro),
        startedAt: new Date(r.started_at).toISOString(),
        lastSeenAt: new Date(r.last_seen_at).toISOString(),
        durationSeconds: Number(r.duration_seconds) || 0,
        active:
          r.ended_at === null && new Date(r.last_seen_at).getTime() >= activeThreshold,
      })),
    };
  } catch (error) {
    void logError({ source: "analytics/getRecentSessions", error });
    return empty;
  }
}

export type DeviceUsageRecord = {
  deviceId: string;
  sessions: number;
  exports: number;
  totalSeconds: number;
  firstSeen: string;
  lastSeen: string;
  country: string;
  countryCode: string;
  city: string;
  isPro: boolean;
  platforms: string[];
  appVersion: string;
};

/**
 * Per-device usage for the selected range, ranked by total time in the app —
 * the account-less answer to "how long does each user spend, and how much do
 * they export". Export counts are joined in by device id, so a device that
 * exported before the range still shows only what it did inside it.
 */
export async function getDeviceUsage(
  range: AnalyticsRange = "all",
  page = 1,
  pageSize = 25,
): Promise<Paginated<DeviceUsageRecord>> {
  const rf = rangeFilter(range);
  const exportRf = rangeFilter(range, "created_at");
  const { page: safePage, offset } = normalizePage(page, pageSize);
  const empty: Paginated<DeviceUsageRecord> = { rows: [], total: 0, page: safePage, pageSize };
  try {
    const [rows, total] = await Promise.all([
      query<{
        device_key: string;
        sessions: number;
        exports: number;
        total_seconds: number;
        first_seen: Date;
        last_seen: Date;
        country: string | null;
        country_code: string | null;
        city: string | null;
        is_pro: boolean;
        platforms: string[];
        app_version: string | null;
      }>(
        `WITH usage AS (
           SELECT COALESCE(NULLIF(device_id, ''), ip_hash) AS device_key,
                  COUNT(*)::int AS sessions,
                  COALESCE(SUM(duration_seconds), 0)::bigint AS total_seconds,
                  MIN(started_at) AS first_seen,
                  MAX(last_seen_at) AS last_seen,
                  bool_or(is_pro) AS is_pro,
                  (array_agg(country ORDER BY last_seen_at DESC)
                     FILTER (WHERE country <> ''))[1] AS country,
                  (array_agg(country_code ORDER BY last_seen_at DESC)
                     FILTER (WHERE country_code <> ''))[1] AS country_code,
                  (array_agg(city ORDER BY last_seen_at DESC)
                     FILTER (WHERE city <> ''))[1] AS city,
                  (array_agg(app_version ORDER BY last_seen_at DESC)
                     FILTER (WHERE app_version <> ''))[1] AS app_version,
                  array_agg(DISTINCT platform) AS platforms
           FROM admin_sessions
           WHERE ${rf}
           GROUP BY 1
         ), exported AS (
           SELECT device_id AS device_key, COUNT(*)::int AS exports
           FROM admin_exports
           WHERE ${exportRf} AND device_id <> ''
           GROUP BY 1
         )
         SELECT usage.*, COALESCE(exported.exports, 0)::int AS exports
         FROM usage
         LEFT JOIN exported ON exported.device_key = usage.device_key
         ORDER BY total_seconds DESC
         LIMIT $1 OFFSET $2`,
        [pageSize, offset],
      ),
      countDeviceGroups(rf),
    ]);
    return {
      page: safePage,
      pageSize,
      total,
      rows: rows.map((r) => ({
        deviceId: r.device_key,
        sessions: Number(r.sessions) || 0,
        exports: Number(r.exports) || 0,
        totalSeconds: Number(r.total_seconds) || 0,
        firstSeen: new Date(r.first_seen).toISOString(),
        lastSeen: new Date(r.last_seen).toISOString(),
        country: r.country ?? "",
        countryCode: r.country_code ?? "",
        city: r.city ?? "",
        isPro: Boolean(r.is_pro),
        platforms: Array.isArray(r.platforms) ? r.platforms : [],
        appVersion: r.app_version ?? "",
      })),
    };
  } catch (error) {
    void logError({ source: "analytics/getDeviceUsage", error });
    return empty;
  }
}

/** Total number of distinct devices in the range (for pagination). */
async function countDeviceGroups(rangeFilterSql: string): Promise<number> {
  const rows = await query<{ count: number }>(
    `SELECT COUNT(*)::int AS count
     FROM (SELECT 1 FROM admin_sessions WHERE ${rangeFilterSql}
           GROUP BY COALESCE(NULLIF(device_id, ''), ip_hash)) g`,
  );
  return Number(rows[0]?.count) || 0;
}
