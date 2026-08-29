import { recordExport } from "@/lib/admin-store";
import { exportDeviceId, exportPlatform } from "@/lib/export-identity";
import { withErrorLog } from "@/lib/api-log";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/** Tools that can report an export. Anything else is filed as "create". */
const TOOLS = new Set([
  "create",
  "html",
  "loop",
  "watermark",
  "silence",
  "speed",
  "convert",
]);

/**
 * Export telemetry for every client that renders locally.
 *
 * Mobile and desktop export with the on-device engine and never hit
 * `/api/exports`, so this is the only signal the server gets from them. There
 * is no account to attribute it to: the row is keyed by the caller's device id
 * (header `x-stillora-device`, hashed IP otherwise), which is what the admin
 * dashboard counts exports and per-device activity by.
 */
async function handler(request: Request) {
  let body: { presetId?: unknown; duration?: unknown; tool?: unknown; platform?: unknown };
  try {
    body = (await request.json()) as typeof body;
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
  const requested = typeof body.tool === "string" ? body.tool.trim().toLowerCase() : "";
  const tool = TOOLS.has(requested) ? requested : "create";
  const platform =
    typeof body.platform === "string" && body.platform.trim()
      ? body.platform.trim()
      : exportPlatform(request, "");

  void recordExport({
    deviceId: exportDeviceId(request),
    platform,
    tool,
    presetId,
    duration,
  });

  return Response.json({ ok: true }, { status: 201 });
}

export const POST = withErrorLog("api/exports/record", handler);
