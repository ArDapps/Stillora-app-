# Stillora — Monetization (RevenueCat + AdMob)

## Ads (AdMob) — quick reference
Ads are wired up and **shown only to non-Pro users on iOS/Android** (Pro
subscribers, desktop and web see none):
- **Banner** — `AdSlotWidget` (in the editor, export, and desktop sidebar).
- **App-open ad** — shown on the splash screen at most **once every 4 hours**
  (`AdConfig.appOpenMinInterval`), skipped for Pro.

Currently using **Google TEST ad unit IDs** (safe for dev; you'll see a
"Test mode" badge). Before release, set your real IDs (publisher
`pub-2861157663948368`):
1. Native **App IDs** (required) — replace the TEST `ca-app-pub-3940256099942544~…`
   values in **`ios/Runner/Info.plist`** (`GADApplicationIdentifier`) and
   **`android/app/src/main/AndroidManifest.xml`** (`com.google.android.gms.ads.APPLICATION_ID`)
   with your real `ca-app-pub-2861157663948368~XXXXXXXXXX`.
2. **Ad unit IDs** — pass via `--dart-define` or edit defaults in
   `lib/core/constants/app_constants.dart` → `AdConfig`:
   `ADMOB_IOS_BANNER_ID`, `ADMOB_ANDROID_BANNER_ID`,
   `ADMOB_IOS_APP_OPEN_ID`, `ADMOB_ANDROID_APP_OPEN_ID`.
3. **app-ads.txt** — published at `app/public/app-ads.txt` (served at your web
   root). Make sure the domain matches the "developer website" on your store
   listing, then have AdMob crawl it.

⚠️ Never ship the TEST App IDs to production — real impressions on test IDs
violate AdMob policy. Tapping your own real ads also risks a ban.

---

# Stillora Pro — RevenueCat setup

The app already has the full paywall + gating wired up. It ships in **"free for
everyone"** mode: until you add real API keys the SDK is never configured and
`isPro` is always `false`, so the app still builds and runs and you can keep
developing. Once you finish the steps below, the paywall starts selling the
annual plan and Pro features unlock.

**Model:** Create, Library + Profile are free. HTML → Video, Loop Images, and
Voice Narration are Pro, behind a **7‑day free trial** on a single **annual**
subscription.

---

## What you need to do (one-time)

### 1. App Store Connect — create the subscription
1. App Store Connect → your app → **Subscriptions**.
2. Create a **Subscription Group** (e.g. `Stillora Pro`).
3. Add one **Auto‑Renewable Subscription**:
   - Product ID: `stillora_pro_annual` (suggested — any value is fine, you map it in RevenueCat).
   - Duration: **1 Year**.
   - Add an **Introductory Offer → Free Trial → 7 days**.
   - Set the price, localized display name, and description.
4. Fill in the subscription's review info / screenshot, and the app's
   **Paid Apps agreement** + banking/tax in *Agreements, Tax, and Banking*
   (StoreKit returns no products until this is active).
5. For local testing, create a **Sandbox tester** in
   *Users and Access → Sandbox*, or use a StoreKit Configuration file in Xcode.

### 2. RevenueCat dashboard
1. Create a project at https://app.revenuecat.com.
2. **Add app → App Store**, set the bundle id (`app.loopara.stillora`), and
   upload your **App Store Connect API key** (In‑App Purchase key) so RevenueCat
   can validate receipts.
3. **Products** → add a product with the App Store product id
   `stillora_pro_annual`.
4. **Entitlements** → create one with identifier **`pro`** and attach that
   product. *(The app reads `RevenueCatConfig.entitlementId`, default `pro`.)*
5. **Offerings** → in the **`default`** offering, add a package of type
   **Annual** pointing at the product. *(The app reads the `default` offering and
   its `annual` package.)*
6. **API keys** → copy the **public SDK key** for Apple App Store
   (starts with `appl_…`).

### 3. Put the key into the app
The key is read from a compile-time define (no secrets committed). Two options:

**A. Pass at build/run time (recommended):**
```bash
flutter run   --dart-define=REVENUECAT_IOS_API_KEY=appl_xxxxxxxxxxxxxxxxxxxx
flutter build ipa --dart-define=REVENUECAT_IOS_API_KEY=appl_xxxxxxxxxxxxxxxxxxxx
```
Add `--dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxxx` when you ship Android.

**B. Or set the default** in
`lib/core/constants/app_constants.dart` → `RevenueCatConfig.iosApiKey`
(replace `REPLACE_ME`). Simpler, but the key lands in source control.

