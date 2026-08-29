import { query } from "../db";
import { logError } from "../error-log";
import {
  ACTIVE_WINDOW_SECONDS,
  normalizePage,
  rangeFilter,
  type AnalyticsRange,
  type Paginated,
} from "./range";

// --- Dashboard read models ---

export type AnalyticsOverview = {
  totalSessions: number;
  sessionsToday: number;
  activeNow: number;
  /** Distinct installs seen in the range — the closest thing to "people". */
  devices: number;
  newDevices: number;
  proDevices: number;
  totalUsageSeconds: number;
  avgSessionSeconds: number;
};

export type CountryStat = {
  country: string;
  countryCode: string;
  sessions: number;
  devices: number;
  usageSeconds: number;
};

export type PlatformStat = {
  platform: string;
  sessions: number;
  devices: number;
  usageSeconds: number;
};

export async function getAnalyticsOverview(
  range: AnalyticsRange = "all",
): Promise<AnalyticsOverview> {
  const rf = rangeFilter(range);
  try {
    // Subqueries (not FILTER) so range-scoped and absolute metrics coexist:
    // sessions/devices/usage follow the range; today/active-now are always live.
    const rows = await query<{
      total_sessions: number;
      sessions_today: number;
      active_now: number;
      devices: number;
      new_devices: number;
      pro_devices: number;
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
         (SELECT COUNT(DISTINCT device_key)
            FROM (SELECT COALESCE(NULLIF(device_id, ''), ip_hash) AS device_key
                  FROM admin_sessions WHERE ${rf}) d)::int AS devices,
         -- First-ever sighting inside the range == a new install.
         (SELECT COUNT(*) FROM (
            SELECT COALESCE(NULLIF(device_id, ''), ip_hash) AS device_key,
                   MIN(started_at) AS first_seen
            FROM admin_sessions
            GROUP BY 1
          ) f WHERE ${rangeFilter(range, "f.first_seen")})::int AS new_devices,
         (SELECT COUNT(DISTINCT COALESCE(NULLIF(device_id, ''), ip_hash))
            FROM admin_sessions WHERE ${rf} AND is_pro)::int AS pro_devices,
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
      devices: Number(r?.devices) || 0,
      newDevices: Number(r?.new_devices) || 0,
      proDevices: Number(r?.pro_devices) || 0,
      totalUsageSeconds: Number(r?.total_usage) || 0,
      avgSessionSeconds: Number(r?.avg_session) || 0,
    };
  } catch (error) {
    void logError({ source: "analytics/getAnalyticsOverview", error });
    return {
      totalSessions: 0,
      sessionsToday: 0,
      activeNow: 0,
      devices: 0,
      newDevices: 0,
      proDevices: 0,
      totalUsageSeconds: 0,
      avgSessionSeconds: 0,
    };
  }
}

export type DayPoint = {
  /** YYYY-MM-DD */
  day: string;
  sessions: number;
  devices: number;
  exports: number;
  usageSeconds: number;
};

/**
 * Day-by-day activity for the trend chart. Built off a generated date series so
 * quiet days appear as zeroes instead of collapsing the x-axis.
 */
export async function getDailySeries(days = 14): Promise<DayPoint[]> {
  const span = Math.min(Math.max(Math.round(days), 1), 90);
  try {
    const rows = await query<{
      day: Date;
      sessions: number;
      devices: number;
      exports: number;
      usage_seconds: number;
    }>(
      `WITH span AS (
         SELECT generate_series(
           date_trunc('day', now()) - make_interval(days => $1::int - 1),
           date_trunc('day', now()),
           interval '1 day'
         ) AS day
       )
       SELECT span.day,
              COALESCE(s.sessions, 0)::int AS sessions,
              COALESCE(s.devices, 0)::int AS devices,
              COALESCE(e.exports, 0)::int AS exports,
              COALESCE(s.usage_seconds, 0)::bigint AS usage_seconds
       FROM span
       LEFT JOIN (
         SELECT date_trunc('day', started_at) AS day,
                COUNT(*) AS sessions,
                COUNT(DISTINCT COALESCE(NULLIF(device_id, ''), ip_hash)) AS devices,
                COALESCE(SUM(duration_seconds), 0) AS usage_seconds
         FROM admin_sessions
         GROUP BY 1
       ) s ON s.day = span.day
       LEFT JOIN (
         SELECT date_trunc('day', created_at) AS day, COUNT(*) AS exports
         FROM admin_exports
         GROUP BY 1
       ) e ON e.day = span.day
       ORDER BY span.day ASC`,
      [span],
    );
    return rows.map((r) => ({
      day: new Date(r.day).toISOString().slice(0, 10),
      sessions: Number(r.sessions) || 0,
      devices: Number(r.devices) || 0,
      exports: Number(r.exports) || 0,
      usageSeconds: Number(r.usage_seconds) || 0,
    }));
  } catch (error) {
    void logError({ source: "analytics/getDailySeries", error });
    return [];
  }
}

