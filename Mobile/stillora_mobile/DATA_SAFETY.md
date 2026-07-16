# Data Safety & Privacy Disclosure — Stillora

This document is the source of truth for the **App Store privacy "nutrition
label"** and the **Google Play Data safety** form. It reflects what the app
actually collects as of the analytics/usage-tracking feature.

> Scope: this covers first-party collection by Stillora (auth + usage
> analytics). Third-party SDKs — **AdMob** (ads) and **RevenueCat** (purchases) —
> collect additional data under their own disclosures; their rows are marked
> below and must be kept in sync with those SDKs' published guidance.

---

## What Stillora collects (first-party)

| Data | Purpose | Linked to user? | Persistent ID? | Where |
|------|---------|-----------------|----------------|-------|
| Email address | Account sign-in (Google / Apple) | Yes | — | On sign-in |
| Name | Account display | Yes | — | On sign-in |
| Approximate location (country / region / city) | Analytics | Yes (when signed in) | No | Derived server-side from IP; **raw IP is not stored — only a salted hash** |
| Product interaction / usage (session start & end, time-in-app, platform, app version) | Analytics | Yes (when signed in) | Session-scoped id only | `/api/track` beacons |
| Export events (preset, output duration) | Analytics | Yes | — | `/api/exports/record` |
| Device / OS / browser (coarse, from User-Agent) | Analytics | Yes | No | `/api/track` |

**Not collected by Stillora:** precise/GPS location, contacts, photos library
metadata sent to our servers (media is processed on-device), health, financial
info, message contents, or a persistent advertising identifier.

---

## Apple App Store — Privacy "Nutrition Label"

Configure in **App Store Connect → App Privacy**.

### Data Used to Track You
- **None** from Stillora's own analytics (we do not track across other
  companies' apps/sites, and do not share data with data brokers).
- ⚠️ If **AdMob** serves personalized ads, Apple treats the **Device ID /
  Advertising Data** it uses as *Tracking*, which requires **App Tracking
  Transparency (ATT)** consent. If you only use non-personalized ads, you can
  avoid the Tracking bucket — confirm against your AdMob configuration.

### Data Linked to You
- **Contact Info** → Email Address, Name — *App Functionality*
- **Location** → Coarse Location — *Analytics*
- **Usage Data** → Product Interaction — *Analytics*
- **Identifiers** → User ID — *Analytics, App Functionality*

### Data Not Linked to You
- **Diagnostics** → none collected by first-party code.

> Purposes to select: **App Functionality** and **Analytics**. Do **not** check
> *Third-Party Advertising* or *Developer's Advertising* for first-party data.
> Those apply only to the AdMob SDK rows.

---

## Google Play — Data safety form

Configure in **Play Console → App content → Data safety**.

**Does your app collect or share user data?** Yes.
**Is all data encrypted in transit?** Yes (HTTPS/TLS).
**Do you provide a way to request data deletion?** Yes — in-app *Delete account*
(`/api/auth/delete-account`) and privacy policy contact.

### Data types — collected (not shared*)

| Category | Type | Collected | Shared | Ephemeral? | Required/Optional | Purpose |
|----------|------|-----------|--------|-----------|-------------------|---------|
| Personal info | Email address | ✅ | ❌ | No | Required | Account management |
| Personal info | Name | ✅ | ❌ | No | Required | Account management |
| Personal info | User IDs | ✅ | ❌ | No | Required | Account management, Analytics |
| Location | Approximate location | ✅ | ❌ | No | Required | Analytics |
| App activity | App interactions | ✅ | ❌ | No | Required | Analytics |
| App info & performance | Other app performance data | ⚠️ optional | ❌ | — | Optional | Analytics |

\* "Shared" = sent to third parties. Stillora's first-party analytics are **not
shared**. The **AdMob** and **RevenueCat** SDKs collect and may share their own
data — declare those rows per Google's
[AdMob Data safety guidance](https://support.google.com/admob/answer/11341544)
and RevenueCat's guidance.

### Typical AdMob rows to add (verify against your setup)
- **Device or other IDs** → Collected, Shared, purpose *Advertising or
  marketing, Analytics*.
- **Location → Approximate location** may also be collected by ads.

---

## Privacy-policy snippet (add to the published policy)

> **Usage analytics.** We collect anonymous-to-pseudonymous usage data to
> understand how Stillora is used and improve it. This includes: the approximate
> location (country, region, and city) derived from your IP address, your
> device platform, operating system, app version, and session activity (when you
> open and close the app and how long you use it). We do **not** store your raw
> IP address — it is converted to a non-reversible hash. When you are signed in,
> this activity is associated with your account; otherwise it is counted
> anonymously. We do not sell this data or use it to track you across other
> companies' apps or websites. You can request deletion of your account and
> associated data at any time from **Settings → Delete account**.

---

## Keeping this accurate

If you change what the app collects, update **both** this file and the store
listings. Key first-party collection points in code:

- `lib/core/analytics/usage_tracker.dart` — session start/heartbeat/end beacon
- `features/export/export_controller.dart` → `_reportExport` — export telemetry
- Backend: `app/app/api/track/route.ts`, `app/lib/geo.ts` (IP → coarse location,
  IP hashed, not stored raw)
