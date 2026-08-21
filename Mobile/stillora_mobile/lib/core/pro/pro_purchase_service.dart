import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pro_config.dart';

enum ProPurchaseStatus {
  /// The lifetime unlock is now owned by this account/device.
  purchased,

  /// The user backed out of the store sheet — not an error, say nothing.
  cancelled,

  /// A restore found no previous purchase for this account.
  nothingToRestore,

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
}

final proPurchaseServiceProvider = Provider<ProPurchaseService>(
  (ref) => kDebugMode
      ? const DebugProPurchaseService()
      : const UnavailableProPurchaseService(),
);
