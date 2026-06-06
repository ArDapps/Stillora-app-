"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function AdminLoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const res = await fetch("/api/admin/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });

      if (!res.ok) {
        const data = (await res.json()) as { error?: string };
        setError(data.error ?? "Login failed.");
        return;
      }

      router.push("/admin");
      router.refresh();
    } catch {
      setError("Network error. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div
      className="flex min-h-screen items-center justify-center p-4"
      style={{ background: "var(--color-surface-dim)" }}
    >
      <div
        className="w-full max-w-sm rounded-2xl border p-8"
        style={{ background: "var(--color-card)", borderColor: "var(--color-border)" }}
      >
        <h1 className="mb-1 text-xl font-bold" style={{ color: "var(--color-foreground)" }}>
          Admin access
        </h1>
        <p className="mb-6 text-sm" style={{ color: "var(--color-muted)" }}>
          Enter your admin email and password.
        </p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <Field label="Email">
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
              placeholder="admin@example.com"
              className="w-full rounded-lg border px-3 py-2 text-sm outline-none transition focus:border-[var(--color-primary)]"
              style={{
                background: "var(--color-surface)",
                borderColor: "var(--color-border)",
                color: "var(--color-foreground)",
              }}
            />
          </Field>

          <Field label="Password">
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              autoComplete="current-password"
              placeholder="••••••••"
              className="w-full rounded-lg border px-3 py-2 text-sm outline-none transition focus:border-[var(--color-primary)]"
              style={{
                background: "var(--color-surface)",
                borderColor: "var(--color-border)",
                color: "var(--color-foreground)",
              }}
            />
          </Field>

          {error && (
            <p className="text-sm" style={{ color: "var(--color-danger)" }}>{error}</p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg py-2.5 text-sm font-semibold transition disabled:opacity-50"
            style={{
              background: "var(--color-primary)",
              color: "var(--color-primary-text)",
            }}
          >
            {loading ? "Signing in…" : "Sign in"}
          </button>
        </form>
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="space-y-1.5">
      <label className="block text-xs font-semibold uppercase tracking-wide" style={{ color: "var(--color-muted)" }}>
        {label}
      </label>
      {children}
    </div>
  );
}
