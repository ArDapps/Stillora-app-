const DEVICE_KEY = "stillora-device-id";
const SESSION_KEY = "stillora-session-id";

function randomId(prefix: string): string {
  if (typeof crypto !== "undefined" && crypto.randomUUID) return `${prefix}-${crypto.randomUUID()}`;
  return `${prefix}-${Date.now()}-${Math.round(Math.random() * 1e9)}`;
}

/**
 * Stable id for this browser install, persisted in localStorage.
 *
 * Stillora has no accounts, so this is what makes "how many people use it" and
 * "how long does each one spend" answerable at all: it survives reloads and new
 * tabs, where the per-tab session id deliberately does not. Cleared storage or
 * a private window simply looks like a new device — the server then falls back
 * to a hashed IP, so the visit is still counted once.
 */
export function getDeviceId(): string {
  try {
    const existing = localStorage.getItem(DEVICE_KEY);
    if (existing) return existing;
    const id = randomId("d");
    localStorage.setItem(DEVICE_KEY, id);
    return id;
  } catch {
    return "";
  }
}

/** A per-tab session id, regenerated for each new browsing session. */
export function getClientId(): string {
  try {
    const existing = sessionStorage.getItem(SESSION_KEY);
    if (existing) return existing;
    const id = randomId("s");
    sessionStorage.setItem(SESSION_KEY, id);
    return id;
  } catch {
    // Private-mode / storage-disabled fallback: a volatile id (won't dedupe across reloads).
    return randomId("s");
  }
}

/**
 * Headers that tie a request to this device. Attach them to anything the admin
 * dashboard should be able to trace back — exports, conversions, crash reports.
 */
export function deviceHeaders(): Record<string, string> {
  const id = getDeviceId();
  return id ? { "x-stillora-device": id, "x-stillora-platform": "web" } : {};
}
