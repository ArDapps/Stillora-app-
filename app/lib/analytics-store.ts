/**
 * Barrel for the analytics store. The implementation lives in `lib/analytics/`:
 *   - `device.ts`   — platform / user-agent / IP normalization helpers
 *   - `track.ts`    — write path (live sessions, screen views, batched sessions)
 *   - `range.ts`    — range keys, SQL range filters, pagination helpers
 *   - `stats.ts`    — dashboard aggregates (overview, countries, platforms, screens)
 *   - `sessions.ts` — paginated session and per-user usage read models
 */

export type { TrackEvent, TrackInput, BatchSessionInput } from "./analytics/track";
export { trackSession, recordScreenView, trackBatchSession } from "./analytics/track";

export type { AnalyticsRange, Paginated } from "./analytics/range";
export { ANALYTICS_RANGES, normalizeRange, normalizePage } from "./analytics/range";

export type {
  AnalyticsOverview,
  CountryStat,
  PlatformStat,
  ScreenStat,
} from "./analytics/stats";
export {
  getAnalyticsOverview,
  getCountryStats,
  getPlatformStats,
  getTopScreens,
} from "./analytics/stats";

export type { SessionRecord, UserUsageRecord } from "./analytics/sessions";
export { getRecentSessions, getUserUsage } from "./analytics/sessions";
