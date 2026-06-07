"use client";

export function AdminLogoutButton() {
  async function handleLogout() {
    await fetch("/api/admin/logout", { method: "POST" });
    window.location.href = "/";
  }

  return (
    <button
      onClick={handleLogout}
      type="button"
      className="w-full rounded-md px-3 py-2 text-left text-sm font-medium transition hover:opacity-80"
      style={{ color: "var(--color-danger)" }}
    >
      Sign out admin
    </button>
  );
}
