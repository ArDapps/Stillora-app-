import { query } from "./db";
import { logError } from "./error-log";
import { normalizePage, rangeFilter, type AnalyticsRange, type Paginated } from "./analytics/range";

/**
 * Export telemetry. Stillora has no accounts, so an export belongs to a
 * *device*, not a person: `deviceId` is the stable per-install id the client
 * sends with every beacon. The `user*` fields only ever hold data from rows
 * written back when sign-in still existed.
 */
export type ExportRecord = {
  id: string;
  deviceId: string;
  platform: string;
  /** Which tool produced it: create, html, loop, watermark, silence, speed… */
  tool: string;
  presetId: string;
  duration: number;
  timestamp: string;
};

type ExportRow = {
  id: string;
  device_id: string;
  platform: string;
  tool: string;
  preset_id: string;
  duration: number;
  created_at: Date;
};

function toIso(value: Date | string): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}

function mapExport(row: ExportRow): ExportRecord {
  return {
    id: row.id,
    deviceId: row.device_id,
    platform: row.platform,
    tool: row.tool || "create",
    presetId: row.preset_id,
    duration: Number(row.duration) || 0,
    timestamp: toIso(row.created_at),
  };
}

/** Records one completed export. Fire-and-forget: never fails the export. */
export async function recordExport(input: {
  deviceId: string;
  platform: string;
  tool: string;
  presetId: string;
  duration: number;
}): Promise<void> {
  try {
    await query(
      `INSERT INTO admin_exports (device_id, platform, tool, preset_id, duration)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        input.deviceId.slice(0, 100),
        input.platform.slice(0, 40),
        (input.tool || "create").slice(0, 40),
        input.presetId.slice(0, 80),
        Math.max(0, Math.round(input.duration)),
      ],
    );
  } catch (error) {
    void logError({ source: "admin-store/recordExport", error, platform: input.platform });
  }
}

export type ExportStats = {
  total: number;
  today: number;
  inRange: number;
  devices: number;
  totalVideoSeconds: number;
  avgDurationSeconds: number;
};

/** Headline export counters. `total`/`today` are absolute; the rest follow the range. */
export async function getExportStats(range: AnalyticsRange = "all"): Promise<ExportStats> {
  const rf = rangeFilter(range, "created_at");
  try {
    const rows = await query<{
      total: number;
      today: number;
      in_range: number;
      devices: number;
      video_seconds: number;
      avg_duration: number;
    }>(
      `SELECT
         (SELECT COUNT(*) FROM admin_exports)::int AS total,
         (SELECT COUNT(*) FROM admin_exports
            WHERE created_at >= date_trunc('day', now()))::int AS today,
         (SELECT COUNT(*) FROM admin_exports WHERE ${rf})::int AS in_range,
         (SELECT COUNT(DISTINCT device_id) FROM admin_exports
            WHERE ${rf} AND device_id <> '')::int AS devices,
         (SELECT COALESCE(SUM(duration), 0) FROM admin_exports WHERE ${rf})::bigint AS video_seconds,
         (SELECT COALESCE(AVG(duration), 0) FROM admin_exports WHERE ${rf})::int AS avg_duration`,
    );
    const r = rows[0];
    return {
      total: Number(r?.total) || 0,
      today: Number(r?.today) || 0,
      inRange: Number(r?.in_range) || 0,
      devices: Number(r?.devices) || 0,
      totalVideoSeconds: Number(r?.video_seconds) || 0,
      avgDurationSeconds: Number(r?.avg_duration) || 0,
    };
  } catch (error) {
    void logError({ source: "admin-store/getExportStats", error });
    return { total: 0, today: 0, inRange: 0, devices: 0, totalVideoSeconds: 0, avgDurationSeconds: 0 };
  }
}

export async function getRecentExports(limit = 20): Promise<ExportRecord[]> {
  try {
    const rows = await query<ExportRow>(
      `SELECT id, device_id, platform, tool, preset_id, duration, created_at
       FROM admin_exports
       ORDER BY created_at DESC
       LIMIT $1`,
      [limit],
    );
    return rows.map(mapExport);
  } catch (error) {
    void logError({ source: "admin-store/getRecentExports", error });
    return [];
  }
}

/** One page of exports for the selected range, newest first. */
export async function getExportsPage(
  range: AnalyticsRange = "all",
  page = 1,
  pageSize = 25,
): Promise<Paginated<ExportRecord>> {
  const rf = rangeFilter(range, "created_at");
  const { page: safePage, offset } = normalizePage(page, pageSize);
  try {
    const [rows, totals] = await Promise.all([
      query<ExportRow>(
        `SELECT id, device_id, platform, tool, preset_id, duration, created_at
         FROM admin_exports
         WHERE ${rf}
         ORDER BY created_at DESC
         LIMIT $1 OFFSET $2`,
        [pageSize, offset],
      ),
      query<{ count: number }>(`SELECT COUNT(*)::int AS count FROM admin_exports WHERE ${rf}`),
    ]);
    return {
      rows: rows.map(mapExport),
      total: Number(totals[0]?.count) || 0,
      page: safePage,
      pageSize,
    };
  } catch (error) {
    void logError({ source: "admin-store/getExportsPage", error });
    return { rows: [], total: 0, page: safePage, pageSize };
  }
}

export type ToolStat = {
  tool: string;
  exports: number;
  devices: number;
  videoSeconds: number;
};

/** Which tool people actually export from, ranked. */
export async function getToolStats(range: AnalyticsRange = "all"): Promise<ToolStat[]> {
  try {
    const rows = await query<{
      tool: string;
      exports: number;
      devices: number;
      video_seconds: number;
    }>(
      `SELECT COALESCE(NULLIF(tool, ''), 'create') AS tool,
              COUNT(*)::int AS exports,
              COUNT(DISTINCT device_id)::int AS devices,
              COALESCE(SUM(duration), 0)::bigint AS video_seconds
       FROM admin_exports
       WHERE ${rangeFilter(range, "created_at")}
       GROUP BY 1
       ORDER BY exports DESC`,
    );
    return rows.map((r) => ({
      tool: r.tool,
      exports: Number(r.exports) || 0,
      devices: Number(r.devices) || 0,
      videoSeconds: Number(r.video_seconds) || 0,
    }));
  } catch (error) {
    void logError({ source: "admin-store/getToolStats", error });
    return [];
  }
}

export type PresetStat = { presetId: string; exports: number };

/** Most-used aspect-ratio presets, for the overview breakdown. */
export async function getPresetStats(range: AnalyticsRange = "all", limit = 8): Promise<PresetStat[]> {
  try {
    const rows = await query<{ preset_id: string; exports: number }>(
      `SELECT preset_id, COUNT(*)::int AS exports
       FROM admin_exports
       WHERE ${rangeFilter(range, "created_at")}
       GROUP BY preset_id
       ORDER BY exports DESC
       LIMIT $1`,
      [limit],
    );
    return rows.map((r) => ({ presetId: r.preset_id || "unknown", exports: Number(r.exports) || 0 }));
  } catch (error) {
    void logError({ source: "admin-store/getPresetStats", error });
    return [];
  }
}
