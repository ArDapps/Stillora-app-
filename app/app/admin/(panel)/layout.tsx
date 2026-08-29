import { redirect } from "next/navigation";

import { getCurrentAdmin } from "@/lib/admin-server";
import { getErrorStats } from "@/lib/error-log";
import { RETENTION_DAYS, maybePurge } from "@/lib/retention";

import { AdminLogoutButton } from "./logout-button";
import { AdminNav } from "./nav";

export const metadata = { title: "Admin — Stillora" };
export const dynamic = "force-dynamic";

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const adminSession = await getCurrentAdmin();
  if (adminSession === null) redirect("/admin/login");

  // Loaded in the shell so the open-error count rides along on every page: a
  // failure that starts while you are reading the dashboard is visible without
  // going looking for it.
  // Housekeeping also runs from the tracking beacon; doing it here means a
  // quiet week with no app traffic still gets its purge when you look.
  void maybePurge();

  const errors = await getErrorStats();
  const who = adminSession.email;

  return (
    <div className="flex min-h-screen" style={{ background: "var(--color-surface-dim)" }}>
      <aside
        className="sticky top-0 hidden h-screen w-60 shrink-0 flex-col border-r md:flex"
        style={{ borderColor: "var(--color-border)", background: "var(--color-surface)" }}
      >
        <div className="flex h-16 items-center gap-2.5 px-4">
          <span
            aria-hidden
            className="size-8 shrink-0 rounded-xl"
            style={{ background: "var(--brand-mark)", boxShadow: `0 8px 24px -6px var(--brand-mark-glow)` }}
          />
          <span className="min-w-0">
            <span className="block text-sm font-bold leading-tight" style={{ color: "var(--color-foreground)" }}>
              Stillora
            </span>
            <span
              className="block text-[10px] font-bold uppercase tracking-[0.18em]"
              style={{ color: "var(--color-primary)" }}
            >
              Admin
            </span>
          </span>
        </div>

        <AdminNav errorCount={errors.open} />

        <div className="border-t p-3" style={{ borderColor: "var(--color-border)" }}>
          {who ? (
            <p className="mb-2 truncate px-3 text-[11px]" style={{ color: "var(--color-muted)" }} title={who}>
              {who}
            </p>
          ) : null}
          <p className="mb-2 px-3 text-[11px]" style={{ color: "var(--color-muted-strong)" }}>
            Data older than {Math.round(RETENTION_DAYS / 30)} months is deleted
            automatically.
          </p>
          <AdminLogoutButton />
        </div>
      </aside>

      <div className="min-w-0 flex-1">
        {/* The sidebar collapses on phones; the same routes ride along here. */}
        <div
          className="sticky top-0 z-10 flex items-center gap-2 border-b backdrop-blur md:hidden"
          style={{ borderColor: "var(--color-border)", background: "var(--color-header)" }}
        >
          <span
            aria-hidden
            className="ml-3 size-7 shrink-0 rounded-lg"
            style={{ background: "var(--brand-mark)" }}
          />
          <AdminNav errorCount={errors.open} orientation="horizontal" />
        </div>

        <main className="overflow-x-hidden px-5 py-8 sm:px-8">
          <div className="mx-auto w-full max-w-[1400px] space-y-8">{children}</div>
        </main>
      </div>
    </div>
  );
}
