"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";

import { getClientId, getDeviceId } from "./device-id";

const HEARTBEAT_MS = 30_000;

/**
 * Fire-and-forget usage tracker for the web app. On mount it opens a session,
 * pings a heartbeat every 30s while the tab is visible, and closes the session
 * when the tab is hidden or unloaded. The server turns these beacons into the
 * admin dashboard's session / country / time-used analytics.
 *
 * Mounted once in the root layout so it covers every page.
 */
export function SessionTracker() {
  const pathname = usePathname();

  // Report each page view as a screen event (skip the admin dashboard so your
  // own analytics browsing doesn't pollute the numbers).
  useEffect(() => {
    if (!pathname || pathname.startsWith("/admin")) return;
    const payload = JSON.stringify({
      clientId: getClientId(),
      deviceId: getDeviceId(),
      event: "screen",
      platform: "web",
      screen: pathname,
    });
    fetch("/api/track", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: payload,
      keepalive: true,
    }).catch(() => {});
  }, [pathname]);

  useEffect(() => {
    const clientId = getClientId();
    const deviceId = getDeviceId();

    const send = (event: "start" | "heartbeat" | "end", useBeacon = false) => {
      const payload = JSON.stringify({ clientId, deviceId, event, platform: "web" });
      // sendBeacon survives page unload; fetch is used while the page is alive.
      if (useBeacon && typeof navigator !== "undefined" && navigator.sendBeacon) {
        navigator.sendBeacon("/api/track", new Blob([payload], { type: "application/json" }));
        return;
      }
      fetch("/api/track", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: payload,
        keepalive: true,
      }).catch(() => {
        /* tracking must never surface an error to the user */
      });
    };

    send("start");
    const interval = setInterval(() => {
      if (document.visibilityState === "visible") send("heartbeat");
    }, HEARTBEAT_MS);

    const onVisibility = () => {
      send(document.visibilityState === "hidden" ? "end" : "heartbeat", document.visibilityState === "hidden");
    };
    const onUnload = () => send("end", true);

    document.addEventListener("visibilitychange", onVisibility);
    window.addEventListener("pagehide", onUnload);

    return () => {
      clearInterval(interval);
      document.removeEventListener("visibilitychange", onVisibility);
      window.removeEventListener("pagehide", onUnload);
      send("end", true);
    };
  }, []);

  return null;
}
