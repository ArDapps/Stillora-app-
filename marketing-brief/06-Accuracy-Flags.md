# 06 · Accuracy Flags — READ BEFORE PUBLISHING

Places where the marketing copy is ahead of, or out of sync with, what the shipping app actually does. Verify each with engineering before making external claims.

---

## 🚩 1. "No account needed" — partly true
- **Copy says:** "Start Free — No Sign-up," "No account needed."
- **Reality (web):** Users can browse and set up a project without an account, **but uploading media and exporting require Google sign-in** (the export API returns 401 without auth).
- **Reality (mobile):** Sign-in (Google / Apple) is genuinely optional — guests can pick media, export, save, and share.
- **Safe framing:** "No account needed to start" (mobile) / "Free — sign in to export" (web). Avoid a flat "no account ever" for the web app.

## 🚩 2. Testimonials & stats appear to be placeholders
- "10,000+ videos exported," "4.9/5 rating," and the named creator quotes look like **sample/placeholder data**, not verified metrics.
- **Action:** Do not cite these externally until confirmed real. Replace with verified numbers or remove.

## 🚩 3. Pricing model — Free with ads, not subscriptions
- The live product has **no paywall and no Pro tier** anywhere in the code. Everything is currently free.
- Monetization is via **Loopara sponsored ad banners** inside the app.
- A **RevenueCat "Pro" plan** ($39.99/yr, 7-day trial, gating HTML→Video / Loop Images / Voice Narration) exists **only in a setup document** — it is **not wired into the shipping app**. Do not market a Pro tier or trial yet.

## 🚩 4. Feature availability varies by platform
- **Watermark** and **Remove Silence** are **desktop-only** right now (in-app copy: "iPhone & Android export is coming next").
- **Speed** is on desktop + iOS but **hidden on Android**.
- Don't imply these three work "everywhere." See [03-Platform-Matrix.md](03-Platform-Matrix.md).

## 🚩 5. Effects & transitions are mostly preview-only
- Create advertises effects (Glow, Ken Burns, Float, Shake) and many transitions. In the current export engine, **only Fade is baked into the final video**; the others are primarily in-app preview.
- Avoid promising that every effect/transition appears in the exported file until confirmed.

## 🚩 6. Minor copy inconsistency
- One place in the mobile UI still says "Desktop soon" while the main landing page now says desktop is Live. Worth aligning.

---

### Summary for the team
Solid, publishable claims today: **free · no watermark · on-device · up to 4K (mobile) · 6 platform presets · web + iOS + macOS + Android + Windows · images + video + audio in one MP4 · HTML → Video.**

Hold or verify: **exact "no account" wording on web · the 10K/4.9★ stats · any Pro/subscription messaging · full cross-platform claims for Watermark / Remove Silence / Speed · "every effect in your export."**
