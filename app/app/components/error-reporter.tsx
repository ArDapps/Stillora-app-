"use client";

import { useEffect } from "react";

import { getDeviceId } from "./device-id";

// One page load can only usefully report a handful of distinct failures; past
// this a broken render loop would hammer the endpoint.
const MAX_REPORTS_PER_PAGE = 10;

/**
 * Browser crash reporter. Forwards uncaught errors and unhandled promise
 * rejections to `/api/errors`, where they land on the admin Errors page next to
 * server-side failures — deduped there, so a bug that fires on every load shows
 * up once with a count.
 *
 * Mounted once in the root layout. Silent by design: reporting a crash must
 * never itself surface anything to the person using the app.
 */
export function ErrorReporter() {
  useEffect(() => {
    let sent = 0;
    const seen = new Set<string>();

    const report = (source: string, name: string, message: string, stack: string) => {
      if (!message || sent >= MAX_REPORTS_PER_PAGE) return;
      // Same message twice in one page load is the same bug — send it once.
      const key = `${source}|${message}`;
      if (seen.has(key)) return;
      seen.add(key);
      sent += 1;

      fetch("/api/errors", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          source,
          name,
          message,
          stack,
          url: window.location.pathname + window.location.search,
          platform: "web",
          deviceId: getDeviceId(),
        }),
        keepalive: true,
      }).catch(() => {});
    };

    const onError = (event: ErrorEvent) => {
      const error = event.error as Error | undefined;
      report(
        "web/window.onerror",
        error?.name ?? "Error",
        error?.message ?? event.message,
        error?.stack ?? `${event.filename}:${event.lineno}:${event.colno}`,
      );
    };

    const onRejection = (event: PromiseRejectionEvent) => {
      const reason = event.reason;
      if (reason instanceof Error) {
        report("web/unhandledrejection", reason.name, reason.message, reason.stack ?? "");
        return;
      }
      report("web/unhandledrejection", "UnhandledRejection", String(reason), "");
    };

    window.addEventListener("error", onError);
    window.addEventListener("unhandledrejection", onRejection);
    return () => {
      window.removeEventListener("error", onError);
      window.removeEventListener("unhandledrejection", onRejection);
    };
  }, []);

  return null;
}
