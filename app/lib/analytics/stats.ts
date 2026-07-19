import { query } from "../db";
import { ACTIVE_WINDOW_SECONDS, rangeFilter, type AnalyticsRange } from "./range";

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

export type ScreenStat = {
  screen: string;
  views: number;
  users: number;
};

/** Most-viewed screens/features in the selected range. */
export async function getTopScreens(
  range: AnalyticsRange = "all",
  limit = 15,
): Promise<ScreenStat[]> {
  try {
    const rows = await query<{ screen: string; views: number; users: number }>(
      `SELECT screen,
              COUNT(*)::int AS views,
              COUNT(DISTINCT COALESCE(user_sub, client_id))::int AS users
       FROM admin_screen_views
       WHERE ${rangeFilter(range, "created_at")}
       GROUP BY screen
       ORDER BY views DESC
       LIMIT $1`,
      [limit],
    );
    return rows.map((r) => ({
      screen: r.screen,
      views: Number(r.views) || 0,
      users: Number(r.users) || 0,
    }));
  } catch (error) {
    console.error("getTopScreens failed:", error);
    return [];
  }
}