Optional overrides (defaults are sensible, only set if you change names):
`REVENUECAT_ENTITLEMENT_ID` (default `pro`),
`REVENUECAT_OFFERING_ID` (default `default`).

### 4. Xcode capability
In Xcode → Runner target → **Signing & Capabilities** → add **In‑App Purchase**
if it isn't already there. (RevenueCat needs no extra entitlement beyond that.)

---

## How to test
1. Run with the `--dart-define` key on a **real device or a sandbox-logged-in
   simulator**.
2. Tap **HTML → Video / Loop Images**, or **Voice Narration** in the
   editor → the paywall appears.
3. Buy with a **sandbox** account → trial starts, the screen unlocks, and the
   Pro tabs open without the paywall.
4. **Restore purchases** (paywall + Profile) re-checks entitlements.

> The production Apple public SDK key (`appl_lGPnaixQCFadDWYctjtpvRSRjGq`) is now
> the default in `RevenueCatConfig.iosApiKey`, so no `--dart-define` is required.
> (Public SDK keys are meant to ship in the binary — they are not secrets.)

## Troubleshooting
- **`Invalid API Key` / `credentials issue` when fetching offerings** — the key
  value is wrong for this project. Re-copy it from RevenueCat → **API keys**
  (make sure there's no trailing space, and that it matches the platform: Test
  Store key for dev, `appl_…` for the real Apple App Store app). The app handles
  this gracefully (paywall shows fallback copy, everyone stays non-Pro), so it
  never crashes — but the live price/offering won't load until the key is valid.
- **`Error fetching offerings — error 1` / "offerings are empty"
  (rev.cat/why-are-offerings-empty)** — the key is valid but StoreKit has no
  buyable products yet. Fix all of: (1) **Agreements, Tax & Banking** active;
  (2) the subscription metadata complete (incl. the review screenshot) and at
  least "Ready to Submit"; (3) the bundle id matches `app.loopara.stillora`. For
  **offline local testing**, add an Xcode **StoreKit Configuration file** with
  `stillora_pro_annual` and select it in the Run scheme — then the paywall shows
  a price on the simulator without waiting for App Review.
- **Price shows "billed yearly" instead of an amount** — the offering didn't
  load (usually the key issue above, or the `default` offering has no
  `$rc_annual` package).

## Test the purchase flow locally (no App Review / no sandbox needed)
A StoreKit Configuration file is already set up at **`ios/Stillora.storekit`** (the
`stillora_pro_annual` annual sub, $39.99, 7‑day trial) and referenced by both the
iOS and macOS Run schemes. It lets the paywall load a price and complete a
**simulated** purchase offline.

⚠️ **It only activates when you launch from Xcode — NOT from `flutter run`/VS Code**
(`flutter run` installs and launches via simctl, which ignores the scheme's
StoreKit config).

To test purchases:
1. **iOS:** `open ios/Runner.xcworkspace` → pick a simulator → press **▶︎ Run**.
   **macOS:** `open macos/Runner.xcworkspace` → press **▶︎ Run**.
2. Go to a Pro area (HTML → Video, Loop, or Voice Narration). The paywall now
   shows **$39.99 / year**.
3. Tap **Start 7‑day free trial** → confirm the StoreKit test sheet → Pro
   unlocks. Use **Debug → StoreKit → Manage Transactions** in Xcode to reset and
   re‑test.

For real sandbox testing on a device, remove/disable the StoreKit config in the
scheme and use a Sandbox tester instead (requires the Paid Apps agreement +
subscription Ready to Submit).

## How it's wired (for reference)
- `lib/core/constants/app_constants.dart` — `RevenueCatConfig` (keys, ids, trial length).
- `lib/core/purchases/pro_controller.dart` — `configureRevenueCat()`,
  `proControllerProvider` (isPro + purchase/restore), `isProProvider`,
  `currentOfferingProvider`.
- `lib/features/paywall/paywall_screen.dart` — the paywall UI + `ensurePro()` /
  `goToTab()` gate helpers.
- Gating call sites: `features/tabs/app_tabs_screen.dart` (mobile nav),
  `core/widgets/desktop_shell.dart` (desktop sidebar),
  `features/editor/add_audio_screen.dart` (Voice Narration).

## Going live checklist
- [ ] Subscription **Approved** in App Store Connect (submit with the app build).
- [ ] Paid Apps agreement active.
- [ ] Real `appl_…` key passed via `--dart-define` in your release build.
- [ ] Entitlement `pro` + `default` offering with an annual package in RevenueCat.
- [ ] Tested a sandbox purchase **and** restore end-to-end.
