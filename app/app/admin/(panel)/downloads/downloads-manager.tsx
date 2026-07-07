"use client";

import { useRouter } from "next/navigation";
import { useRef, useState } from "react";

export type PlatformState = {
  platform: string;
  label: string;
  kind: "file" | "url" | null;
  externalUrl: string;
  fileName: string;
  sizeBytes: number;
  version: string;
  updatedAt: string;
};

export function DownloadsManager({ platforms }: { platforms: PlatformState[] }) {
  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
      {platforms.map((p) => (
        <PlatformCard key={p.platform} state={p} />
      ))}
    </div>
  );
}

function PlatformCard({ state }: { state: PlatformState }) {
  const router = useRouter();
  const fileInput = useRef<HTMLInputElement>(null);
  const [mode, setMode] = useState<"file" | "url">(state.kind === "url" ? "url" : "file");
  const [url, setUrl] = useState(state.externalUrl);
  const [version, setVersion] = useState(state.version);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [done, setDone] = useState("");

  async function save(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setDone("");
    setBusy(true);
    try {
      const form = new FormData();
      form.set("platform", state.platform);
      form.set("version", version);
      if (mode === "file") {
        const file = fileInput.current?.files?.[0];
        if (!file) {
          setError("Choose a file to upload.");
          return;
        }
        form.set("file", file);
      } else {
        if (!url.trim()) {
          setError("Enter a link.");
          return;
        }
        form.set("url", url.trim());
      }

      const res = await fetch("/api/admin/downloads", { method: "POST", body: form });
      if (!res.ok) {
        const data = (await res.json().catch(() => ({}))) as { error?: string };
        setError(data.error ?? "Save failed.");
        return;
      }
      setDone("Saved.");
      if (fileInput.current) fileInput.current.value = "";
      router.refresh();
    } catch {
      setError("Network error.");
    } finally {
      setBusy(false);
    }
  }

  async function clear() {
    if (!confirm(`Remove the ${state.label} download?`)) return;
    setError("");
    setDone("");
    setBusy(true);
    try {
      const res = await fetch(`/api/admin/downloads/${state.platform}`, { method: "DELETE" });
      if (!res.ok) {
        const data = (await res.json().catch(() => ({}))) as { error?: string };
        setError(data.error ?? "Remove failed.");
        return;
      }
      setUrl("");
      setVersion("");
      router.refresh();
    } catch {
      setError("Network error.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form
      onSubmit={save}
      className="flex flex-col gap-3 rounded-xl border p-5"
      style={{ background: "var(--color-card)", borderColor: "var(--color-border)" }}
    >
      <div className="flex items-center justify-between">
        <h3 className="text-base font-semibold" style={{ color: "var(--color-foreground)" }}>
          {state.label}
        </h3>
        <StatusBadge state={state} />
      </div>

      {/* Mode toggle */}
      <div
        className="inline-flex w-fit rounded-lg border p-0.5 text-xs font-semibold"
        style={{ borderColor: "var(--color-border)" }}
      >
        <ModeButton active={mode === "file"} onClick={() => setMode("file")}>Upload file</ModeButton>
        <ModeButton active={mode === "url"} onClick={() => setMode("url")}>External link</ModeButton>
      </div>

      {mode === "file" ? (
        <input
          ref={fileInput}
          type="file"
          className="text-sm"
          style={{ color: "var(--color-muted)" }}
        />
      ) : (
        <input
          type="url"
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          placeholder="https://…"
          className="w-full rounded-lg border px-3 py-2 text-sm outline-none focus:border-[var(--color-primary)]"
          style={{ background: "var(--color-surface)", borderColor: "var(--color-border)", color: "var(--color-foreground)" }}
        />
      )}

      <input
        type="text"
        value={version}
        onChange={(e) => setVersion(e.target.value)}
        placeholder="Version (optional, e.g. 1.1.3)"
        className="w-full rounded-lg border px-3 py-2 text-sm outline-none focus:border-[var(--color-primary)]"
        style={{ background: "var(--color-surface)", borderColor: "var(--color-border)", color: "var(--color-foreground)" }}
      />

      {error && (
        <p className="rounded-lg px-3 py-2 text-xs" style={{ background: "var(--color-danger-soft)", color: "var(--color-danger)" }}>
          {error}
        </p>
      )}
      {done && (
        <p className="rounded-lg px-3 py-2 text-xs" style={{ background: "var(--color-success-soft, var(--color-primary-soft))", color: "var(--color-success)" }}>
          {done}
        </p>
      )}

      <div className="mt-1 flex gap-2">
        <button
          type="submit"
          disabled={busy}
          className="rounded-lg px-4 py-2 text-sm font-bold transition hover:opacity-95 disabled:opacity-50"
          style={{ background: "var(--brand-gradient)", color: "#fff" }}
        >
          {busy ? "Saving…" : "Save"}
        </button>
        {state.kind && (
          <button
            type="button"
            onClick={clear}
            disabled={busy}
            className="rounded-lg border px-4 py-2 text-sm font-semibold transition hover:opacity-80 disabled:opacity-50"
            style={{ borderColor: "var(--color-border)", color: "var(--color-danger)" }}
          >
            Remove
          </button>
        )}
      </div>
    </form>
  );
}

function StatusBadge({ state }: { state: PlatformState }) {
  if (!state.kind) {
    return (
      <span className="rounded-full px-2 py-0.5 text-xs font-semibold" style={{ background: "var(--color-border-subtle)", color: "var(--color-muted)" }}>
        Default
      </span>
    );
  }
  const text =
    state.kind === "url"
      ? state.externalUrl
      : `${state.fileName} · ${formatBytes(state.sizeBytes)}`;
  return (
    <span
      className="max-w-[55%] truncate rounded-full px-2 py-0.5 text-xs font-semibold"
      style={{ background: "var(--color-primary-soft)", color: "var(--color-primary)" }}
      title={text}
    >
      {state.kind === "url" ? "Link" : "File"} · {text}
    </span>
  );
}

function ModeButton({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="rounded-md px-3 py-1 transition"
      style={
        active
          ? { background: "var(--color-primary)", color: "#fff" }
          : { color: "var(--color-muted)" }
      }
    >
      {children}
    </button>
  );
}

function formatBytes(bytes: number): string {
  if (!bytes) return "0 B";
  const units = ["B", "KB", "MB", "GB"];
  const i = Math.min(units.length - 1, Math.floor(Math.log(bytes) / Math.log(1024)));
  return `${(bytes / Math.pow(1024, i)).toFixed(i ? 1 : 0)} ${units[i]}`;
}