export async function getCountryStats(
  range: AnalyticsRange = "all",
  limit = 30,
): Promise<CountryStat[]> {
  return (await getCountryPage(range, 1, limit)).rows;
}

/** Countries by session count, one page at a time. */
export async function getCountryPage(
  range: AnalyticsRange = "all",
  page = 1,
  pageSize = 20,
): Promise<Paginated<CountryStat>> {
  const rf = rangeFilter(range);
  const { page: safePage, offset } = normalizePage(page, pageSize);
  try {
    const [rows, totals] = await Promise.all([
      query<{
        country: string;
        country_code: string;
        sessions: number;
        devices: number;
        usage_seconds: number;
      }>(
        `SELECT
           CASE WHEN country = '' THEN 'Unknown' ELSE country END AS country,
           country_code,
           COUNT(*)::int AS sessions,
           COUNT(DISTINCT COALESCE(NULLIF(device_id, ''), ip_hash))::int AS devices,
           COALESCE(SUM(duration_seconds), 0)::bigint AS usage_seconds
         FROM admin_sessions
         WHERE ${rf}
         GROUP BY country, country_code
         ORDER BY sessions DESC
         LIMIT $1 OFFSET $2`,
        [pageSize, offset],
      ),
      query<{ count: number }>(
        `SELECT COUNT(*)::int AS count
         FROM (SELECT 1 FROM admin_sessions WHERE ${rf}
               GROUP BY country, country_code) g`,
      ),
    ]);
    return {
      rows: rows.map((r) => ({
        country: r.country,
        countryCode: r.country_code,
        sessions: Number(r.sessions) || 0,
        devices: Number(r.devices) || 0,
        usageSeconds: Number(r.usage_seconds) || 0,
      })),
      total: Number(totals[0]?.count) || 0,
      page: safePage,
      pageSize,
    };
  } catch (error) {
    void logError({ source: "analytics/getCountryPage", error });
    return { rows: [], total: 0, page: safePage, pageSize };
  }
}


export async function getPlatformStats(
  range: AnalyticsRange = "all",
): Promise<PlatformStat[]> {
  try {
    const rows = await query<{
      platform: string;
      sessions: number;
      devices: number;
      usage_seconds: number;
    }>(
      `SELECT platform,
              COUNT(*)::int AS sessions,
              COUNT(DISTINCT COALESCE(NULLIF(device_id, ''), ip_hash))::int AS devices,
              COALESCE(SUM(duration_seconds), 0)::bigint AS usage_seconds
       FROM admin_sessions
       WHERE ${rangeFilter(range)}
       GROUP BY platform
       ORDER BY sessions DESC`,
    );
    return rows.map((r) => ({
      platform: r.platform,
      sessions: Number(r.sessions) || 0,
      devices: Number(r.devices) || 0,
      usageSeconds: Number(r.usage_seconds) || 0,
    }));
  } catch (error) {
    void logError({ source: "analytics/getPlatformStats", error });
    return [];
  }
}

export type ScreenStat = {
  screen: string;
  views: number;
  devices: number;
};

/** Most-viewed screens/features in the selected range. */
export async function getTopScreens(
  range: AnalyticsRange = "all",
  limit = 15,
): Promise<ScreenStat[]> {
  return (await getScreenPage(range, 1, limit)).rows;
}

/** Screens by view count, one page at a time — the list is unbounded. */
export async function getScreenPage(
  range: AnalyticsRange = "all",
  page = 1,
  pageSize = 12,
): Promise<Paginated<ScreenStat>> {
  const rf = rangeFilter(range, "created_at");
  const { page: safePage, offset } = normalizePage(page, pageSize);
  try {
    const [rows, totals] = await Promise.all([
      query<{ screen: string; views: number; devices: number }>(
        `SELECT screen,
                COUNT(*)::int AS views,
                COUNT(DISTINCT COALESCE(NULLIF(device_id, ''), client_id))::int AS devices
         FROM admin_screen_views
         WHERE ${rf}
         GROUP BY screen
         ORDER BY views DESC
         LIMIT $1 OFFSET $2`,
        [pageSize, offset],
      ),
      query<{ count: number }>(
        `SELECT COUNT(*)::int AS count
         FROM (SELECT 1 FROM admin_screen_views WHERE ${rf} GROUP BY screen) g`,
      ),
    ]);
    return {
      rows: rows.map((r) => ({
        screen: r.screen,
        views: Number(r.views) || 0,
        devices: Number(r.devices) || 0,
      })),
      total: Number(totals[0]?.count) || 0,
      page: safePage,
      pageSize,
    };
  } catch (error) {
    void logError({ source: "analytics/getScreenPage", error });
    return { rows: [], total: 0, page: safePage, pageSize };
  }
}

