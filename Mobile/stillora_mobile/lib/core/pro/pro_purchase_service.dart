import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'pro_config.dart';
import 'store_pro_purchase_service.dart';

enum ProPurchaseStatus {
  /// The lifetime unlock is now owned by this account/device.
  purchased,

  /// The user backed out of the store sheet — not an error, say nothing.
  cancelled,

  /// A restore found no previous purchase for this account.
  nothingToRestore,

  /// The store took the order but the money has not arrived yet — Play's slow
  /// payment methods (cash, bank transfer) can take hours. Not an error, and
  /// not an unlock: say "waiting for payment" and let
  /// [ProPurchaseService.entitlementGranted] flip the app to Pro when it
  /// clears.
  pending,

  /// Billing is not available on this build/platform yet.
  unavailable,

  /// The store returned an error.
  failed,
}

@immutable
class ProPurchaseResult {
  const ProPurchaseResult(this.status, {this.message});

  final ProPurchaseStatus status;

  /// User-facing detail, already phrased for display. Null when there is
  /// nothing worth saying (e.g. a plain cancel).
  final String? message;

  bool get unlocked => status == ProPurchaseStatus.purchased;
}

/// The single seam between Stillora and a platform billing SDK.
///
/// Nothing above this interface knows about App Store / Play / Microsoft Store
/// products, so wiring real billing means shipping one more implementation and
/// overriding [proPurchaseServiceProvider] — no UI or gating changes.
abstract class ProPurchaseService {
  /// Silent entitlement check, run once at launch.
  ///
  /// This is what makes "buy once, own it everywhere" true. It must map onto
  /// the *non-prompting* store APIs — StoreKit 2's `Transaction
  /// .currentEntitlements` and Play Billing's `queryPurchasesAsync` — both of
  /// which report what the signed-in store account already owns:
  ///  • Apple: the lifetime unlock bought on iPhone shows up on the Mac (and
  ///    the reverse) via Universal Purchase, because both platforms ship under
  ///    one bundle id / one App Store Connect record.
  ///  • Google: the purchase follows the Google account onto every Android
  ///    device it signs into.
  ///
  /// Never call a prompting restore here — asking a first-time user for their
  /// store password on launch is exactly the kind of paywall-first behaviour
  /// Stillora avoids. Return false on any error.
  Future<bool> hasActiveEntitlement(ProConfig config);

  /// Buys the non-consumable identified by [config.productId].
  Future<ProPurchaseResult> purchaseLifetime(ProConfig config);

  /// Explicit, user-initiated restore (the "Restore Purchase" button). May
  /// prompt for store credentials, which is why it is never automatic.
  Future<ProPurchaseResult> restorePurchases(ProConfig config);

  /// The store's own localized price for `config.productId`, or null when the
  /// store has not answered. Preferred over [ProConfig.priceLabel], which is
  /// only the pre-store-query display value — a buyer in Brazil should read
  /// R$ on the paywall, not the configured US dollars.
  Future<StorePrice?> storePrice(ProConfig config);

  /// Fires when the store reports the unlock is owned without the app having
  /// asked: a pending payment clearing mid-session, or a purchase made on
  /// another device arriving while this one is open. Never fires to *revoke*
  /// — a lifetime unlock is never taken back by this app.
  Stream<void> get entitlementGranted;
}

/// Optional add-on for a [ProPurchaseService] that can hand back the store's
/// own token for the last unlock it saw.
///
/// Kept separate from [ProPurchaseService] rather than added to it so that
/// implementations which have no token — the debug and unavailable stand-ins —
/// do not have to pretend. Callers feature-detect with `is`.
///
/// The token is what lets a purchase recorded on the server today be verified
/// against Apple/Google later, once those server credentials exist.
abstract class StoreCredentialSource {
  /// Verification data for the most recent purchase/restore, or null if this
  /// session has not seen one.
  String? get latestStoreToken;

  /// 'apple' or 'google' — which store produced [latestStoreToken].
  String? get storeSourceName;
}

/// The shipping default until a billing SDK is wired up. It never silently
/// grants Pro: an un-wired build tells the user billing is unavailable instead
/// of pretending the purchase went through.
class UnavailableProPurchaseService implements ProPurchaseService {
  const UnavailableProPurchaseService();

  static const _message =
      'In-app purchases are not available on this build yet. '
      'Nothing was charged.';

  @override
  Future<bool> hasActiveEntitlement(ProConfig config) async => false;

  @override
  Future<ProPurchaseResult> purchaseLifetime(ProConfig config) async =>
      const ProPurchaseResult(ProPurchaseStatus.unavailable, message: _message);

  @override
  Future<ProPurchaseResult> restorePurchases(ProConfig config) async =>
      const ProPurchaseResult(ProPurchaseStatus.unavailable, message: _message);

  @override
  Future<StorePrice?> storePrice(ProConfig config) async => null;

  @override
  Stream<void> get entitlementGranted => const Stream<void>.empty();
}

/// Debug-only stand-in so the whole Pro flow (paywall → unlock → badges
/// disappear → ads stop) can be exercised before billing exists. Never used in
/// a release build.
class DebugProPurchaseService implements ProPurchaseService {
  const DebugProPurchaseService();

  @override
  Future<bool> hasActiveEntitlement(ProConfig config) async => false;

  @override
  Future<ProPurchaseResult> purchaseLifetime(ProConfig config) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const ProPurchaseResult(
      ProPurchaseStatus.purchased,
      message: 'Debug build: Stillora Pro unlocked locally.',
    );
  }

  @override
  Future<ProPurchaseResult> restorePurchases(ProConfig config) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const ProPurchaseResult(
      ProPurchaseStatus.purchased,
      message: 'Debug build: Stillora Pro restored locally.',
    );
  }

  /// Null keeps the configured [ProConfig.priceLabel] on screen — a debug
  /// build has no store to ask.
  @override
  Future<StorePrice?> storePrice(ProConfig config) async => null;

  @override
  Stream<void> get entitlementGranted => const Stream<void>.empty();
}

/// Which billing backend this build gets:
/// `--dart-define=STILLORA_BILLING=store|debug|off`.
///
/// Empty (the default) means automatic — the local stand-in in debug builds,
/// the real store in release. Set it to `store` to exercise Play licence
/// testers or the StoreKit sandbox from a debug build, or to `off` to ship a
/// build that openly reports billing as unavailable.
const _billingBackend = String.fromEnvironment('STILLORA_BILLING');

/// Platforms `in_app_purchase` has an implementation for. Windows and Linux
/// have no store, so Stillora there is Free with an honest "not available"
/// rather than a button that throws.
bool get _storeBillingSupported => switch (defaultTargetPlatform) {
  TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

final proPurchaseServiceProvider = Provider<ProPurchaseService>((ref) {
  final backend = _billingBackend.isNotEmpty
      ? _billingBackend
      : (kDebugMode ? 'debug' : 'store');

  if (backend == 'debug') return const DebugProPurchaseService();
  if (backend == 'off' || !_storeBillingSupported) {
    return const UnavailableProPurchaseService();
  }

  try {
    final service = StoreProPurchaseService(
      productId: () => ref.read(proConfigProvider).productId,
      // Read at purchase time, not now: someone may sign in after launch and
      // before they buy.
      accountId: () => ref.read(authControllerProvider).value?.user.id,
    );
    ref.onDispose(service.dispose);
    return service;
  } catch (error) {
    // Reached when the plugin has no registered platform implementation.
    // Falling back keeps the paywall honest instead of crashing it.
    debugPrint('Stillora billing: falling back to unavailable: $error');
    return const UnavailableProPurchaseService();
  }
});
