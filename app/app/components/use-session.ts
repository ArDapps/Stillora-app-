"use client";

import { useEffect, useState } from "react";

export type SessionUser = {
  sub: string;
  email: string;
  name: string;
  picture: string;
};

export function useSession() {
  const [user, setUser] = useState<SessionUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;

    fetch("/api/auth/me", { cache: "no-store" })
      .then((response) => response.json())
      .then((data: { user: SessionUser | null }) => {
        if (active) {
          setUser(data.user ?? null);
        }
      })
      .catch(() => {
        if (active) {
          setUser(null);
        }
      })
      .finally(() => {
        if (active) {
          setLoading(false);
        }
      });

    return () => {
      active = false;
    };
  }, []);

  return { user, loading };
}

export function startGoogleSignIn(callbackUrl = "/editor") {
  window.location.href = `/api/auth/google?callbackUrl=${encodeURIComponent(callbackUrl)}`;
}
