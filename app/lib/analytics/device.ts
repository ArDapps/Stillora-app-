import { createHash } from "node:crypto";

const KNOWN_PLATFORMS = new Set([
  "web",
  "ios",
  "android",
  "macos",
  "windows",
  "linux",
]);

export function normalizePlatform(value: string): string {
  const p = value.trim().toLowerCase();
  return KNOWN_PLATFORMS.has(p) ? p : "web";
}

/** Coarse OS/browser/device sniffing from a User-Agent string. No dependency. */
export function parseUserAgent(ua: string): { os: string; browser: string; device: string } {
  if (!ua) return { os: "", browser: "", device: "" };

  let os = "";
  if (/windows nt/i.test(ua)) os = "Windows";
  else if (/iphone|ipad|ipod/i.test(ua)) os = "iOS";
  else if (/android/i.test(ua)) os = "Android";
  else if (/mac os x/i.test(ua)) os = "macOS";
  else if (/linux/i.test(ua)) os = "Linux";

  let browser = "";
  if (/edg\//i.test(ua)) browser = "Edge";
  else if (/opr\/|opera/i.test(ua)) browser = "Opera";
  else if (/chrome\//i.test(ua) && !/chromium/i.test(ua)) browser = "Chrome";
  else if (/firefox\//i.test(ua)) browser = "Firefox";
  else if (/safari\//i.test(ua) && !/chrome/i.test(ua)) browser = "Safari";

  const device = /mobile|iphone|ipod|android.*mobile/i.test(ua)
    ? "Mobile"
    : /ipad|tablet/i.test(ua)
      ? "Tablet"
      : "Desktop";

  return { os, browser, device };
}

export function hashIp(ip: string): string {
  if (!ip) return "";
  const salt = process.env.AUTH_SECRET ?? "stillora";
  return createHash("sha256").update(`${salt}:${ip}`).digest("hex").slice(0, 16);
}
