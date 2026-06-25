"use client";

import { useEffect, useState } from "react";

// Loopara ad network — public, no-auth, CORS-enabled, so the browser calls it
// directly (no proxy needed).
const LOOPARA_BASE = "https://www.loopara.app";
// Campaign key used to fetch the ad pool. All campaigns sharing this key rotate
// together (we pick one at random per load).
const LOOPARA_KEY = "all";
// Traffic-source name reported on clicks and impressions for attribution.
const APP_KEY = "my-app";

type Promo = {
  id: string;
  name: string;
  image: string;
  link: string;
};

// `placement` is accepted for call-site compatibility but unused — the Loopara
// pool is always fetched with placement=app.
export function AdSlot({
  className,
}: {
  placement?: "HOME_BANNER" | "USER_DASHBOARD_LEFT";
  className?: string;
}) {
  const [promo, setPromo] = useState<Promo | null>(null);

  // Re-fetch the pool on every mount; never cache ad IDs across sessions.
  useEffect(() => {
    let cancelled = false;

    fetch(`${LOOPARA_BASE}/api/promos?key=${encodeURIComponent(LOOPARA_KEY)}`)
      .then((r) => (r.ok ? r.json() : []))
      .then((ads: Promo[]) => {
        if (cancelled || !Array.isArray(ads) || ads.length === 0) return;

        // Pick one ad at random.
        const chosen = ads[Math.floor(Math.random() * ads.length)];
        // Image paths come back relative (e.g. "/api/uploads/…"); resolve them
        // against the Loopara origin so the banner loads.
        const image =
          chosen.image && !/^https?:\/\//.test(chosen.image)
            ? `${LOOPARA_BASE}${chosen.image}`
            : chosen.image;
        setPromo({ ...chosen, image });

        // Report exactly one impression for the displayed ad. Prefer
        // sendBeacon so it survives navigation; fall back to keepalive fetch.
        const body = JSON.stringify({
          id: chosen.id,
          type: "impression",
          source: APP_KEY,
        });
        const trackUrl = `${LOOPARA_BASE}/api/promos/track`;
        if (typeof navigator !== "undefined" && navigator.sendBeacon) {
          navigator.sendBeacon(
            trackUrl,
            new Blob([body], { type: "application/json" })
          );
        } else {
          fetch(trackUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body,
            keepalive: true,
          }).catch(() => {});
        }
      })
      // On any failure render nothing — never show an error to the user.
      .catch(() => {});

    return () => {
      cancelled = true;
    };
  }, []);

  if (!promo) return null;

  // Always route clicks through the tracking endpoint, which 302-redirects to
  // the real destination. Never link to `promo.link` directly.
  const clickUrl = `${LOOPARA_BASE}/api/promos/click?id=${encodeURIComponent(
    promo.id
  )}&source=${encodeURIComponent(APP_KEY)}`;

  return (
    <div className={`mx-auto w-fit ${className ?? ""}`}>
      <a
        href={clickUrl}
        target="_blank"
        rel="noopener noreferrer sponsored"
        className="relative block overflow-hidden rounded-lg opacity-60 transition-opacity hover:opacity-85"
        style={{ boxShadow: "0 0 14px rgba(139,92,246,0.22)" }}
      >
        {promo.image ? (
          // Loopara serves a 320x100 "large banner" — render at that native
          // ratio so it fills edge-to-edge with no crop.
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={promo.image}
            alt={promo.name}
            className="h-[100px] w-[320px] max-w-full rounded-lg object-cover"
          />
        ) : (
          // Fallback styled text banner when the ad has no image.
          <span className="flex h-[100px] w-[320px] max-w-full items-center justify-center rounded-lg bg-gradient-to-r from-violet-600/30 to-fuchsia-600/30 px-6 text-center text-sm font-semibold text-white/90">
            {promo.name}
          </span>
        )}
        <span className="absolute bottom-1 right-1.5 rounded text-[9px] leading-none text-white/50">
          Sponsored
        </span>
      </a>
    </div>
  );
}
