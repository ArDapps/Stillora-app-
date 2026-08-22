import { getUsersPage } from "@/lib/admin-store";
import { getEntitlementsFor } from "@/lib/pro-store";
import { Pagination } from "../pagination";
import { ProControl, type ProState } from "./pro-control";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 25;

export default async function AdminUsersPage({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const sp = await searchParams;
  const pageRaw = Array.isArray(sp.page) ? sp.page[0] : sp.page;
  const users = await getUsersPage(pageRaw ? parseInt(pageRaw, 10) : 1, PAGE_SIZE);
  // One lookup for the whole page rather than a per-row query.
  const entitlements = await getEntitlementsFor(users.rows.map((u) => u.sub));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold" style={{ color: "var(--color-foreground)" }}>
          Users
        </h1>
        <span className="text-sm" style={{ color: "var(--color-muted)" }}>
          {users.total.toLocaleString()} total
        </span>
      </div>

      {users.total === 0 ? (
        <p className="rounded-xl border px-4 py-12 text-center text-sm" style={{ borderColor: "var(--color-border)", color: "var(--color-muted)" }}>
          No users yet. They appear after their first Google sign-in.
        </p>
      ) : (
        <>
        <div className="overflow-x-auto rounded-xl border" style={{ borderColor: "var(--color-border)" }}>
          <table className="w-full text-sm" style={{ background: "var(--color-card)" }}>
            <thead>
              <tr style={{ borderBottom: "1px solid var(--color-border)" }}>
                {["User", "Email", "Plan", "First seen", "Last active", "Exports"].map((h) => (
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
              {users.rows.map((u) => (
                <tr key={u.sub} style={{ borderBottom: "1px solid var(--color-border-subtle)" }}>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      {u.picture ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={u.picture} alt="" className="size-8 rounded-full" referrerPolicy="no-referrer" />
                      ) : (
                        <span
                          className="grid size-8 place-items-center rounded-full text-xs font-bold"
                          style={{ background: "var(--color-primary)", color: "#fff" }}
                        >
                          {u.name.charAt(0).toUpperCase()}
                        </span>
                      )}
                      <span className="font-medium" style={{ color: "var(--color-foreground)" }}>{u.name}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3" style={{ color: "var(--color-muted)" }}>{u.email}</td>
                  <td className="px-4 py-3 whitespace-nowrap">
                    <ProControl userSub={u.sub} state={proStateFor(entitlements.get(u.sub))} />
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap" style={{ color: "var(--color-muted)" }}>
                    {fmt(u.firstSeen)}
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap" style={{ color: "var(--color-muted)" }}>
                    {fmt(u.lastSeen)}
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className="rounded-full px-2.5 py-0.5 text-xs font-bold"
                      style={{ background: "var(--color-secondary-soft)", color: "var(--color-secondary)" }}
                    >
                      {u.exportCount}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <Pagination
          basePath="/admin/users"
          page={users.page}
          pageSize={users.pageSize}
          total={users.total}
        />
        </>
      )}
    </div>
  );
}

function proStateFor(
  entitlement: Awaited<ReturnType<typeof getEntitlementsFor>> extends Map<string, infer T>
    ? T | undefined
    : never,
): ProState {
  if (!entitlement) {
    return { source: null, active: false, grantedBy: "", note: "" };
  }
  return {
    source: entitlement.source,
    active: !entitlement.revokedAt,
    grantedBy: entitlement.grantedBy,
    note: entitlement.note,
  };
}

function fmt(iso: string) {
  return new Date(iso).toLocaleString("en-US", {
    month: "short", day: "numeric", year: "numeric",
    hour: "2-digit", minute: "2-digit",
  });
}
