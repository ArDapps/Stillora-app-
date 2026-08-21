# Stillora Pro — App Store In-App Purchase

Everything Apple needs before the lifetime unlock can be sold, and everything the app has to implement to sell it.

Listing copy lives in [app-store-listing.md](app-store-listing.md). This file is the product and payment side only.

---

## The product

Stillora Pro is a **one-time purchase, not a subscription**. Filing it as a subscription would set up recurring billing, a different tax treatment, and a cancellation flow that contradicts "Pay once. Use forever." on the paywall.

| Field | Value |
| --- | --- |
| Type | **Non-Consumable** |
| Reference name | `Stillora Pro Lifetime` |
| Product ID | `stillora_pro_lifetime` |
| Display name | `Stillora Pro — Lifetime` (23 / 30) |
| Description | `Unlock 4K exports, advanced tools, no ads.` (42 / 45) |
| Price | $19.99 |

> The Product ID must match `ProConfig.fromEnvironment.productId` in `lib/core/pro/pro_config.dart`. The same string is used on Google Play, so one identifier covers both stores.

**What it unlocks:** 1080p / 2K / 4K exports (Free stops at 720p), higher bitrate and advanced export controls, advanced tool controls such as the silence threshold, premium presets, and permanent removal of ads.

**What it does not touch:** on-device processing, no cloud upload, and watermark-free exports are identical on Free and Pro. Privacy is never the thing being sold.

---

## One purchase covers iPhone, iPad and Mac

iOS and macOS ship from **one App Store Connect record** under a shared bundle ID, so the non-consumable is a Universal Purchase. Bought on the iPhone, it is owned on the Mac — and the reverse — at no extra cost.

Already true in this repo:

| Target | Bundle ID | Source |
| --- | --- | --- |
| iOS | `app.loopara.stillora` | `ios/Runner.xcodeproj/project.pbxproj` |
| macOS | `app.loopara.stillora` | `macos/Runner/Configs/AppInfo.xcconfig:11` |

**The one thing that breaks it:** adding macOS as a *separate* app record. Add the macOS platform to the existing iOS record instead. Two records means two products and a second charge, and it is not casually reversible.

