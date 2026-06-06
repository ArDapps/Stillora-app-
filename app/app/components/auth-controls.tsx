"use client";

import { startGoogleSignIn, useSession } from "./use-session";
import { UserMenu } from "./user-menu";
import { isAdminEmail } from "@/lib/admin";

export function AuthControls({ callbackUrl = "/editor" }: { callbackUrl?: string }) {
  const { user, loading } = useSession();

  if (loading) {
    return <div className="size-9 animate-pulse rounded-full bg-[var(--color-card-high)]" aria-hidden />;
  }

  if (!user) {
    return (
      <button
        className="inline-flex items-center gap-2 rounded-md border border-[var(--color-border)] px-3 py-2 text-sm font-medium text-[var(--color-foreground)] transition hover:border-[var(--color-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]"
        onClick={() => startGoogleSignIn(callbackUrl)}
        type="button"
      >
        <GoogleGlyph />
        Sign in
      </button>
    );
  }

  return <UserMenu user={user} isAdmin={isAdminEmail(user.email)} />;
}

function GoogleGlyph() {
  return (
    <svg aria-hidden viewBox="0 0 24 24" width="16" height="16">
      <path
        fill="#EA4335"
        d="M12 10.2v3.9h5.5c-.24 1.42-1.66 4.17-5.5 4.17-3.3 0-6-2.74-6-6.12s2.7-6.12 6-6.12c1.88 0 3.14.8 3.86 1.48l2.63-2.53C16.9 2.86 14.66 2 12 2 6.97 2 2.9 6.07 2.9 11.1S6.97 20.2 12 20.2c5.8 0 9.64-4.07 9.64-9.8 0-.66-.07-1.16-.16-1.66H12z"
      />
    </svg>
  );
}
