import { query } from "../db";
import { logError } from "../error-log";
import type { GeoLocation } from "../geo";
import { hashIp, normalizePlatform, parseUserAgent } from "./device";

export type TrackEvent = "start" | "heartbeat" | "end";

export type TrackInput = {
  clientId: string;
  /** Stable per-install id. Stillora has no accounts, so this is the "who". */
  deviceId: string;
  event: TrackEvent;
  platform: string;
  appVersion: string;
  /** Whether the device currently holds the lifetime Pro unlock. */
  isPro: boolean;
  geo: GeoLocation;
  ip: string;
  userAgent: string;
};

/**
 * Upserts a usage session. `start` creates (or refreshes) the row and fills in
 * location/device details; `heartbeat`/`end` just extend the duration. Errors
 * are swallowed so tracking never breaks the app.
 */
export async function trackSession(input: TrackInput): Promise<void> {
  const clientId = input.clientId.trim();
  if (!clientId) return;

  const platform = normalizePlatform(input.platform);
  const { os, browser, device } = parseUserAgent(input.userAgent);
  const ipHash = hashIp(input.ip);
  // Falls back to the hashed IP so anonymous web visitors still count as one
  // device across reloads instead of inflating the device total.
  const deviceId = (input.deviceId.trim() || ipHash).slice(0, 100);
  const endedClause = input.event === "end" ? "now()" : "NULL";

  try {
    if (input.event === "start") {
      await query(
        `INSERT INTO admin_sessions
           (client_id, platform, app_version,
            country, country_code, region, city, os, browser, device, user_agent,
            ip_hash, device_id, is_pro, started_at, last_seen_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14, now(), now())
         ON CONFLICT (client_id) DO UPDATE
           SET last_seen_at = now(),
               ended_at = NULL,
               -- Fill geo fields in once we learn them.
               country      = CASE WHEN admin_sessions.country = '' THEN EXCLUDED.country ELSE admin_sessions.country END,
               country_code = CASE WHEN admin_sessions.country_code = '' THEN EXCLUDED.country_code ELSE admin_sessions.country_code END,
               region       = CASE WHEN admin_sessions.region = '' THEN EXCLUDED.region ELSE admin_sessions.region END,
               city         = CASE WHEN admin_sessions.city = '' THEN EXCLUDED.city ELSE admin_sessions.city END,
               app_version  = CASE WHEN EXCLUDED.app_version <> '' THEN EXCLUDED.app_version ELSE admin_sessions.app_version END,
               device_id    = CASE WHEN EXCLUDED.device_id <> '' THEN EXCLUDED.device_id ELSE admin_sessions.device_id END,
               -- Pro can be bought mid-session; it never un-buys itself.
               is_pro       = admin_sessions.is_pro OR EXCLUDED.is_pro,
               duration_seconds = GREATEST(admin_sessions.duration_seconds,
                 CAST(EXTRACT(EPOCH FROM (now() - admin_sessions.started_at)) AS INTEGER))`,
        [
          clientId,
          platform,
          input.appVersion,
          input.geo.country,
          input.geo.countryCode,
          input.geo.region,
          input.geo.city,
          os,
          browser,
          device,
          input.userAgent.slice(0, 500),
          ipHash,
          deviceId,
          input.isPro,
        ],
      );
      return;
    }

    // heartbeat / end: extend the live session; only touch rows we already have.
    await query(
      `UPDATE admin_sessions
         SET last_seen_at = now(),
             ended_at = ${endedClause},
             device_id = CASE WHEN admin_sessions.device_id = '' THEN $2 ELSE admin_sessions.device_id END,
             is_pro = admin_sessions.is_pro OR $3,
             duration_seconds = CAST(EXTRACT(EPOCH FROM (now() - started_at)) AS INTEGER)
       WHERE client_id = $1`,
      [clientId, deviceId, input.isPro],
    );
  } catch (error) {
    void logError({ source: "analytics/trackSession", error, platform });
  }
}

const MAX_SCREEN_LEN = 120;

