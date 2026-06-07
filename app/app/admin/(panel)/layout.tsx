import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentAdmin } from "@/lib/admin-server";
import { isAdminEmail } from "@/lib/admin";
import { getCurrentUser } from "@/lib/auth";
import { AdminLogoutButton } from "./logout-button";

export const metadata = { title: "Admin — Stillora" };

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const [adminSession, userSession] = await Promise.all([
    getCurrentAdmin(),
    getCurrentUser(),
  ]);

  const allowed =
    adminSession !== null ||
    (userSession !== null && isAdminEmail(userSession.email));

  if (!allowed) redirect("/admin/login");

  return (
    <div className="flex min-h-screen" style={{ background: "var(--color-surface-dim)" }}>
      {/* Sidebar */}
      <aside
        className="flex w-52 shrink-0 flex-col border-r"
        style={{ borderColor: "var(--color-border)", background: "var(--color-surface)" }}
      >
        <div
          className="flex h-14 items-center gap-2 border-b px-4"
          style={{ borderColor: "var(--color-border)" }}
        >
          <span
            className="text-xs font-extrabold uppercase tracking-widest"
            style={{ color: "var(--color-primary)" }}
          >
            Admin
          </span>
        </div>

        <nav className="flex flex-1 flex-col gap-0.5 p-2">
          <NavItem href="/admin">Dashboard</NavItem>
          <NavItem href="/admin/users">Users</NavItem>
          <NavItem href="/admin/activity">Activity</NavItem>
        </nav>

        <div className="border-t p-2" style={{ borderColor: "var(--color-border)" }}>
          <NavItem href="/editor">← App</NavItem>
          <AdminLogoutButton />
        </div>
      </aside>

      {/* Content */}
      <main className="flex-1 overflow-auto p-8">{children}</main>
    </div>
  );
}

function NavItem({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <Link
      href={href}
      className="rounded-md px-3 py-2 text-sm font-medium transition"
      style={{ color: "var(--color-muted)" }}
    >
      {children}
    </Link>
  );
}
