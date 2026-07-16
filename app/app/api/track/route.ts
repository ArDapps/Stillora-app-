import { getUserFromRequest } from "@/lib/auth";
import { getClientIp, lookupGeo } from "@/lib/geo";
import { recordScreenView, trackSession, type TrackEvent } from "@/lib/analytics-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const EVENTS: readonly TrackEvent[] = ["start", "heartbeat", "end"];

/**
 * Usage-tracking beacon for every Stillora client (web, mobile, desktop).
 * Clients POST `{ clientId, event, platform, appVersion }` on app open, then a
 * heartbeat every ~30s, then `end` on close. The dashboard turns these into
 * session counts, per-country breakdowns, and total time-used.
 *
 * Auth is optional: signed-in users are attributed by account; anonymous
 * visitors are still counted (deduped by hashed IP).
 */
export async function POST(request: Request) {
  let body: {
    clientId?: unknown;
    event?: unknown;
    platform?: unknown;
    appVersion?: unknown;
    screen?: unknown;
  };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return Response.json({ error: "Invalid request." }, { status: 400 });
  }

  const clientId = typeof body.clientId === "string" ? body.clientId.trim() : "";
  if (!clientId || clientId.length > 100) {
    return Response.json({ error: "clientId is required." }, { status: 400 });
  }

  const platform = typeof body.platform === "string" ? body.platform : "web";
  const user = await getUserFromRequest(request);

  // A "screen" event records which part of the app was viewed; it doesn't touch
  // the session row (heartbeats keep that alive).
  if (body.event === "screen") {
    const screen = typeof body.screen === "string" ? body.screen : "";
    if (screen.trim()) {
      await recordScreenView({ clientId, userSub: user?.sub ?? null, platform, screen });
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
    event,
    platform,
    appVersion,
    user,
    geo,
    ip,
    userAgent,
  });

  return Response.json({ ok: true }, { status: 202 });
}
