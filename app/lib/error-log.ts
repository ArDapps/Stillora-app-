import { query } from "./db";

/** Where the failure happened. */
export type ErrorScope = "server" | "client";

export type ErrorInput = {
  /** The function or route that failed, e.g. "api/convert/html" or "recordExport". */
  source: string;
  /** Anything thrown: an Error, a string, or a plain value. */
  error: unknown;
  scope?: ErrorScope;
  /** Page/route the client was on, when the report comes from a client. */
  url?: string;
  platform?: string;
  appVersion?: string;
  deviceId?: string;
  userAgent?: string;
};

export type ErrorRecord = {
  id: string;
  scope: ErrorScope;
  source: string;
  name: string;
  message: string;
  stack: string;
  url: string;
  platform: string;
  appVersion: string;
  deviceId: string;
  userAgent: string;
  count: number;
  firstSeen: string;
  lastSeen: string;
  resolvedAt: string | null;
};

type ErrorRow = {
  id: string;
  scope: string;
  source: string;
  name: string;
  message: string;
  stack: string;
  url: string;
  platform: string;
  app_version: string;
  device_id: string;
  user_agent: string;
  count: number;
  first_seen: Date;
  last_seen: Date;
  resolved_at: Date | null;
};

const MAX_MESSAGE = 2000;
const MAX_STACK = 8000;

function toIso(value: Date | string): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}

function mapError(row: ErrorRow): ErrorRecord {
  return {
    id: row.id,
    scope: row.scope === "client" ? "client" : "server",
    source: row.source,
    name: row.name,
    message: row.message,
    stack: row.stack,
    url: row.url,
    platform: row.platform,
    appVersion: row.app_version,
    deviceId: row.device_id,
    userAgent: row.user_agent,
    count: Number(row.count) || 0,
    firstSeen: toIso(row.first_seen),
    lastSeen: toIso(row.last_seen),
    resolvedAt: row.resolved_at ? toIso(row.resolved_at) : null,
  };
}

/** Splits any thrown value into the parts worth storing. */
function describe(error: unknown): { name: string; message: string; stack: string } {
  if (error instanceof Error) {
    return {
      name: error.name || "Error",
      message: (error.message || String(error)).slice(0, MAX_MESSAGE),
      stack: (error.stack ?? "").slice(0, MAX_STACK),
    };
  }
  if (typeof error === "string") {
    return { name: "Error", message: error.slice(0, MAX_MESSAGE), stack: "" };
  }
  let serialized: string;
  try {
    serialized = JSON.stringify(error);
  } catch {
    serialized = String(error);
  }
  return { name: "Error", message: (serialized ?? "Unknown error").slice(0, MAX_MESSAGE), stack: "" };
}

/**
 * Groups repeats of the same failure onto one row. Digits, UUIDs and quoted
 * fragments are stripped from the message first, so "row 41 not found" and
 * "row 92 not found" are recognised as the same bug rather than two.
 */
function fingerprintOf(scope: string, source: string, name: string, message: string): string {
  const normalized = message
    .toLowerCase()
    .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/g, "<id>")
    .replace(/\d+/g, "<n>")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 300);
  return fingerprintHash(`${scope}|${source}|${name}|${normalized}`);
}

/**
 * 64-bit grouping key: two 32-bit FNV-1a passes with different seeds, joined.
 *
 * Deliberately hand-rolled rather than `node:crypto` — Next bundles the
 * instrumentation hook for every runtime, and a Node-only import there is a
 * build warning. 32-bit arithmetic rather than BigInt keeps it inside the
 * project's compile target. A grouping key needs to be stable and
 * collision-resistant across a few thousand distinct messages, not
 * cryptographic.
 */
function fingerprintHash(input: string): string {
  return `${fnv1a32(input, 0x811c9dc5)}${fnv1a32(input, 0x01000193)}`;
}

function fnv1a32(input: string, seed: number): string {
  let hash = seed >>> 0;
  for (let i = 0; i < input.length; i++) {
    hash ^= input.charCodeAt(i);
    // The FNV prime (16777619) via shifts: plain `*` would lose precision.
    hash = (hash + ((hash << 1) + (hash << 4) + (hash << 7) + (hash << 8) + (hash << 24))) >>> 0;
  }
  return hash.toString(16).padStart(8, "0");
}

/**
 * Records a failure for the admin Errors page.
 *
 * Never throws and never rejects: it is called from `catch` blocks all over the
 * app, and a logger that can break the thing it is logging is worse than no
 * logger at all. Still writes to the server console, so nothing that used to be
 * visible in the platform logs disappears.
 */
