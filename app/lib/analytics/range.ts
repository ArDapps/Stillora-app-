// A session is considered "active" if it has sent a heartbeat within this window.
export const ACTIVE_WINDOW_SECONDS = 90;

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
 * SQL boolean limiting a timestamp column to the selected range. The range keys
 * and column name come from fixed sets (never user text), so inlining is safe.
 */
export function rangeFilter(range: AnalyticsRange, column = "started_at"): string {
  switch (range) {
    case "today":
      return `${column} >= date_trunc('day', now())`;
    case "7d":
      return `${column} >= now() - make_interval(days => 7)`;
    case "30d":
      return `${column} >= now() - make_interval(days => 30)`;
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
