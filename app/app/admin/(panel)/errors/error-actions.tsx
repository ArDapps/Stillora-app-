"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";

type Action = "resolve" | "reopen" | "delete" | "clear-resolved";

async function send(action: Action, id?: string): Promise<boolean> {
  const response = await fetch("/api/admin/errors", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ action, id }),
  });
  return response.ok;
}

/** Resolve / reopen / delete for one error row. */
export function ErrorRowActions({ id, resolved }: { id: string; resolved: boolean }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [busy, setBusy] = useState(false);

  const run = (action: Action) => {
    setBusy(true);
    void send(action, id).finally(() => {
      setBusy(false);
      startTransition(() => router.refresh());
    });
  };

  const disabled = busy || pending;

  return (
    <div className="flex shrink-0 items-center gap-2">
      <ActionButton disabled={disabled} onClick={() => run(resolved ? "reopen" : "resolve")}>
        {resolved ? "Reopen" : "Resolve"}
      </ActionButton>
      <ActionButton disabled={disabled} tone="danger" onClick={() => run("delete")}>
        Delete
      </ActionButton>
    </div>
  );
}

/** Bulk clear, shown next to the filter tabs. */
export function ClearResolvedButton({ count }: { count: number }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);

  if (count <= 0) return null;

  return (
    <ActionButton
      disabled={busy}
      onClick={() => {
        setBusy(true);
        void send("clear-resolved").finally(() => {
          setBusy(false);
          router.refresh();
        });
      }}
    >
      Clear {count} resolved
    </ActionButton>
  );
}

function ActionButton({
  children,
  onClick,
  disabled,
  tone = "default",
}: {
  children: React.ReactNode;
  onClick: () => void;
  disabled?: boolean;
  tone?: "default" | "danger";
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className="rounded-lg border px-2.5 py-1 text-xs font-semibold transition disabled:opacity-40"
      style={{
        borderColor: "var(--color-border)",
        color: tone === "danger" ? "var(--color-danger)" : "var(--color-foreground)",
      }}
    >
      {children}
    </button>
  );
}
