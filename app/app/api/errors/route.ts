import { logError } from "@/lib/error-log";
import { getClientIp } from "@/lib/geo";
import { overRateLimit } from "@/lib/rate-limit";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// One report can only ever describe one failure; a client that batches sends
// several requests. Keeps the handler cheap and un-abusable.
const MAX_SOURCE = 200;

// The endpoint is unauthenticated by necessity, so it is capped per IP: a real
// client reports a handful of distinct crashes, never hundreds. Tunable so a
// deployment seeing legitimate bursts — or an end-to-end suite that has to
// report many crashes in one minute — can raise it without a code change.
const RATE_LIMIT = Number(process.env.ERROR_REPORT_RATE_LIMIT ?? 30);
const RATE_WINDOW_MS = 60_000;

export async function POST(request: Request) {
  if (overRateLimit(getClientIp(request), RATE_LIMIT, RATE_WINDOW_MS)) {
    // Accepted-and-dropped, not 429: a client that retries a rejected crash
    // report just makes the flood worse.
    return Response.json({ ok: true }, { status: 202 });
  }

  let body: {
    source?: unknown;
    name?: unknown;
    message?: unknown;
    stack?: unknown;
    url?: unknown;
    platform?: unknown;
    appVersion?: unknown;
    deviceId?: unknown;
  };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return Response.json({ error: "Invalid request." }, { status: 400 });
  }

  const message = typeof body.message === "string" ? body.message.trim() : "";
  if (!message) {
    return Response.json({ error: "message is required." }, { status: 400 });
  }

  const name = typeof body.name === "string" && body.name.trim() ? body.name.trim() : "Error";
  const error = Object.assign(new Error(message), {
    name,
    stack: typeof body.stack === "string" ? body.stack : "",
  });

  await logError({
    scope: "client",
    source: typeof body.source === "string" && body.source.trim()
      ? body.source.trim().slice(0, MAX_SOURCE)
      : "client",
    error,
    url: typeof body.url === "string" ? body.url : "",
    platform: typeof body.platform === "string" ? body.platform : "web",
    appVersion: typeof body.appVersion === "string" ? body.appVersion : "",
    deviceId: typeof body.deviceId === "string" ? body.deviceId : "",
    userAgent: request.headers.get("user-agent") ?? "",
  });

  return Response.json({ ok: true }, { status: 202 });
}
