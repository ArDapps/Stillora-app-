/**
 * Barrel for the analytics store. The implementation lives in `lib/analytics/`:
 *   - `device.ts`   — platform / user-agent / IP normalization helpers
 *   - `track.ts`    — write path (live sessions, screen views, batched sessions)
 *   - `range.ts`    — range keys, SQL range filters, pagination helpers
 *   - `stats.ts`    — dashboard aggregates (overview, trend, countries, platforms, screens)
 *   - `sessions.ts` — paginated session and per-device usage read models
 *
 * Everything is keyed by device, not by account: Stillora ships without sign-in.
 */

export type { TrackEvent, TrackInput, BatchSessionInput } from "./analytics/track";
export { trackSession, recordScreenView, trackBatchSession } from "./analytics/track";

export type { AnalyticsRange, Paginated } from "./analytics/range";
export { ANALYTICS_RANGES, normalizeRange, normalizePage } from "./analytics/range";

export type {
  AnalyticsOverview,
  CountryStat,
  DayPoint,
  PlatformStat,
  ScreenStat,
} from "./analytics/stats";
export {
  getAnalyticsOverview,
  getCountryPage,
  getCountryStats,
  getDailySeries,
  getPlatformStats,
  getScreenPage,
  getTopScreens,
} from "./analytics/stats";

export type { SessionRecord, DeviceUsageRecord } from "./analytics/sessions";
export { getRecentSessions, getDeviceUsage } from "./analytics/sessions";