Android never shares with Apple, and Windows/Linux have no store at all. Covering those needs a backend entitlement tied to the Stillora account — see [Beyond Apple](#beyond-apple).

---

## Getting paid

Order matters; each step unlocks the next.

### 1. Paid membership, and you must be the Account Holder

Apple Developer Program, $99/year, active. Only the **Account Holder** role can sign agreements or enter banking — an Admin cannot. This is why most stuck "Pending Agreement" states never resolve.

Organization registration also needs a D-U-N-S number, which takes days to weeks. Individual is immediate but publishes under your legal name.

### 2. Sign the Paid Applications agreement

`App Store Connect → Business → Agreements, Tax, and Banking`

Sign it **first** — the tax forms do not appear until you have.

### 3. Tax forms

Every developer files a US tax form regardless of where they are based:

| Situation | Form |
| --- | --- |
| Based in the US | W-9 |
| Individual outside the US | W-8BEN |
| Company outside the US | W-8BEN-E |

Plus any regional forms for the territories you sell in.

### 4. Banking

A bank account in the same legal name as the developer account, in a payout region Apple supports. **Check your region is on Apple's list before building anything else** — if it isn't, that is a hard blocker, not a paperwork delay.

### 5. Wait for Active

Usually about 24 hours. Until the contract shows **Active**, StoreKit returns an empty product list and every purchase fails — the most common cause of "product not found" in a build that is otherwise correct.

---

## Apply to the Small Business Program

**Not automatic — you have to enrol.** It halves Apple's commission.

| | Apple takes | You receive |
| --- | --- | --- |
| Standard | $6.00 | **$13.99** |
| Small Business Program | $3.00 | **$16.99** |

About **21% more revenue on every sale**, for one form. Eligibility is proceeds up to $1M in the previous calendar year; developers new to the App Store qualify.

Two things you do **not** need: VAT registration in each country (Apple collects and remits in most territories — you set one price), and a payment processor (Apple is the merchant of record, and its rules require IAP for a digital unlock like this anyway).

Payouts arrive monthly, roughly a month in arrears, above a minimum threshold.

---

## Create the product

1. `App Store Connect → your app → Monetization → In-App Purchases → +`
2. Choose **Non-Consumable**. Fill in the table at the top of this file.
3. Add at least one localization with a display name and description, a review screenshot, and review notes. Without all three the product sits in **Missing Metadata** and never reaches the sandbox.
4. Submit the product **with your first app version** — Apple reviews the first in-app purchase alongside a binary, not on its own. Later price changes go through without a new review.

### Sandbox testing

`Users and Access → Sandbox → Test Accounts`

Use an email that has never been an Apple ID. On device, sign out of the real account under Settings → App Store first.

**Test the Mac and the iPhone with the same sandbox tester.** That is how you prove the no-double-charge behaviour before shipping, and it is the one test worth doing manually.

---

## What the app still has to implement

Billing is **not wired yet**. Everything store-related goes through one interface — `ProPurchaseService` in `lib/core/pro/pro_purchase_service.dart` — so this is one new implementation and a provider override. No screen, badge, gate or paywall changes with it.

Until then the release default is `UnavailableProPurchaseService`, which tells the user billing is unavailable and that nothing was charged. It never silently grants Pro.

### The three methods

| Method | Maps to | Prompts? |
| --- | --- | --- |
| `hasActiveEntitlement()` | StoreKit 2 `Transaction.currentEntitlements` | **No** |
| `purchaseLifetime()` | StoreKit purchase | Yes |
| `restorePurchases()` | StoreKit restore | Yes, may ask for credentials |

**`hasActiveEntitlement()` is what makes cross-device ownership work.** `ProController` calls it once per launch, so a Mac opened after an iPhone purchase unlocks by itself instead of waiting for someone to find the Restore button. It must map onto the non-prompting API — a store password box on first launch is exactly the paywall-first behaviour this model exists to avoid.

`restorePurchases()` stays on the button only, because it can prompt.

### Rules the implementation must keep

- **A failed query means *unknown*, not *refunded*.** An offline or rate-limited store must never revoke a lifetime unlock someone paid for. `ProController.syncEntitlement()` only ever grants, and there is a test holding that line.
- **Never grant Pro without the store saying so.** An un-wired or failing build reports unavailable; it does not fall back to unlocking.
- **Prefer the store's localized price** over `ProConfig.priceLabel` once billing is live. The configured value is the pre-store-query display price.

### Dependency

`in_app_purchase: ^3.3.0` — resolves `in_app_purchase_storekit`, and on the Android side `in_app_purchase_android 0.5.x`, which is the release that moved to Play Billing 8.

Deployment targets already satisfy it:

| Platform | Plugin needs | This repo has |
| --- | --- | --- |
| iOS | 13.0+ | 13.0 ✅ |
| macOS | 10.15+ | 11.0 ✅ |

### Xcode

Add the **In-App Purchase** capability to both the iOS and macOS `Runner` targets. The macOS target keeps App Sandbox on with `com.apple.security.network.client`, which `Release.entitlements` already has.

---

## Before submitting

- [ ] Billing implemented — the listing advertises Pro, and Apple rejects listings describing features the binary lacks. A non-functional IAP fails review outright.
- [ ] Paid Applications agreement **Active**, or the IAP will not load for the reviewer.
- [ ] Small Business Program application submitted.
- [ ] Purchase tested end to end in sandbox on **both** iPhone and Mac with one tester account.
- [ ] Restore tested on a clean install.
- [ ] `PrivacyInfo.xcprivacy` added — **currently missing from both `ios/` and `macos/`**. Adding a purchase means the app now handles a *Purchases* data type, which belongs in the privacy manifest and in the App Privacy answers.
- [ ] App Privacy updated to declare **Purchases**. See [app-store-listing.md](app-store-listing.md#app-privacy) for the full set of answers.
- [ ] Review notes filled in, including how to reach the paywall.

---

## Beyond Apple

Universal Purchase covers iPhone, iPad and Mac for free. Nothing crosses between Apple and Google, and Windows/Linux have no store.

To make one purchase cover everything: validate the receipt on your backend, attach the entitlement to the signed-in Stillora account, and have the app read it from there. Stillora already has accounts and a backend at `stillora.loopara.app`, so it is the same mechanism for all three cases.

---

## Sources

- [Universal purchase — Apple Developer glossary](https://developer.apple.com/help/glossary/universal-purchase)
- [Create consumable or non-consumable In-App Purchases](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/)
- [App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/)
- [Tax forms overview — App Store Connect Help](https://developer.apple.com/help/app-store-connect/provide-tax-information/tax-forms-overview)
- [in_app_purchase on pub.dev](https://pub.dev/packages/in_app_purchase)
