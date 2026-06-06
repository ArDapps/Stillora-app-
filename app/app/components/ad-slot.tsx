"use client";

import { useEffect, useState } from "react";

// All ad API calls go through the local proxy rewrite (/ad-api → https://md.loopara.app/api)
// to avoid CORS issues when fetching from the browser.
const AD_PROXY = "/ad-api";
const AD_ORIGIN = "https://md.loopara.app";

type Campaign = {
  id: string;
  title: string;
  imageUrl: string;
};

export function AdSlot({
  placement,
  className,
}: {
  placement: "HOME_BANNER" | "USER_DASHBOARD_LEFT";
  className?: string;
}) {
  const [campaign, setCampaign] = useState<Campaign | null>(null);

  useEffect(() => {
    fetch(`${AD_PROXY}/campaigns?placement=${placement}`)
      .then((r) => r.json())
      .then((data) => {
        const c: Campaign | undefined = data.campaigns?.[0];
        if (!c) return;
        // Image URLs are relative paths on md.loopara.app — serve them via the proxy.
        const imageUrl = c.imageUrl.startsWith("/")
          ? `${AD_PROXY}${c.imageUrl.slice("/api".length)}`
          : c.imageUrl;
        setCampaign({ ...c, imageUrl });
        fetch(`${AD_PROXY}/campaigns/${c.id}/impression`, { method: "POST" }).catch(
          () => {}
        );
      })
      .catch(() => {});
  }, [placement]);

  if (!campaign) return null;

  return (
    <div className={className}>
      <a
        href={`${AD_ORIGIN}/api/campaigns/${campaign.id}/click`}
        target="_blank"
        rel="noopener noreferrer"
        className="block"
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={campaign.imageUrl}
          alt={campaign.title}
          className="w-full rounded-lg object-cover"
        />
        <p className="mt-1 text-xs text-muted-foreground">Sponsored</p>
      </a>
    </div>
  );
}
