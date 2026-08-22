"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

export type ProState = {
  /** null when the user has never held Pro. */
  source: "apple" | "google" | "admin" | null;
  active: boolean;
  grantedBy: string;
  note: string;
};

const LABELS: Record<string, string> = {
  apple: "App Store",
  google: "Google Play",
  admin: "Comped",
};

/**
 * Per-user Pro control for the users table.
 *
 * Only a comp can be taken back from here. A real store purchase has no revoke
 * button at all, because the buyer's device would hear "owned" from Apple or
 * Google on its next launch and re-grant itself — offering a button that cannot
 * work is worse than not offering one. Refunds go through the store.
 */
export function ProControl({ userSub, state }: { userSub: string; state: ProState }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function act(action: "grant" | "revoke") {
    setBusy(true);
    setError("");
    try {
      const response = await fetch("/api/admin/pro", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action, userSub }),
      });
      const data = (await response.json()) as { ok?: boolean; error?: string };
      if (!response.ok || data.ok === false) {
        setError(data.error ?? "Failed.");
        return;
      }
      router.refresh();
    } catch {
      setError("Network error.");
    } finally {
      setBusy(false);
    }
  }

  const canRevoke = state.active && state.source === "admin";

  return (
    <div className="flex items-center gap-2">
      {state.active ? (
        <span
          className="rounded-full px-2 py-0.5 text-xs font-bold"
          style={{
            background: "var(--color-primary-soft)",
            color: "var(--color-primary)",
          }}
          title={
            state.source === "admin" && state.grantedBy
              ? `Granted by ${state.grantedBy}${state.note ? ` — ${state.note}` : ""}`
              : undefined
          }
        >
          PRO · {LABELS[state.source ?? ""] ?? state.source}
        </span>
      ) : (
        <span className="text-xs" style={{ color: "var(--color-muted)" }}>
          Free
        </span>
      )}

      {canRevoke ? (
        <button
          type="button"
          onClick={() => act("revoke")}
          disabled={busy}
          className="rounded-md border px-2 py-0.5 text-xs font-semibold disabled:opacity-50"
          style={{ borderColor: "var(--color-border)", color: "var(--color-danger)" }}
        >
          {busy ? "…" : "Revoke"}
        </button>
      ) : state.active ? null : (
        <button
          type="button"
          onClick={() => act("grant")}
          disabled={busy}
          className="rounded-md border px-2 py-0.5 text-xs font-semibold disabled:opacity-50"
          style={{ borderColor: "var(--color-border)", color: "var(--color-foreground)" }}
        >
          {busy ? "…" : "Grant Pro"}
        </button>
      )}

      {error ? (
        <span className="text-xs" style={{ color: "var(--color-danger)" }} title={error}>
          !
        </span>
      ) : null}
    </div>
  );
}
