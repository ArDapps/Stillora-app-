import { getClientIp } from "./geo";
import { hashIp } from "./analytics/device";

/**
 * The device an export belongs to.
 *
 * Clients send a stable per-install id in `x-stillora-device` (the same one the
 * `/api/track` beacon uses), so an export lines up with the session that
 * produced it. Anything without the header — an older build, a direct API call
 * — falls back to the hashed IP, which is what the analytics tables already use
 * for anonymous web visitors.
 */
export function exportDeviceId(request: Request): string {
  const header = request.headers.get("x-stillora-device")?.trim();
  if (header) return header.slice(0, 100);
  return hashIp(getClientIp(request));
}

/** Which surface an export came from, defaulting to web. */
export function exportPlatform(request: Request, fallback = "web"): string {
  const header = request.headers.get("x-stillora-platform")?.trim();
  return (header || fallback).slice(0, 40);
}

/** Tools a client may attribute an export to. Anything else is filed as create. */
const TOOLS = new Set(["create", "html", "loop", "watermark", "silence", "speed", "convert"]);

/** Which tool produced an export, from the `x-stillora-tool` header. */
export function exportTool(request: Request, fallback = "create"): string {
  const header = request.headers.get("x-stillora-tool")?.trim().toLowerCase() ?? "";
  return TOOLS.has(header) ? header : fallback;
}
