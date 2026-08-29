import { getClientIp, lookupGeo } from "@/lib/geo";
import { maybePurge } from "@/lib/retention";
import {
  recordScreenView,
  trackBatchSession,
  trackSession,
  type TrackEvent,
} from "@/lib/analytics-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const EVENTS: readonly TrackEvent[] = ["start", "heartbeat", "end"];

// Cap sessions ingested per flush so one request can't do unbounded DB work.
const MAX_BATCH_SESSIONS = 200;

/**
 * Usage-tracking beacon for every Stillora client (web, mobile, desktop).
 * Clients POST `{ clientId, event, platform, appVersion }` on app open, then a
 * heartbeat every ~30s, then `end` on close. The dashboard turns these into
 * session counts, per-country breakdowns, and total time-used.
 *
 * Attribution is by device: clients send a stable `deviceId` (and `isPro`) and
 * nothing else identifies them. A client that sends no device id falls back to
 * its hashed IP, so it still counts as one device rather than many.
 */
export async function POST(request: Request) {
  // Fire-and-forget: at most one purge a day, claimed in the database, so this
  // is a single indexed read on every other beacon.
  void maybePurge();

  let body: {
    clientId?: unknown;
    deviceId?: unknown;
    isPro?: unknown;
    event?: unknown;
    platform?: unknown;
    appVersion?: unknown;
    screen?: unknown;
    sessions?: unknown;
  };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return Response.json({ error: "Invalid request." }, { status: 400 });
  }

  // Batched flush from mobile/desktop: a device sends many completed sessions at
  // once (~every 12h) instead of live heartbeats. Handled before the per-event
  // clientId check because the ids live on each session, not the envelope. Geo
  // is resolved once from the flush IP and shared across the batch.
  if (body.event === "batch") {
    const sessions = Array.isArray(body.sessions) ? body.sessions : [];
    if (sessions.length) {
      const envelopeDeviceId = str(body.deviceId).slice(0, 100);
      const envelopePro = body.isPro === true;
      const ip = getClientIp(request);
      const userAgent = request.headers.get("user-agent") ?? "";
      const geo = await lookupGeo(ip);

      for (const raw of sessions.slice(0, MAX_BATCH_SESSIONS)) {
        const s = raw as {
          clientId?: unknown;
          deviceId?: unknown;
          isPro?: unknown;
          startedAt?: unknown;
          durationSeconds?: unknown;
          platform?: unknown;
          appVersion?: unknown;
          screens?: unknown;
        };
        if (typeof s.clientId !== "string" || typeof s.startedAt !== "string") {
          continue;
        }
        await trackBatchSession({
          clientId: s.clientId,
          // Per-session id wins; the envelope's is the fallback for clients
          // that only send it once per flush.
          deviceId: str(s.deviceId).slice(0, 100) || envelopeDeviceId,
          isPro: s.isPro === true || envelopePro,
          startedAt: s.startedAt,
          durationSeconds:
            typeof s.durationSeconds === "number" ? s.durationSeconds : 0,
          platform: typeof s.platform === "string" ? s.platform : "web",
          appVersion: typeof s.appVersion === "string" ? s.appVersion : "",
          screens: Array.isArray(s.screens)
            ? s.screens.filter((x): x is string => typeof x === "string")
            : [],
          geo,
          ip,
          userAgent,
        });
      }
    }
    return Response.json({ ok: true }, { status: 202 });
  }

  const clientId = typeof body.clientId === "string" ? body.clientId.trim() : "";
  if (!clientId || clientId.length > 100) {
    return Response.json({ error: "clientId is required." }, { status: 400 });
  }

  const platform = typeof body.platform === "string" ? body.platform : "web";
  const deviceId = str(body.deviceId).slice(0, 100);
  const isPro = body.isPro === true;

  // A "screen" event records which part of the app was viewed; it doesn't touch
  // the session row (heartbeats keep that alive).
  if (body.event === "screen") {
    const screen = typeof body.screen === "string" ? body.screen : "";
    if (screen.trim()) {
      await recordScreenView({ clientId, deviceId, platform, screen });
    }
    return Response.json({ ok: true }, { status: 202 });
  }

  const event: TrackEvent = EVENTS.includes(body.event as TrackEvent)
    ? (body.event as TrackEvent)
    : "heartbeat";
  const appVersion =
    typeof body.appVersion === "string" ? body.appVersion.slice(0, 40) : "";

  const ip = getClientIp(request);
  const userAgent = request.headers.get("user-agent") ?? "";

  // Only spend a geo lookup when the session is created.
  const geo =
    event === "start"
      ? await lookupGeo(ip)
      : { country: "", countryCode: "", region: "", city: "" };

  await trackSession({
    clientId,
    deviceId,
    isPro,
    event,
    platform,
    appVersion,
    geo,
    ip,
    userAgent,
  });

  return Response.json({ ok: true }, { status: 202 });
}

/** Narrows an unknown JSON field to a trimmed string. */
function str(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}
