"use client";

import { useEffect } from "react";

/**
 * Last-resort boundary for a crash in the root layout. It reports the failure
 * to /admin/errors — the render is already lost at this point, so the one thing
 * still worth doing is making sure the failure is not silent — then offers a
 * retry.
 */
export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    fetch("/api/errors", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        source: "web/global-error",
        name: error.name,
        message: error.message,
        stack: error.stack ?? "",
        url: typeof window !== "undefined" ? window.location.pathname : "",
        platform: "web",
      }),
      keepalive: true,
    }).catch(() => {});
  }, [error]);

  return (
    <html lang="en">
      <body
        style={{
          display: "flex",
          minHeight: "100vh",
          alignItems: "center",
          justifyContent: "center",
          padding: "2rem",
          background: "#060711",
          color: "#f5f7ff",
          fontFamily: "system-ui, sans-serif",
          textAlign: "center",
        }}
      >
        <div style={{ maxWidth: "28rem" }}>
          <h1 style={{ fontSize: "1.25rem", fontWeight: 700 }}>Something broke</h1>
          <p style={{ marginTop: "0.5rem", fontSize: "0.875rem", color: "#b7bfd5" }}>
            The problem has been reported. Try again — your work in progress is kept on this device.
          </p>
          <button
            type="button"
            onClick={reset}
            style={{
              marginTop: "1.5rem",
              borderRadius: "0.5rem",
              background: "#8b5cf6",
              color: "#fff",
              padding: "0.625rem 1.25rem",
              fontWeight: 600,
              border: "none",
              cursor: "pointer",
            }}
          >
            Try again
          </button>
        </div>
      </body>
    </html>
  );
}
