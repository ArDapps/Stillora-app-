# Stillora App Store Listing

Copy-ready metadata for App Store Connect. Covers **iOS, iPadOS and macOS from one app record** — the two platforms share the bundle ID `app.loopara.stillora`, so this is a single Universal Purchase listing, not two.

See [../googleplay/play-store-listing.md](../googleplay/play-store-listing.md) for the Play version. **Do not reuse this copy there** — five tools advertised below are hidden on Android (see [Platform differences](#platform-differences)).

---

## ⚠️ Blockers before submitting

1. **In-app purchase is not implemented yet.** This copy advertises Stillora Pro. Apple rejects listings describing features the binary doesn't have, and a non-functional IAP fails review outright. Ship billing first — see the store-setup checklist.
2. **The free export ceiling is now 720p.** Earlier marketing said "up to 4K" as a free claim. That is no longer true: 1080p / 2K / 4K are Pro. Do not carry the old line over.
3. **Paid Applications agreement must be Active** or the IAP won't load for the reviewer, which is an automatic rejection.

---

## App Information

| Field | Value |
| --- | --- |
| Bundle ID | `app.loopara.stillora` |
| Platforms | iOS, iPadOS, macOS (Universal Purchase — one record) |
| Primary category | Photo & Video |
| Secondary category | Utilities |
| Age rating | 4+ |
| Price | Free, with In-App Purchases |
| Default language | English (U.S.) |

---

## App Name

**Recommended — 8 / 30**

```
Stillora
```

If you want the ASO weight, Apple permits a short descriptor. Both fit:

| Option | Chars |
| --- | --- |
| `Stillora` | 8 |
| `Stillora: Video Toolkit` | 23 |
| `Stillora — Private Video Kit` | 28 |

Keep whichever you pick stable; renaming resets some ASO signal.

---

## Subtitle

**30 / 30 — exactly at the limit**

```
Video Maker, Compress, Convert
```

Leads with the three highest-volume search terms the app genuinely serves. Alternatives if you'd rather lead on positioning than search:

| Option | Chars |
| --- | --- |
| `Video Maker, Compress, Convert` | 30 |
| `Private Media Toolkit` | 21 |
| `Photo to Video, On Your Device` | 30 |

---

## Promotional Text

**162 / 170** — editable any time **without** a new review, so use it for price changes and launches.

```
Every tool runs on your device — nothing is uploaded. Free forever with no watermark. Unlock 1080p, 2K and 4K plus advanced controls once, and keep them for good.
```

---

## Keywords

**97 / 100** — comma-separated, no spaces after commas. Words already in the app name, subtitle, or category are indexed automatically and are deliberately **not** repeated here.

```
photo,image,slideshow,mp4,reel,shorts,watermark,silence,trim,speed,pdf,heic,offline,private,batch
```

---

## Description

**1,553 / 4,000**

```
Stillora is a private media toolkit. Every tool runs on your device — your photos, videos and audio are never uploaded to a server to be processed, and nothing you export carries a Stillora watermark.

CREATE
• Turn images and clips into a video sized for Reels, Shorts, TikTok or YouTube
• Add captions and titles over any video
• Loop images into a slideshow
• Turn a web page into a video clip

VIDEO TOOLS
• Add a logo or watermark
• Cut the silent gaps out of a recording
• Speed a video up
• Compress a video down to a smaller file
• Convert HEIC and other formats to JPEG or PNG

DOCUMENTS
• Combine images and PDFs into a single PDF

YOUR CONTENT
• Every render you make is saved to a library on your device

FREE FOREVER
All of the above is free. No account is required to start, nothing is watermarked, and there is no trial that expires and locks the app. Free exports go up to 720p.

STILLORA PRO — ONE PAYMENT, NO SUBSCRIPTION
• 1080p, 2K and 4K exports
• Higher bitrate and advanced export controls
• Advanced tool controls, including silence thresholds and custom settings
• Premium presets
• No ads, permanently

Buy it once and it stays unlocked. Because Stillora is a Universal Purchase, buying on your iPhone unlocks your Mac as well — and the other way around — at no extra cost.

PRIVACY IS NOT A PAID FEATURE
On-device processing, no cloud upload, and watermark-free exports are identical on Free and Pro, and always will be. Pro buys you more power — higher quality, finer control, faster workflows — not access to your own files.
```

---

## What's New

**For the release that introduces Pro. 420 / 4,000**

```
Stillora is now a full private media toolkit, reorganised so every tool is easier to find: Create, Video Tools, Document Tools and your Library each have their own section.

New in this release:
• Stillora Pro — a one-time purchase that unlocks 1080p, 2K and 4K exports, advanced controls, and removes ads for good. No subscription.
• Buy once on iPhone and it unlocks on Mac too.
• Everything still runs on your device.
```

---

## In-App Purchase metadata

Entered on the product itself in App Store Connect, not the listing. Product ID must match `ProConfig.fromEnvironment.productId` in the app. Full product, payment and sandbox setup: [pro-in-app-purchase.md](pro-in-app-purchase.md).

| Field | Value | Limit |
| --- | --- | --- |
| Type | **Non-Consumable** | — |
| Reference name | `Stillora Pro Lifetime` | internal |
| Product ID | `stillora_pro_lifetime` | must match code |
| Display name | `Stillora Pro — Lifetime` | 23 / 30 |
| Description | `Unlock 4K exports, advanced tools, no ads.` | 42 / 45 |
| Price | $19.99 (Tier 20) | — |

---

## URLs

| Field | Value |
| --- | --- |
| Privacy Policy URL | `https://stillora.loopara.app/privacy` |
| Terms of Use (EULA) | `https://stillora.loopara.app/terms` |
| Support URL | `https://stillora.loopara.app` |
| Marketing URL | `https://stillora.loopara.app` |

`privacyUrl`, `termsUrl` and `reviewUrl` are already defined in `AppConstants`, so the in-app links and the listing agree.

---

## App Privacy

Answer against what the shipping app actually does. Media never leaves the device, so it is **not collected** — do not over-declare, it costs you the privacy label you've earned.

| Data type | Collected | Notes |
| --- | --- | --- |
| Photos or Videos | **No** | Selected media is processed on device and never uploaded. |
| Audio Data | **No** | Narration is recorded and mixed locally. |
| Files and Docs | **No** | Same — local only. |
| Email Address | **Yes**, if the user signs in | Optional Google / Apple sign-in. Linked to identity. Not used for tracking. |
| Name | **Yes**, if the user signs in | Same. |
| Product Interaction | **Yes** | Buffered on device, flushed to the backend roughly every 12h. Not linked to identity. |
| Purchases | **Yes** | Store-side purchase record for the lifetime unlock. |
| Identifiers / Advertising Data | **Verify** | The Loopara ad banner reports the running OS. Confirm whether it sets any device identifier before answering — if it does, declare it. |

> Ads are shown to Free users only and disappear permanently after the Pro purchase.

---

## Review notes

Paste into App Review Information. This pre-empts the two rejections this app is most likely to get.

```
No account is required. Sign-in is optional and no feature is behind it — the reviewer can open the app and use every tool immediately.

All media processing happens on the device. The app does not upload user photos, video or audio to a server.

IN-APP PURCHASE
"Stillora Pro — Lifetime" (stillora_pro_lifetime) is a one-time non-consumable, not a subscription. It unlocks 1080p/2K/4K exports, advanced tool controls, and removes ads.

To test: open Stillora Pro from the bottom of the navigation, or pick any resolution above 720p in a tool — the upgrade page opens with the price and a Restore Purchase button.

The app is a Universal Purchase across iOS and macOS. The unlock bought on one platform is reported on the other through the store's entitlement query.
```

---

## Platform differences

The App Store listing may advertise the full toolkit. **The Play listing may not** — `AppSection.isAvailable` hides five tools on Android:

| Tool | iOS / macOS | Android |
| --- | --- | --- |
| Create, Loop Images, HTML, Convert, PDF, Library | ✅ | ✅ |
| Text, Watermark, Remove Silence, Speed, Compress | ✅ | ❌ hidden |

---

## Claims audit

**Safe to publish:** on-device processing · no watermark on any export · no account needed · one-time purchase, no subscription · Universal Purchase across iPhone/iPad/Mac · 720p free · 1080p/2K/4K with Pro.

**Do not publish:**

- ~~"Up to 4K, free"~~ — 4K is Pro now. Superseded by this file; also correct it in [../marketing-brief/06-Accuracy-Flags.md](../marketing-brief/06-Accuracy-Flags.md).
- ~~"10,000+ videos exported", "4.9/5 rating"~~ — unverified placeholder metrics.
- ~~Any claim that every effect or transition appears in the export~~ — only Fade is baked into the final video today.
- ~~A subscription, free trial, or "$39.99/yr Pro"~~ — the shipping model is a single $19.99 lifetime purchase.
