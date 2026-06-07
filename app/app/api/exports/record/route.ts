import { getUserFromRequest } from "@/lib/auth";
import { recordExport } from "@/lib/admin-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/**
 * Telemetry endpoint for native apps. Mobile/desktop export locally with the
 * on-device engine, so they never hit `/api/exports`. They POST here after a
 * successful export so the admin dashboard reflects activity from every app.
 */
export async function POST(request: Request) {
  const user = await getUserFromRequest(request);
  if (!user) {
    return Response.json({ error: "Unauthorized." }, { status: 401 });
  }

  let body: { presetId?: unknown; duration?: unknown };
  try {
    body = (await request.json()) as { presetId?: unknown; duration?: unknown };
  } catch {
    return Response.json({ error: "Invalid request." }, { status: 400 });
  }

  const presetId =
    typeof body.presetId === "string" && body.presetId.trim()
      ? body.presetId.trim()
      : "unknown";
  const duration =
    typeof body.duration === "number" && Number.isFinite(body.duration)
      ? Math.max(0, Math.round(body.duration))
      : 0;

  void recordExport(user, { presetId, duration });

  return Response.json({ ok: true }, { status: 201 });
}
