"use client";

import { useState, useRef, useEffect } from "react";
import Link from "next/link";
import { ChevronDown, ChevronRight, LayoutDashboard, LogOut, Trash2, Users, Activity } from "lucide-react";
import type { SessionUser } from "./use-session";

type Props = {
  user: SessionUser;
  isAdmin: boolean;
};

export function UserMenu({ user, isAdmin }: Props) {
  const [open, setOpen] = useState(false);
  const [adminOpen, setAdminOpen] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function onClickOutside(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", onClickOutside);
    return () => document.removeEventListener("mousedown", onClickOutside);
  }, []);

  async function signOut() {
    await fetch("/api/auth/signout", { method: "POST" });
    window.location.reload();
  }

  async function deleteAccount() {
    setDeleting(true);
    await fetch("/api/auth/delete-account", { method: "DELETE" });
    window.location.reload();
  }

  return (
    <div ref={ref} className="relative">
      {/* Trigger */}
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="flex items-center gap-2 rounded-full border px-2 py-1 transition hover:opacity-80 focus:outline-none focus:ring-2"
        style={{ borderColor: "var(--color-border)" }}
        aria-haspopup="true"
        aria-expanded={open}
      >
        {user.picture ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={user.picture}
            alt={user.name}
            className="size-7 rounded-full"
            referrerPolicy="no-referrer"
          />
        ) : (
          <span
            className="grid size-7 place-items-center rounded-full text-xs font-bold"
            style={{ background: "var(--color-primary)", color: "#fff" }}
          >
            {user.name.charAt(0).toUpperCase()}
          </span>
        )}
        <ChevronDown
          size={14}
          className="transition-transform"
          style={{
            color: "var(--color-muted)",
            transform: open ? "rotate(180deg)" : "rotate(0deg)",
          }}
        />
      </button>

      {/* Dropdown */}
      {open && (
        <div
          className="absolute right-0 top-full z-50 mt-2 w-60 rounded-xl border shadow-xl"
          style={{
            background: "var(--color-card-high)",
            borderColor: "var(--color-border)",
            boxShadow: "var(--shadow-card)",
          }}
        >
          {/* User info */}
          <div className="flex items-center gap-3 border-b px-4 py-3" style={{ borderColor: "var(--color-border)" }}>
            {user.picture ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={user.picture} alt="" className="size-9 rounded-full shrink-0" referrerPolicy="no-referrer" />
            ) : (
              <span
                className="grid size-9 place-items-center rounded-full text-sm font-bold shrink-0"
                style={{ background: "var(--color-primary)", color: "#fff" }}
              >
                {user.name.charAt(0).toUpperCase()}
              </span>
            )}
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold" style={{ color: "var(--color-foreground)" }}>
                {user.name}
              </p>
              <p className="truncate text-xs" style={{ color: "var(--color-muted)" }}>
                {user.email}
              </p>
            </div>
          </div>

          {/* Admin section */}
          {isAdmin && (
            <div className="border-b" style={{ borderColor: "var(--color-border)" }}>
              <button
                type="button"
                onClick={() => setAdminOpen((v) => !v)}
                className="flex w-full items-center gap-2 px-4 py-2.5 text-left text-xs font-bold uppercase tracking-wider transition hover:opacity-80"
                style={{ color: "var(--color-primary)" }}
              >
                <LayoutDashboard size={13} />
                Admin
                <ChevronRight
                  size={13}
                  className="ml-auto transition-transform"
                  style={{ transform: adminOpen ? "rotate(90deg)" : "rotate(0deg)" }}
                />
              </button>

              {adminOpen && (
                <div className="pb-1 pl-4">
                  <MenuLink href="/admin" icon={<LayoutDashboard size={14} />} onClick={() => setOpen(false)}>
                    Dashboard
                  </MenuLink>
                  <MenuLink href="/admin/users" icon={<Users size={14} />} onClick={() => setOpen(false)}>
                    Users
                  </MenuLink>
                  <MenuLink href="/admin/activity" icon={<Activity size={14} />} onClick={() => setOpen(false)}>
                    Activity
                  </MenuLink>
                </div>
              )}
            </div>
          )}

          {/* Sign out + Delete account */}
          <div className="p-1.5">
            <button
              type="button"
              onClick={signOut}
              className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium transition hover:opacity-80"
              style={{ color: "var(--color-danger)" }}
            >
              <LogOut size={14} />
              Sign out
            </button>
            <button
              type="button"
              onClick={() => setConfirmDelete(true)}
              className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium transition hover:opacity-80"
              style={{ color: "var(--color-muted)" }}
            >
              <Trash2 size={14} />
              Delete account
            </button>
          </div>
        </div>
      )}
      {/* Delete account confirmation modal */}
      {confirmDelete && (
        <div
          className="fixed inset-0 z-[100] flex items-center justify-center p-4"
          style={{ background: "rgba(0,0,0,0.6)" }}
        >
          <div
            className="w-full max-w-sm rounded-2xl border p-6 shadow-2xl"
            style={{ background: "var(--color-card-high)", borderColor: "var(--color-border)" }}
          >
            <h2 className="mb-2 text-base font-semibold" style={{ color: "var(--color-foreground)" }}>
              Delete your account?
            </h2>
            <p className="mb-5 text-sm" style={{ color: "var(--color-muted)" }}>
              This will permanently delete your account and all associated data. This action cannot be undone.
            </p>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setConfirmDelete(false)}
                disabled={deleting}
                className="flex-1 rounded-lg border px-4 py-2 text-sm font-medium transition hover:opacity-80 disabled:opacity-50"
                style={{ borderColor: "var(--color-border)", color: "var(--color-foreground)" }}
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={deleteAccount}
                disabled={deleting}
                className="flex-1 rounded-lg px-4 py-2 text-sm font-medium text-white transition hover:opacity-80 disabled:opacity-50"
                style={{ background: "var(--color-danger)" }}
              >
                {deleting ? "Deleting…" : "Delete account"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function MenuLink({
  href,
  icon,
  children,
  onClick,
}: {
  href: string;
  icon: React.ReactNode;
  children: React.ReactNode;
  onClick?: () => void;
}) {
  return (
    <Link
      href={href}
      onClick={onClick}
      className="flex items-center gap-2 rounded-lg px-3 py-2 text-sm transition hover:opacity-80"
      style={{ color: "var(--color-muted)" }}
    >
      {icon}
      {children}
    </Link>
  );
}
