import { query } from "../db";
import type { GeoLocation } from "../geo";
import { hashIp, normalizePlatform, parseUserAgent } from "./device";

export type TrackEvent = "start" | "heartbeat" | "end";

export type TrackInput = {
  clientId: string;
  event: TrackEvent;
  platform: string;
  appVersion: string;
  user: { sub: string; email: string; name: string } | null;
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
  const endedClause = input.event === "end" ? "now()" : "NULL";

  try {
    if (input.event === "start") {
      await query(
        `INSERT INTO admin_sessions
           (client_id, user_sub, user_email, user_name, platform, app_version,
            country, country_code, region, city, os, browser, device, user_agent,
            ip_hash, started_at, last_seen_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15, now(), now())
         ON CONFLICT (client_id) DO UPDATE
           SET last_seen_at = now(),
               ended_at = NULL,
               -- Fill user/geo fields once we learn them (e.g. user signs in mid-session).
               user_sub  = COALESCE(admin_sessions.user_sub, EXCLUDED.user_sub),
               user_email = CASE WHEN admin_sessions.user_email = '' THEN EXCLUDED.user_email ELSE admin_sessions.user_email END,
               user_name  = CASE WHEN admin_sessions.user_name = '' THEN EXCLUDED.user_name ELSE admin_sessions.user_name END,
               country      = CASE WHEN admin_sessions.country = '' THEN EXCLUDED.country ELSE admin_sessions.country END,
               country_code = CASE WHEN admin_sessions.country_code = '' THEN EXCLUDED.country_code ELSE admin_sessions.country_code END,
               region       = CASE WHEN admin_sessions.region = '' THEN EXCLUDED.region ELSE admin_sessions.region END,
               city         = CASE WHEN admin_sessions.city = '' THEN EXCLUDED.city ELSE admin_sessions.city END,
               app_version  = CASE WHEN EXCLUDED.app_version <> '' THEN EXCLUDED.app_version ELSE admin_sessions.app_version END,
               duration_seconds = GREATEST(admin_sessions.duration_seconds,
                 CAST(EXTRACT(EPOCH FROM (now() - admin_sessions.started_at)) AS INTEGER))`,
        [
          clientId,
          input.user?.sub ?? null,
          input.user?.email ?? "",
          input.user?.name ?? "",
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
        ],
      );
      return;
    }

    // heartbeat / end: extend the live session; only touch rows we already have.
    await query(
      `UPDATE admin_sessions
         SET last_seen_at = now(),
             ended_at = ${endedClause},
             user_sub = COALESCE(admin_sessions.user_sub, $2),
             user_email = CASE WHEN admin_sessions.user_email = '' THEN $3 ELSE admin_sessions.user_email END,
             user_name  = CASE WHEN admin_sessions.user_name = '' THEN $4 ELSE admin_sessions.user_name END,
             duration_seconds = CAST(EXTRACT(EPOCH FROM (now() - started_at)) AS INTEGER)
       WHERE client_id = $1`,
      [clientId, input.user?.sub ?? null, input.user?.email ?? "", input.user?.name ?? ""],
    );
  } catch (error) {
    console.error("trackSession failed:", error);
  }
}

const MAX_SCREEN_LEN = 120;

/** Records a single screen/feature view. Fire-and-forget like the rest. */
export async function recordScreenView(input: {
  clientId: string;
  userSub: string | null;
  platform: string;
  screen: string;
}): Promise<void> {
  const screen = input.screen.trim().slice(0, MAX_SCREEN_LEN);
  if (!screen) return;
  try {
    await query(
      `INSERT INTO admin_screen_views (client_id, user_sub, platform, screen)
       VALUES ($1, $2, $3, $4)`,
      [input.clientId.trim().slice(0, 100), input.userSub, normalizePlatform(input.platform), screen],
    );
  } catch (error) {
    console.error("recordScreenView failed:", error);
  }
}

// Guards a bad client clock from inflating total time-used with one giant session.
const MAX_BATCH_SESSION_SECONDS = 24 * 60 * 60;

export type BatchSessionInput = {
  clientId: string;
  /** ISO 8601 timestamp measured on the client when the session opened. */
  startedAt: string;
  /** Seconds the app was actually in the foreground, measured on the client. */
  durationSeconds: number;
  platform: string;
  appVersion: string;
  screens: string[];
  user: { sub: string; email: string; name: string } | null;
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

  try {
    await query(
      `INSERT INTO admin_sessions
         (client_id, user_sub, user_email, user_name, platform, app_version,
          country, country_code, region, city, os, browser, device, user_agent,
          ip_hash, started_at, last_seen_at, ended_at, duration_seconds)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$17,$18)
       ON CONFLICT (client_id) DO UPDATE
         SET duration_seconds = GREATEST(admin_sessions.duration_seconds, EXCLUDED.duration_seconds),
             last_seen_at = GREATEST(admin_sessions.last_seen_at, EXCLUDED.last_seen_at),
             ended_at = EXCLUDED.ended_at`,
      [
        clientId,
        input.user?.sub ?? null,
        input.user?.email ?? "",
        input.user?.name ?? "",
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
        `INSERT INTO admin_screen_views (client_id, user_sub, platform, screen, created_at)
         VALUES ($1, $2, $3, $4, $5)`,
        [clientId, input.user?.sub ?? null, platform, screen, startedIso],
      );
    }
  } catch (error) {
    console.error("trackBatchSession failed:", error);
  }
}
