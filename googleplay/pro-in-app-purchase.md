# Stillora Pro — Google Play In-App Purchase

Everything Google needs before the lifetime unlock can be sold on Android, and everything the app has to implement to sell it.

Listing copy lives in [play-store-listing.md](play-store-listing.md). Assets live in [UPLOAD-ASSETS.md](UPLOAD-ASSETS.md). This file is the product and payment side only. The Apple equivalent is [../appstore/pro-in-app-purchase.md](../appstore/pro-in-app-purchase.md).

---

## The product

Stillora Pro is a **one-time product, not a subscription**. In Play Console the section is `Monetize → Products → In-app products` — *not* `Subscriptions`. Filing it as a subscription would create recurring billing, a cancellation flow, and a "renews monthly" badge on the listing, all of which contradict "Pay once. Use forever." on the paywall.

| Field | Value |
| --- | --- |
| Type | **In-app product** (one-time, non-consumable) |
| Product ID | `stillora_pro_lifetime` |
| Name | `Stillora Pro — Lifetime` (max 55) |
| Description | `Unlock 4K exports, advanced tools, no ads.` (max 200) |
| Price | $19.99 USD, auto-converted to other countries |
| Multi-quantity | **Off** |
| Purchase type | **Buy** (not Rent) |

> The Product ID must match `ProConfig.fromEnvironment.productId` in [../Mobile/stillora_mobile/lib/core/pro/pro_config.dart](../Mobile/stillora_mobile/lib/core/pro/pro_config.dart#L44). It is the same string as the App Store product, so one identifier covers both stores.

**Product IDs are permanent.** Once created, the ID can never be renamed, and it cannot be reused even after deleting the product. Type it carefully: lowercase letters, digits, underscores and periods only, starting with a letter or digit.

**What it unlocks:** 1080p / 2K / 4K exports (Free stops at 720p), higher bitrate and advanced export controls, advanced tool controls such as the silence threshold, premium presets, and permanent removal of ads.

**What it does not touch:** on-device processing, no cloud upload, and watermark-free exports are identical on Free and Pro.

---

## One purchase covers every Android device

The purchase is attached to the buyer's **Google account**, so it follows them onto every Android device they sign into — no extra work, provided the app calls the silent restore at launch (see [What the app still has to implement](#what-the-app-still-has-to-implement)).

Nothing crosses between Google and Apple. A user who bought on iPhone owns nothing on Android unless the entitlement is mirrored through the Stillora backend — see [Beyond Google](#beyond-google).

Package name, already fixed in the repo: `app.loopara.stillora` ([android/app/build.gradle.kts:32](../Mobile/stillora_mobile/android/app/build.gradle.kts#L32)). It can never be changed after the first upload.

---

## Getting paid

Order matters; each step unlocks the next.

### 1. Play Console developer account

$25, one time, lifetime. Verified identity required (address + phone; organizations also need a D-U-N-S number and can take a week or more).

### 2. Personal accounts: the 12-tester rule

If the developer account is registered as **personal** (not organization) and was created after 13 Nov 2023, Google requires a **closed test with at least 12 testers opted in continuously for 14 days** before you can apply for production access. Organization accounts are exempt.

This is the single longest lead time on Android. Start the closed test early — it runs in parallel with everything else here.

### 3. Payments profile

`Play Console → Setup → Payments profile`

Only the account **owner** can create it. Once a payments profile is linked to a Play Console account it cannot be swapped for another one, so create it under the right Google account the first time.

Confirm your country is on Google's list of supported merchant countries **before building anything else** — if it isn't, that is a hard blocker, not a paperwork delay.

### 4. Tax information

Inside the payments profile: US tax info (Google collects a US form from every developer, wherever based), plus tax settings for the countries you sell in.

Google is the merchant of record in most territories and collects and remits VAT/GST for you — you set one price. In a small number of countries the developer is the seller of record and self-remits; the payments centre flags those.

### 5. Bank account

In the same legal name as the developer account, in a country Google supports for payouts. Payouts are monthly, around the 15th, for the previous month, above a low minimum threshold.

### 6. Wait for the profile to be approved

Until the payments profile is active, Play Billing returns an empty product list and every purchase fails — the most common cause of "product not found" in a build that is otherwise correct.

---

## The service fee — nothing to apply for

Unlike Apple's Small Business Program, Google's reduced rate is **automatic**.

| | Google takes | You receive |
| --- | --- | --- |
| First $1M of earnings each calendar year | 15% ($3.00) | **$16.99** |
| Above $1M | 30% ($6.00) | $13.99 |

Play Billing is mandatory for a digital unlock like this. Linking out to your own checkout to avoid the fee violates Play policy outside of specific alternative-billing programmes.

---

## Create the product

Play will not let you sell anything until a build that *declares billing* is on a track.

1. **Ship a build with the billing permission first.** Adding `in_app_purchase` to the app merges `com.android.vending.BILLING` into the manifest automatically. Upload that AAB to at least **Internal testing** — you do not need it in production.
2. `Play Console → your app → Monetize → Products → In-app products → Create product`
3. Fill in the table at the top of this file.
4. Set the price: enter **19.99 USD**, then use **Set prices** to auto-convert all other countries. Review the rounding on a few key markets.
5. **Activate** the product. A saved-but-inactive product is invisible to the app.

New products can take a few hours to propagate before the app can query them.

### License testing (free test purchases)

`Play Console → (all apps, left nav) Setup → License testing` → add Gmail addresses.

A licence tester who is **also opted into a testing track** sees a "Test card, always approves" payment option, is charged nothing, and can re-buy after the purchase is voided from the Order management page. This is the only sane way to test a non-consumable repeatedly.

Testing checklist worth doing manually:

- Buy on device A, sign the same Google account into device B, confirm Pro is on at launch with no prompt.
- Uninstall and reinstall — Pro must come back by itself.
- Airplane mode at launch — Pro must **not** disappear.

---

## What the app still has to implement

**Implemented**, in [../Mobile/stillora_mobile/lib/core/pro/store_pro_purchase_service.dart](../Mobile/stillora_mobile/lib/core/pro/store_pro_purchase_service.dart) — one `ProPurchaseService` implementation over `in_app_purchase`, covering Play Billing and StoreKit 2 together. No screen, badge, gate or paywall changed. Not yet exercised against a real store: everything below is verified by unit tests against a fake, and the device passes in [Before submitting](#before-submitting) are still open.

Release builds on Android, iOS and macOS get it automatically. Windows and Linux keep `UnavailableProPurchaseService`, which reports billing as unavailable and never silently grants Pro. Debug builds get the local stand-in unless you pass `--dart-define=STILLORA_BILLING=store`, which is how you drive a licence tester or the StoreKit sandbox from a debug build.

### Dependency

```yaml
in_app_purchase: ^3.3.0                     # → in_app_purchase_android 0.5.2, Play Billing 8.0.0
in_app_purchase_platform_interface: ^1.4.1  # the seam the service takes, so it is testable
```

Play enforces a minimum Play Billing Library version and raises it roughly once a year; 0.5.2 is on the current top version. No Android manifest, Gradle or Proguard edits are needed: `com.android.vending.BILLING` is declared by the `com.android.billingclient:billing:8.0.0` AAR and merges into the app at build time. Its `minSdkVersion 21` is below the Flutter default, so nothing moves there either.

### The three methods on Android

| Method | Maps to | Prompts? |
| --- | --- | --- |
| `hasActiveEntitlement()` | `InAppPurchase.instance.restorePurchases()` → `purchaseStream` (Play Billing `queryPurchasesAsync`) | **No** |
| `purchaseLifetime()` | `buyNonConsumable()` | Yes |
| `restorePurchases()` | same as the first row, user-initiated | No |

Android differs from iOS here in a useful way: `restorePurchases()` on Play **never asks for credentials**, so it is safe to run at launch. That is what makes a second Android device unlock by itself instead of waiting for someone to find the Restore button.

### Two Android rules that cost real money if missed

- **Acknowledge every purchase within 3 days or Google automatically refunds it.** With the Flutter plugin that means calling `InAppPurchase.instance.completePurchase(purchase)` for every delivered purchase, including the ones that arrive from `restorePurchases()`. This is the number-one Android billing bug.
- **Do not consume it.** `stillora_pro_lifetime` is non-consumable; consuming it would let the same user buy it again and would drop their entitlement.

Also handle `PurchaseStatus.pending` — Play supports slow payment methods (cash, bank transfer) where the purchase completes hours later. Show "waiting for payment", not an error, and unlock when it arrives.

### Rules the implementation must keep

- **A failed query means *unknown*, not *refunded*.** An offline or rate-limited store must never revoke a lifetime unlock someone paid for. `ProController.syncEntitlement()` only ever grants, and there is a test holding that line.
- **Never grant Pro without the store saying so.**
- **Prefer the store's localized price** (`ProductDetails.price`) over `ProConfig.priceLabel` once billing is live. The configured value is the pre-store-query display price.

---

## Play Console forms that change once Pro exists

- **App content → Ads:** Stillora serves house ads from `md.loopara.app` ([../ADS-INTEGRATION.md](../ADS-INTEGRATION.md)), so the app **contains ads** — declare it, even though they are your own. Removing ads is part of what Pro sells.
- **Data safety:** if the backend ever receives purchase or entitlement data, declare *Financial info → Purchase history* (collected, not shared, for app functionality). Purchases handled entirely by Play Billing on-device need no declaration.
- **Store listing:** the "In-app purchases" badge and the `$19.99` price range appear automatically once the product is active. No copy change needed.
- **Target API level:** already at 36 ([UPLOAD-ASSETS.md](UPLOAD-ASSETS.md)), which satisfies the current requirement.

---

## Before submitting

- [x] Billing implemented, and `completePurchase()` called on every delivered purchase — restores and failures included. Held by tests in [../Mobile/stillora_mobile/test/core/pro/store_pro_purchase_service_test.dart](../Mobile/stillora_mobile/test/core/pro/store_pro_purchase_service_test.dart).
- [ ] Payments profile active, bank and tax details complete.
- [ ] Product `stillora_pro_lifetime` created **and activated**, price set in all countries.
- [ ] Build with the billing permission uploaded to a track.
- [ ] Purchase, reinstall-restore, second-device-restore and offline-launch all tested with a licence tester.
- [ ] Personal account only: 12 testers × 14 days closed test satisfied, production access granted.
- [ ] App content → Ads and Data safety updated.

---

## Beyond Google

The Google account covers every Android device the buyer signs into. Nothing crosses to Apple, and Windows/Linux have no store.

To make one purchase cover everything: verify the purchase token server-side with the **Google Play Developer API** (a service account in Google Cloud, granted access under `Play Console → Setup → API access`), attach the entitlement to the signed-in Stillora account, and have the app read it from there. Stillora already has accounts and a backend at `stillora.loopara.app`, so it is the same mechanism used for the Apple side.

Passing `applicationUserName` on the purchase (Play's `obfuscatedAccountId`) links the Play order to the Stillora account and is worth doing from day one — it cannot be added retroactively to past orders. **Done:** every order carries the SHA-256 of the signed-in Stillora account id, or nothing at all when signed out.

---

## Sources

- [Create a one-time product — Play Console Help](https://support.google.com/googleplay/android-developer/answer/1153481)
- [Test in-app billing with license testers](https://developer.android.com/google/play/billing/test)
- [Process purchases — acknowledgement requirement](https://developer.android.com/google/play/billing/integrate#process)
- [Service fees — Play Console Help](https://support.google.com/googleplay/android-developer/answer/112622)
- [Closed testing requirements for personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- [in_app_purchase on pub.dev](https://pub.dev/packages/in_app_purchase)