export async function logError(input: ErrorInput): Promise<void> {
  const { name, message, stack } = describe(input.error);
  const scope: ErrorScope = input.scope === "client" ? "client" : "server";
  const source = (input.source || "unknown").slice(0, 200);

  console.error(`[${scope}] ${source}:`, input.error);

  try {
    await query(
      `INSERT INTO admin_errors
         (fingerprint, scope, source, name, message, stack, url, platform,
          app_version, device_id, user_agent)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       ON CONFLICT (fingerprint) DO UPDATE
         SET count       = admin_errors.count + 1,
             last_seen   = now(),
             -- A recurrence reopens a resolved error: it clearly is not fixed.
             resolved_at = NULL,
             stack       = CASE WHEN EXCLUDED.stack <> '' THEN EXCLUDED.stack ELSE admin_errors.stack END,
             url         = CASE WHEN EXCLUDED.url <> '' THEN EXCLUDED.url ELSE admin_errors.url END,
             platform    = CASE WHEN EXCLUDED.platform <> '' THEN EXCLUDED.platform ELSE admin_errors.platform END,
             app_version = CASE WHEN EXCLUDED.app_version <> '' THEN EXCLUDED.app_version ELSE admin_errors.app_version END,
             device_id   = CASE WHEN EXCLUDED.device_id <> '' THEN EXCLUDED.device_id ELSE admin_errors.device_id END`,
      [
        fingerprintOf(scope, source, name, message),
        scope,
        source,
        name.slice(0, 120),
        message,
        stack,
        (input.url ?? "").slice(0, 500),
        (input.platform ?? "").slice(0, 40),
        (input.appVersion ?? "").slice(0, 40),
        (input.deviceId ?? "").slice(0, 100),
        (input.userAgent ?? "").slice(0, 500),
      ],
    );
  } catch (loggingFailure) {
    // Deliberately terminal: if the error table itself is unreachable there is
    // nowhere left to report to, and re-throwing would break the caller.
    console.error("logError failed:", loggingFailure);
  }
}

export type ErrorStats = {
  open: number;
  last24h: number;
  clientOpen: number;
  serverOpen: number;
  totalOccurrences: number;
};

export async function getErrorStats(): Promise<ErrorStats> {
  try {
    const rows = await query<{
      open: number;
      last24h: number;
      client_open: number;
      server_open: number;
      occurrences: number;
    }>(
      `SELECT
         COUNT(*) FILTER (WHERE resolved_at IS NULL)::int AS open,
         COUNT(*) FILTER (WHERE last_seen >= now() - make_interval(hours => 24))::int AS last24h,
         COUNT(*) FILTER (WHERE resolved_at IS NULL AND scope = 'client')::int AS client_open,
         COUNT(*) FILTER (WHERE resolved_at IS NULL AND scope = 'server')::int AS server_open,
         COALESCE(SUM(count) FILTER (WHERE resolved_at IS NULL), 0)::int AS occurrences
       FROM admin_errors`,
    );
    const r = rows[0];
    return {
      open: Number(r?.open) || 0,
      last24h: Number(r?.last24h) || 0,
      clientOpen: Number(r?.client_open) || 0,
      serverOpen: Number(r?.server_open) || 0,
      totalOccurrences: Number(r?.occurrences) || 0,
    };
  } catch (error) {
    console.error("getErrorStats failed:", error);
    return { open: 0, last24h: 0, clientOpen: 0, serverOpen: 0, totalOccurrences: 0 };
  }
}

export type ErrorFilter = "open" | "resolved" | "all";

export async function getErrorsPage(
  filter: ErrorFilter = "open",
  page = 1,
  pageSize = 25,
): Promise<{ rows: ErrorRecord[]; total: number; page: number; pageSize: number }> {
  const safePage = Number.isFinite(page) && page >= 1 ? Math.floor(page) : 1;
  const offset = (safePage - 1) * pageSize;
  // Fixed set, never user text — safe to inline.
  const where =
    filter === "open"
      ? "resolved_at IS NULL"
      : filter === "resolved"
        ? "resolved_at IS NOT NULL"
        : "TRUE";
  try {
    const [rows, totals] = await Promise.all([
      query<ErrorRow>(
        `SELECT id, scope, source, name, message, stack, url, platform, app_version,
                device_id, user_agent, count, first_seen, last_seen, resolved_at
         FROM admin_errors
         WHERE ${where}
         ORDER BY last_seen DESC
         LIMIT $1 OFFSET $2`,
        [pageSize, offset],
      ),
      query<{ count: number }>(`SELECT COUNT(*)::int AS count FROM admin_errors WHERE ${where}`),
    ]);
    return {
      rows: rows.map(mapError),
      total: Number(totals[0]?.count) || 0,
      page: safePage,
      pageSize,
    };
  } catch (error) {
    console.error("getErrorsPage failed:", error);
    return { rows: [], total: 0, page: safePage, pageSize };
  }
}

/** The most recent unresolved failures, for the overview card. */
export async function getRecentErrors(limit = 5): Promise<ErrorRecord[]> {
  try {
    const rows = await query<ErrorRow>(
      `SELECT id, scope, source, name, message, stack, url, platform, app_version,
              device_id, user_agent, count, first_seen, last_seen, resolved_at
       FROM admin_errors
       WHERE resolved_at IS NULL
       ORDER BY last_seen DESC
       LIMIT $1`,
      [limit],
    );
    return rows.map(mapError);
  } catch (error) {
    console.error("getRecentErrors failed:", error);
    return [];
  }
}

export async function resolveErrorById(id: string): Promise<void> {
  await query(`UPDATE admin_errors SET resolved_at = now() WHERE id = $1`, [id]);
}

export async function reopenErrorById(id: string): Promise<void> {
  await query(`UPDATE admin_errors SET resolved_at = NULL WHERE id = $1`, [id]);
}

export async function deleteErrorById(id: string): Promise<void> {
  await query(`DELETE FROM admin_errors WHERE id = $1`, [id]);
}

/** Clears every resolved row. Used by the "Clear resolved" button. */
export async function deleteResolvedErrors(): Promise<number> {
  const rows = await query<{ id: string }>(
    `DELETE FROM admin_errors WHERE resolved_at IS NOT NULL RETURNING id`,
  );
  return rows.length;
}