/** Records a single screen/feature view. Fire-and-forget like the rest. */
export async function recordScreenView(input: {
  clientId: string;
  deviceId: string;
  platform: string;
  screen: string;
}): Promise<void> {
  const screen = input.screen.trim().slice(0, MAX_SCREEN_LEN);
  if (!screen) return;
  try {
    await query(
      `INSERT INTO admin_screen_views (client_id, device_id, platform, screen)
       VALUES ($1, $2, $3, $4)`,
      [
        input.clientId.trim().slice(0, 100),
        input.deviceId.trim().slice(0, 100),
        normalizePlatform(input.platform),
        screen,
      ],
    );
  } catch (error) {
    void logError({ source: "analytics/recordScreenView", error });
  }
}

// Guards a bad client clock from inflating total time-used with one giant session.
const MAX_BATCH_SESSION_SECONDS = 24 * 60 * 60;

export type BatchSessionInput = {
  clientId: string;
  deviceId: string;
  isPro: boolean;
  /** ISO 8601 timestamp measured on the client when the session opened. */
  startedAt: string;
  /** Seconds the app was actually in the foreground, measured on the client. */
  durationSeconds: number;
  platform: string;
  appVersion: string;
  screens: string[];
  geo: GeoLocation;
  ip: string;
  userAgent: string;
};

/**
 * Ingests one already-completed session that a client buffered locally and
 * flushed later. Mobile/desktop clients batch their usage and POST it about
 * every 12h instead of sending live heartbeats, so — unlike {@link trackSession}
 * — the duration and timing come from the client, not the server clock (the
 * session is long over by the time it arrives). Each buffered session carries a
 * unique client id, so rows never collide; the upsert only makes retries safe.
 */
export async function trackBatchSession(input: BatchSessionInput): Promise<void> {
  const clientId = input.clientId.trim().slice(0, 100);
  if (!clientId) return;

  const started = new Date(input.startedAt);
  if (Number.isNaN(started.getTime())) return;

  const now = Date.now();
  // Clamp to a sane window: never in the future, never older than 30 days.
  const startedMs = Math.min(Math.max(started.getTime(), now - 30 * 86_400_000), now);
  const duration = Math.round(
    Math.min(Math.max(input.durationSeconds, 0), MAX_BATCH_SESSION_SECONDS),
  );
  const startedIso = new Date(startedMs).toISOString();
  const endedIso = new Date(startedMs + duration * 1000).toISOString();

  const platform = normalizePlatform(input.platform);
  const { os, browser, device } = parseUserAgent(input.userAgent);
  const ipHash = hashIp(input.ip);
  const deviceId = (input.deviceId.trim() || ipHash).slice(0, 100);

  try {
    await query(
      `INSERT INTO admin_sessions
         (client_id, platform, app_version,
          country, country_code, region, city, os, browser, device, user_agent,
          ip_hash, started_at, last_seen_at, ended_at, duration_seconds,
          device_id, is_pro)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$13,$14,$15,$16,$17)
       ON CONFLICT (client_id) DO UPDATE
         SET duration_seconds = GREATEST(admin_sessions.duration_seconds, EXCLUDED.duration_seconds),
             last_seen_at = GREATEST(admin_sessions.last_seen_at, EXCLUDED.last_seen_at),
             ended_at = EXCLUDED.ended_at,
             device_id = CASE WHEN EXCLUDED.device_id <> '' THEN EXCLUDED.device_id ELSE admin_sessions.device_id END,
             is_pro = admin_sessions.is_pro OR EXCLUDED.is_pro`,
      [
        clientId,
        platform,
        input.appVersion.slice(0, 40),
        input.geo.country,
        input.geo.countryCode,
        input.geo.region,
        input.geo.city,
        os,
        browser,
        device,
        input.userAgent.slice(0, 500),
        ipHash,
        startedIso,
        endedIso,
        duration,
        deviceId,
        input.isPro,
      ],
    );

    // Attribute each buffered screen view to the session's real start time (not
    // the flush time, up to 12h later) so the dashboard's range filters stay
    // accurate.
    const screens = input.screens
      .map((screen) => screen.trim().slice(0, MAX_SCREEN_LEN))
      .filter(Boolean)
      .slice(0, 200);
    for (const screen of screens) {
      await query(
        `INSERT INTO admin_screen_views (client_id, device_id, platform, screen, created_at)
         VALUES ($1, $2, $3, $4, $5)`,
        [clientId, deviceId, platform, screen, startedIso],
      );
    }
  } catch (error) {
    void logError({ source: "analytics/trackBatchSession", error, platform });
  }
}
