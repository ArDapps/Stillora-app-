import { query } from "./db";
import { logError } from "./error-log";

/**
 * How long analytics are kept.
 *
 * Six months is enough to compare a season against the one before it; past
 * that the rows answer no question anyone asks and are just personal-ish data
 * (hashed IPs, device ids, coarse location) sitting on disk. Deleting them is
 * the privacy-preserving default, and it keeps the dashboard's queries fast.
 */
export const RETENTION_DAYS = 180;

/** At most one purge a day — the work is identical however often it runs. */
const PURGE_INTERVAL_HOURS = 24;

export type PurgeResult = {
  sessions: number;
  screenViews: number;
  exports: number;
  errors: number;
};

async function deleteWhere(sql: string): Promise<number> {
  const rows = await query<Record<string, unknown>>(sql);
  return rows.length;
}

/**
 * Deletes everything older than the retention window.
 *
 * Unresolved errors are kept regardless of age: a bug nobody has looked at is
 * still a bug, and its `last_seen` moves forward every time it recurs, so a
 * genuinely dead one ages out on its own once resolved.
 */
export async function purgeExpiredData(): Promise<PurgeResult> {
  const cutoff = `now() - make_interval(days => ${RETENTION_DAYS})`;

  const [sessions, screenViews, exportRows, errors] = await Promise.all([
    deleteWhere(`DELETE FROM admin_sessions WHERE last_seen_at < ${cutoff} RETURNING 1`),
    deleteWhere(`DELETE FROM admin_screen_views WHERE created_at < ${cutoff} RETURNING 1`),
    deleteWhere(`DELETE FROM admin_exports WHERE created_at < ${cutoff} RETURNING 1`),
    deleteWhere(
      `DELETE FROM admin_errors
        WHERE last_seen < ${cutoff} AND resolved_at IS NOT NULL
        RETURNING 1`,
    ),
    // Geo cache rows are rebuilt on demand; stale ones are pure waste.
    deleteWhere(`DELETE FROM admin_geo_cache WHERE fetched_at < ${cutoff} RETURNING 1`),
  ]);

  return { sessions, screenViews, exports: exportRows, errors };
}

/**
 * Runs a purge if one has not run in the last day.
 *
 * The marker lives in the database rather than in memory so several instances —
 * or a process that restarts hourly — still purge once a day between them. The
 * upsert claims the run atomically, so two instances waking together cannot
 * both do the work. Safe to call from a hot path, and it never throws.
 */
export async function maybePurge(): Promise<PurgeResult | null> {
  try {
    const claimed = await query<{ id: string }>(
      `INSERT INTO admin_maintenance (id, last_purge_at)
       VALUES ('purge', now())
       ON CONFLICT (id) DO UPDATE
         SET last_purge_at = now()
         WHERE admin_maintenance.last_purge_at
               < now() - make_interval(hours => ${PURGE_INTERVAL_HOURS})
       RETURNING id`,
    );
    if (claimed.length === 0) return null;

    return await purgeExpiredData();
  } catch (error) {
    void logError({ source: "retention/maybePurge", error });
    return null;
  }
}

/** When the last purge ran, for the admin panel to show. */
export async function getLastPurgeAt(): Promise<string | null> {
  try {
    const rows = await query<{ last_purge_at: Date }>(
      `SELECT last_purge_at FROM admin_maintenance WHERE id = 'purge'`,
    );
    const value = rows[0]?.last_purge_at;
    return value ? new Date(value).toISOString() : null;
  } catch (error) {
    void logError({ source: "retention/getLastPurgeAt", error });
    return null;
  }
}
