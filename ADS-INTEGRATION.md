# Ads Integration Guide — md.loopara.app

All ads are managed in one place: **md.loopara.app/admin**  
Any website or app can display them by calling the public API.

---

## How It Works

```
Admin (md.loopara.app/admin)
  └── creates / edits / activates campaigns
        └── API (md.loopara.app/api/campaigns)
              ├── Your Website A  →  shows ad
              ├── Your Website B  →  shows ad
              └── Any other app   →  shows ad
```

- Admin controls which ads are active, what image, where they link.
- Every app just fetches from the same API — no setup needed per app.
- Impressions and clicks are tracked automatically back to the admin dashboard.

---

## Placements

| Placement key          | Use for                        | Image ratio |
|------------------------|-------------------------------|-------------|
| `HOME_BANNER`          | Wide banner across the top     | 16:9        |
| `USER_DASHBOARD_LEFT`  | Tall card on the left sidebar  | 4:5         |

---

## API Reference

### 1. Get active campaigns

```
GET https://md.loopara.app/api/campaigns?placement=HOME_BANNER
```

Returns up to 3 active campaigns for that placement.

> **Important:** `imageUrl` is a relative path (e.g. `/api/campaign-assets/abc.png`).
> External apps must prepend `https://md.loopara.app` to build the full image URL.
> ```js
> const fullImageUrl = 'https://md.loopara.app' + campaign.imageUrl;
> ```

**Response:**
```json
{
  "campaigns": [
    {
      "id": "cm1abc123",
      "title": "Campaign Title",
      "imageUrl": "/api/campaign-assets/abc123.png",
      "targetUrl": "https://advertiser-site.com",
      "placement": "HOME_BANNER"
    }
  ]
}
```

### 2. Record an impression (ad was shown)

```
POST https://md.loopara.app/api/campaigns/{id}/impression
```

Call this as soon as the ad becomes visible. No body needed.

### 3. Record a click (user clicked the ad)

```
GET https://md.loopara.app/api/campaigns/{id}/click
```

Use this as the `href` on the ad link — it records the click then redirects the user to the advertiser's site automatically.

---

## Integration: Plain HTML / Any Website

Copy this snippet into any page. Change `HOME_BANNER` to whichever placement fits.

```html
<div id="ad-slot"></div>

<script>
(function () {
  const API = 'https://md.loopara.app';
  const PLACEMENT = 'HOME_BANNER'; // or USER_DASHBOARD_LEFT

  fetch(API + '/api/campaigns?placement=' + PLACEMENT)
    .then(function (r) { return r.json(); })
    .then(function (data) {
      var campaign = data.campaigns && data.campaigns[0];
      if (!campaign) return;

      // record impression
      fetch(API + '/api/campaigns/' + campaign.id + '/impression', { method: 'POST' });

      // render ad
      var imageUrl = API + campaign.imageUrl; // imageUrl is relative — must prepend domain
      var slot = document.getElementById('ad-slot');
      slot.innerHTML =
        '<a href="' + API + '/api/campaigns/' + campaign.id + '/click" target="_blank" rel="noopener" ' +
        'style="display:block;text-decoration:none;">' +
          '<img src="' + imageUrl + '" alt="' + campaign.title + '" ' +
          'style="width:100%;border-radius:8px;display:block;" />' +
          '<p style="font-size:12px;color:#888;margin:4px 0 0;">Sponsored</p>' +
        '</a>';
    });
})();
</script>
```

---

## Integration: React / Next.js

```tsx
import { useEffect, useState } from "react";

type Campaign = {
  id: string;
  title: string;
  imageUrl: string;
  targetUrl: string;
};

const API = "https://md.loopara.app";

export function AdSlot({ placement }: { placement: "HOME_BANNER" | "USER_DASHBOARD_LEFT" }) {
  const [campaign, setCampaign] = useState<Campaign | null>(null);

  useEffect(() => {
    fetch(`${API}/api/campaigns?placement=${placement}`)
      .then((r) => r.json())
      .then((data) => {
        const c = data.campaigns?.[0] ?? null;
        setCampaign(c);
        if (c) {
          fetch(`${API}/api/campaigns/${c.id}/impression`, { method: "POST" });
        }
      });
  }, [placement]);

  if (!campaign) return null;

  const imageUrl = `${API}${campaign.imageUrl}`; // imageUrl is relative — prepend domain

  return (
    <a
      href={`${API}/api/campaigns/${campaign.id}/click`}
      target="_blank"
      rel="noopener noreferrer"
      style={{ display: "block" }}
    >
      <img src={imageUrl} alt={campaign.title} style={{ width: "100%" }} />
      <p style={{ fontSize: 12, color: "#888" }}>Sponsored</p>
    </a>
  );
}
```

Usage:
```tsx
<AdSlot placement="HOME_BANNER" />
<AdSlot placement="USER_DASHBOARD_LEFT" />
```

---

## Integration: Vue / Nuxt

```vue
<template>
  <a
    v-if="campaign"
    :href="`${API}/api/campaigns/${campaign.id}/click`"
    target="_blank"
    rel="noopener noreferrer"
  >
    <img :src="campaign.imageUrl" :alt="campaign.title" style="width:100%" />
    <p style="font-size:12px;color:#888">Sponsored</p>
  </a>
</template>

<script setup>
import { ref, onMounted } from "vue";

const API = "https://md.loopara.app";
const props = defineProps({ placement: String });
const campaign = ref(null);

onMounted(async () => {
  const r = await fetch(`${API}/api/campaigns?placement=${props.placement}`);
  const data = await r.json();
  campaign.value = data.campaigns?.[0] ?? null;
  if (campaign.value) {
    campaign.value.imageUrl = API + campaign.value.imageUrl; // make absolute
    fetch(`${API}/api/campaigns/${campaign.value.id}/impression`, { method: "POST" });
  }
});
</script>
```

---

## Integration: Vanilla JavaScript (No Framework)

```js
async function loadAd(containerId, placement) {
  const API = 'https://md.loopara.app';
  const res = await fetch(`${API}/api/campaigns?placement=${placement}`);
  const { campaigns } = await res.json();
  const c = campaigns?.[0];
  if (!c) return;

  fetch(`${API}/api/campaigns/${c.id}/impression`, { method: 'POST' });

  const imageUrl = API + c.imageUrl; // imageUrl is relative — prepend domain
  document.getElementById(containerId).innerHTML = `
    <a href="${API}/api/campaigns/${c.id}/click" target="_blank" rel="noopener">
      <img src="${imageUrl}" alt="${c.title}" style="width:100%;border-radius:8px" />
      <small style="color:#888">Sponsored</small>
    </a>
  `;
}

// Call it anywhere:
loadAd('my-ad-container', 'HOME_BANNER');
```

---

## Admin: Where to Manage Everything

Go to **md.loopara.app/admin** → Campaigns tab.

From there you can:
- Create a new campaign (title, image, destination URL, placement)
- Activate or deactivate any campaign instantly — all apps update immediately
- See impressions, clicks, and CTR per campaign
- See a full event log (who saw/clicked, when, from which placement)

No code change needed in any app when you update a campaign — the API always returns the latest active campaigns.

---

## Notes

- The API is public and read-only for fetching campaigns. Only the admin panel can create/edit/delete.
- If no active campaign exists for a placement, the API returns an empty array — your ad slot stays hidden automatically.
- Clicks go through `md.loopara.app/api/campaigns/{id}/click` which records the event then redirects. The user always ends up at the advertiser's site.
