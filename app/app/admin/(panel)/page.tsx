import Link from "next/link";

import { getStats, getUsersPage, getRecentExports } from "@/lib/admin-store";
import type { UserRecord, ExportRecord } from "@/lib/admin-store";

export const dynamic = "force-dynamic";

// The dashboard is a summary: it shows only the first page of users (the full,
// paginated list lives at /admin/users). getUsersPage bounds the query to 10
// rows + a COUNT, instead of loading every user row just to slice 10.
const USERS_PREVIEW = 10;

export default async function AdminDashboard() {
  const [stats, usersPage, exports] = await Promise.all([
    getStats(),
    getUsersPage(1, USERS_PREVIEW),
    getRecentExports(20),
  ]);

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold" style={{ color: "var(--color-foreground)" }}>
        Dashboard
      </h1>

      {/* Stat cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard label="Total Users" value={stats.totalUsers} color="var(--color-primary)" />
        <StatCard label="Total Exports" value={stats.totalExports} color="var(--color-secondary)" />
        <StatCard label="Exports Today" value={stats.exportsToday} color="var(--color-success)" />
      </div>

      {/* Users */}
      <section>
        <div className="mb-3 flex items-center justify-between gap-3">
          <h2 className="text-lg font-semibold" style={{ color: "var(--color-foreground)" }}>
            Users <span className="text-sm font-normal" style={{ color: "var(--color-muted)" }}>({usersPage.total})</span>
          </h2>
          {usersPage.total > USERS_PREVIEW ? <ViewAllLink href="/admin/users" /> : null}
        </div>
        <UsersTable users={usersPage.rows} />
      </section>

      {/* Recent exports */}
      <section>
        <div className="mb-3 flex items-center justify-between gap-3">
          <h2 className="text-lg font-semibold" style={{ color: "var(--color-foreground)" }}>
            Recent Exports
          </h2>
          {exports.length > 0 ? <ViewAllLink href="/admin/activity" /> : null}
        </div>
        <ExportsTable exports={exports} />
      </section>
    </div>
  );
}

function StatCard({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div
      className="rounded-xl border p-5"
      style={{
        background: "var(--color-card)",
        borderColor: "var(--color-border)",
      }}
    >
      <p className="text-sm font-medium" style={{ color: "var(--color-muted)" }}>{label}</p>
      <p className="mt-1 text-3xl font-bold" style={{ color }}>{value}</p>
    </div>
  );
}

function UsersTable({ users }: { users: UserRecord[] }) {
  if (users.length === 0) {
    return <Empty text="No users yet. Users appear after their first Google sign-in." />;
  }

  return (
    <div className="overflow-x-auto rounded-xl border" style={{ borderColor: "var(--color-border)" }}>
      <table className="w-full text-sm" style={{ background: "var(--color-card)" }}>
        <thead>
          <tr style={{ borderBottom: "1px solid var(--color-border)" }}>
            {["User", "Email", "First seen", "Last seen", "Exports"].map((h) => (
              <th
                key={h}
                className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide"
                style={{ color: "var(--color-muted)" }}
              >
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {users.map((u) => (
            <tr
              key={u.sub}
              className="transition"
              style={{ borderBottom: "1px solid var(--color-border-subtle)" }}
            >
              <td className="px-4 py-3">
                <div className="flex items-center gap-2">
                  {u.picture ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={u.picture} alt="" className="size-7 rounded-full" referrerPolicy="no-referrer" />
                  ) : (
                    <span
                      className="grid size-7 place-items-center rounded-full text-xs font-bold"
                      style={{ background: "var(--color-primary)", color: "#fff" }}
                    >
                      {u.name.charAt(0).toUpperCase()}
                    </span>
                  )}
                  <span style={{ color: "var(--color-foreground)" }}>{u.name}</span>
                </div>
              </td>
              <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>{u.email}</td>
              <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>{fmtDate(u.firstSeen)}</td>
              <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>{fmtDate(u.lastSeen)}</td>
              <td className="px-4 py-3 font-semibold" style={{ color: "var(--color-secondary)" }}>{u.exportCount}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ExportsTable({ exports: rows }: { exports: ExportRecord[] }) {
  if (rows.length === 0) {
    return <Empty text="No exports yet." />;
  }

  return (
    <div className="overflow-x-auto rounded-xl border" style={{ borderColor: "var(--color-border)" }}>
      <table className="w-full text-sm" style={{ background: "var(--color-card)" }}>
        <thead>
          <tr style={{ borderBottom: "1px solid var(--color-border)" }}>
            {["User", "Preset", "Duration", "Time"].map((h) => (
              <th
                key={h}
                className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide"
                style={{ color: "var(--color-muted)" }}
              >
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((e) => (
            <tr key={e.id} style={{ borderBottom: "1px solid var(--color-border-subtle)" }}>
              <td className="px-4 py-3" style={{ color: "var(--color-foreground)" }}>{e.userName}</td>
              <td className="px-4 py-3">
                <span
                  className="rounded-full px-2 py-0.5 text-xs font-semibold"
                  style={{ background: "var(--color-primary-soft)", color: "var(--color-primary)" }}
                >
                  {e.presetId}
                </span>
              </td>
              <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>{e.duration}s</td>
              <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>{fmtDate(e.timestamp)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ViewAllLink({ href }: { href: string }) {
  return (
    <Link
      href={href}
      className="shrink-0 text-sm font-semibold transition hover:underline"
      style={{ color: "var(--color-primary)" }}
    >
      View all →
    </Link>
  );
}

function Empty({ text }: { text: string }) {
  return (
    <p className="rounded-xl border px-4 py-8 text-center text-sm" style={{ borderColor: "var(--color-border)", color: "var(--color-muted)" }}>
      {text}
    </p>
  );
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
