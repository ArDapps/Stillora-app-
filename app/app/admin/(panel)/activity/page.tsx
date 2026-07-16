import { getExportsPage, getStats } from "@/lib/admin-store";
import { Pagination } from "../pagination";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 25;

export default async function AdminActivityPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string }>;
}) {
  const { page } = await searchParams;
  const [exports, stats] = await Promise.all([
    getExportsPage(page ? parseInt(page, 10) : 1, PAGE_SIZE),
    getStats(),
  ]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold" style={{ color: "var(--color-foreground)" }}>
          Activity
        </h1>
        <div className="flex gap-4 text-sm" style={{ color: "var(--color-muted)" }}>
          <span>
            <b style={{ color: "var(--color-secondary)" }}>{stats.exportsToday}</b> today
          </span>
          <span>
            <b style={{ color: "var(--color-primary)" }}>{stats.totalExports}</b> total
          </span>
        </div>
      </div>

      {exports.total === 0 ? (
        <p className="rounded-xl border px-4 py-12 text-center text-sm" style={{ borderColor: "var(--color-border)", color: "var(--color-muted)" }}>
          No exports recorded yet.
        </p>
      ) : (
        <>
        <div className="overflow-x-auto rounded-xl border" style={{ borderColor: "var(--color-border)" }}>
          <table className="w-full text-sm" style={{ background: "var(--color-card)" }}>
            <thead>
              <tr style={{ borderBottom: "1px solid var(--color-border)" }}>
                {["User", "Email", "Preset", "Duration", "Time"].map((h) => (
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
              {exports.rows.map((e) => (
                <tr key={e.id} style={{ borderBottom: "1px solid var(--color-border-subtle)" }}>
                  <td className="px-4 py-3 font-medium" style={{ color: "var(--color-foreground)" }}>{e.userName}</td>
                  <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>{e.userEmail}</td>
                  <td className="px-4 py-3">
                    <span
                      className="rounded-full px-2 py-0.5 text-xs font-semibold"
                      style={{ background: "var(--color-primary-soft)", color: "var(--color-primary)" }}
                    >
                      {e.presetId}
                    </span>
                  </td>
                  <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>{e.duration}s</td>
                  <td className="px-4 py-3 whitespace-nowrap" style={{ color: "var(--color-muted)" }}>
                    {fmt(e.timestamp)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <Pagination
          basePath="/admin/activity"
          page={exports.page}
          pageSize={exports.pageSize}
          total={exports.total}
        />
        </>
      )}
    </div>
  );
}

function fmt(iso: string) {
  return new Date(iso).toLocaleString("en-US", {
    month: "short", day: "numeric", year: "numeric",
    hour: "2-digit", minute: "2-digit",
  });
}
