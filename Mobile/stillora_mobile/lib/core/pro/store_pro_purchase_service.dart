import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import 'pro_config.dart';
import 'pro_purchase_service.dart';

/// Real billing for the lifetime unlock, backed by `in_app_purchase`:
/// Play Billing on Android, StoreKit 2 on iOS and macOS.
///
/// The plugin has one quirk that shapes this whole file: nothing returns its
/// result. `buyNonConsumable` only reports whether the *sheet opened*, and
/// every outcome — bought, cancelled, failed, or still waiting on a bank
/// transfer — arrives later on a single app-wide [InAppPurchase.purchaseStream].
/// So the stream is subscribed once for the life of the app and each call
/// parks a [_PendingOp] that the stream handler resolves.
///
/// Two store rules are load-bearing here:
///  • **Acknowledge everything.** Google refunds any purchase not acknowledged
///    within 3 days, and StoreKit re-delivers a transaction forever until it is
///    finished. [_deliver] calls `completePurchase` for every update that asks
///    for it, including restores and failures, and including products this
///    build does not recognise.
///  • **Never consume it.** `stillora_pro_lifetime` is non-consumable. Nothing
///    in this file calls a consume API, which is what keeps the entitlement
///    permanent instead of re-buyable.
class StoreProPurchaseService implements ProPurchaseService {
  StoreProPurchaseService({
    required String Function() productId,
    String? Function()? accountId,
    InAppPurchasePlatform? platform,
    this.queryTimeout = const Duration(seconds: 12),
    this.purchaseTimeout = const Duration(minutes: 5),
  }) : _productId = productId,
       _accountId = accountId,
       _iap = platform ?? _registeredPlatform() {
    _updates = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      // A stream-level error is a broken query, not a revoked purchase. Let
      // the parked ops time out; none of them may grant Pro on this path.
      onError: (Object error, StackTrace _) =>
          debugPrint('Stillora billing: purchase stream error: $error'),
    );
  }

  /// How long a silent ownership query waits for the store to answer before it
  /// reports "nothing found". On both platforms the results are already queued
  /// by the time the query future resolves, so this only covers a wedged store.
  final Duration queryTimeout;

  /// How long the buy flow waits for a verdict. Generous on purpose — the user
  /// may be typing card details, and a timeout here shows an error for a
  /// purchase that may still be about to succeed.
  final Duration purchaseTimeout;

  final InAppPurchasePlatform _iap;
  final String Function() _productId;
  final String? Function()? _accountId;

  /// Reading `InAppPurchase.instance` is what registers the Android or
  /// StoreKit implementation; the platform object it registers is the narrower
  /// seam this class actually uses, and the one a test can substitute.
  static InAppPurchasePlatform _registeredPlatform() {
    InAppPurchase.instance;
    return InAppPurchasePlatform.instance;
  }

  late final StreamSubscription<List<PurchaseDetails>> _updates;
  final List<_PendingOp> _pending = <_PendingOp>[];
  final StreamController<void> _granted = StreamController<void>.broadcast();

  /// Fires every time the store hands us an owned purchase, including ones no
  /// call of ours asked for: a slow payment method clearing while the app is
  /// open, or a purchase made on another device arriving mid-session.
  @override
  Stream<void> get entitlementGranted => _granted.stream;

  void dispose() {
    _updates.cancel();
    _granted.close();
    for (final op in _pending) {
      op.resolve(const ProPurchaseResult(ProPurchaseStatus.failed));
    }
    _pending.clear();
  }

  @override
  Future<bool> hasActiveEntitlement(ProConfig config) async {
    final result = await _queryOwnership(config);
    return result.unlocked;
  }

  @override
  Future<ProPurchaseResult> restorePurchases(ProConfig config) =>
      _queryOwnership(config);

  @override
  Future<ProPurchaseResult> purchaseLifetime(ProConfig config) async {
    if (!await _storeReachable()) return _unavailable;

    final product = await _findProduct(config.productId);
    if (product == null) {
      return const ProPurchaseResult(
        ProPurchaseStatus.failed,
        message:
            'Stillora Pro is not available from the store right now. '
            'Nothing was charged — please try again later.',
      );
    }

    final op = _park(config.productId, isPurchase: true);
    bool started;
    try {
      started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          // Play's obfuscatedAccountId / StoreKit's applicationUserName. Ties
          // the order to the signed-in Stillora account so the entitlement can
          // be mirrored server-side later; it cannot be added to past orders,
          // which is why it goes in from the first sale.
          applicationUserName: _obfuscatedAccountId(),
        ),
      );
    } catch (error) {
      _release(op);
      debugPrint('Stillora billing: buy flow did not start: $error');
      return const ProPurchaseResult(
        ProPurchaseStatus.failed,
        message: 'The store could not start the purchase. $_nothingCharged',
      );
    }

    if (!started) {
      _release(op);
      return const ProPurchaseResult(
        ProPurchaseStatus.failed,
        message: 'The store could not start the purchase. $_nothingCharged',
      );
    }

    return op.completer.future.timeout(
      purchaseTimeout,
      onTimeout: () {
        _release(op);
        return const ProPurchaseResult(
          ProPurchaseStatus.failed,
          message:
              'The store did not answer. If you completed the purchase, '
              'reopen Stillora or tap Restore Purchase — you will not be '
              'charged twice.',
        );
      },
    );
  }

  @override
  Future<StorePrice?> storePrice(ProConfig config) async {
    if (!await _storeReachable()) return null;
    final product = await _findProduct(config.productId);
    if (product == null) return null;
    return StorePrice(
      label: product.price,
      currencyCode: product.currencyCode,
      amount: product.rawPrice,
    );
  }

  /// The silent, non-prompting ownership check behind both
  /// [hasActiveEntitlement] and the Restore Purchase button.
  ///
  /// `restorePurchases()` is the same call on both stores and prompts on
  /// neither: on Android it is Play Billing's `queryPurchasesAsync`, and on
  /// iOS/macOS this plugin version defaults to StoreKit 2, where it reads
  /// `Transaction.currentEntitlements`. That is what lets it run at launch —
  /// a second device unlocks by itself instead of waiting for someone to find
  /// the Restore button.
  Future<ProPurchaseResult> _queryOwnership(ProConfig config) async {
    if (!await _storeReachable()) return _unavailable;

    final op = _park(config.productId, isPurchase: false);
    try {
      await _iap.restorePurchases();
    } catch (error) {
      // A failed query means *unknown*, never *refunded*. Report nothing
      // found; ProController only ever grants on this path, so an offline
      // store cannot take a paid unlock away.
      _release(op);
      debugPrint('Stillora billing: ownership query failed: $error');
      return const ProPurchaseResult(
        ProPurchaseStatus.nothingToRestore,
        message:
            'Could not reach the store. If you already own Stillora Pro, '
            'try again once you are back online.',
      );
    }

    return op.completer.future.timeout(
      queryTimeout,
      onTimeout: () {
        _release(op);
        return const ProPurchaseResult(
          ProPurchaseStatus.nothingToRestore,
          message: 'No previous Stillora Pro purchase found on this account.',
        );
      },
    );
  }

  Future<bool> _storeReachable() async {
    try {
      return await _iap.isAvailable();
    } catch (error) {
      debugPrint('Stillora billing: store unavailable: $error');
      return false;
    }
  }

  Future<ProductDetails?> _findProduct(String id) async {
    try {
      final response = await _iap.queryProductDetails(<String>{id});
      for (final product in response.productDetails) {
        if (product.id == id) return product;
      }
      // An empty list with the id flagged invalid is the classic symptom of a
      // product that exists but is not activated, or a payments profile that
      // is not approved yet.
      debugPrint(
        'Stillora billing: product "$id" not returned by the store '
        '(invalid: ${response.notFoundIDs}, error: ${response.error?.message})',
      );
      return null;
    } catch (error) {
      debugPrint('Stillora billing: product lookup failed: $error');
      return null;
    }
  }

  _PendingOp _park(String productId, {required bool isPurchase}) {
    final op = _PendingOp(productId, isPurchase: isPurchase);
    _pending.add(op);
    return op;
  }

  void _release(_PendingOp op) => _pending.remove(op);

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _deliver(purchase);
    }
  }

  Future<void> _deliver(PurchaseDetails purchase) async {
    final mine = purchase.productID == _productId();

    if (mine) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _resolveAll(
            purchase.productID,
            ProPurchaseResult(
              ProPurchaseStatus.purchased,
              message: purchase.status == PurchaseStatus.restored
                  ? 'Stillora Pro restored. Welcome back.'
                  : 'Stillora Pro unlocked. Thank you.',
            ),
          );
          // Also announce it, so an unlock nobody asked for — a pending
          // payment clearing mid-session — still flips the app to Pro.
          if (!_granted.isClosed) _granted.add(null);
        case PurchaseStatus.pending:
          _resolveAll(
            purchase.productID,
            const ProPurchaseResult(
              ProPurchaseStatus.pending,
              message:
                  'Waiting for your payment to clear. Stillora Pro unlocks '
                  'automatically once the store confirms it.',
            ),
            purchasesOnly: true,
          );
        case PurchaseStatus.canceled:
          _resolveAll(
            purchase.productID,
            const ProPurchaseResult(ProPurchaseStatus.cancelled),
            purchasesOnly: true,
          );
        case PurchaseStatus.error:
          _resolveAll(
            purchase.productID,
            ProPurchaseResult(
              ProPurchaseStatus.failed,
              message:
                  '${purchase.error?.message ?? 'The store reported an error.'} '
                  '$_nothingCharged',
            ),
            purchasesOnly: true,
          );
      }
    }

    // Unconditional, and last: acknowledging is what stops Google auto-
    // refunding after 3 days and stops StoreKit re-delivering forever. It runs
    // for restores and failures too, and for ids this build does not know.
    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
      } catch (error) {
        debugPrint('Stillora billing: completePurchase failed: $error');
      }
    }
  }

  /// Hands [result] to every parked call waiting on [productId].
  ///
  /// [purchasesOnly] keeps non-terminal noise away from ownership queries: a
  /// cancelled buy or a store error says nothing about what the account owns,
  /// so the query is left to finish on its own timeout.
  void _resolveAll(
    String productId,
    ProPurchaseResult result, {
    bool purchasesOnly = false,
  }) {
    final matched = _pending
        .where(
          (op) =>
              op.productId == productId && (!purchasesOnly || op.isPurchase),
        )
        .toList();
    for (final op in matched) {
      _pending.remove(op);
      op.resolve(result);
    }
  }

  /// A stable, non-reversible handle for the signed-in Stillora account.
  /// Both stores require this field to carry no personal data, and Play caps
  /// it at 64 characters — a SHA-256 hex digest is exactly 64.
  String? _obfuscatedAccountId() {
    final id = _accountId?.call();
    if (id == null || id.isEmpty) return null;
    return sha256.convert(utf8.encode(id)).toString();
  }

  static const _nothingCharged = 'Nothing was charged.';

  static const _unavailable = ProPurchaseResult(
    ProPurchaseStatus.unavailable,
    message:
        'The store is not available on this device right now. '
        'Nothing was charged.',
  );
}

/// One in-flight call waiting on the shared purchase stream.
class _PendingOp {
  _PendingOp(this.productId, {required this.isPurchase});

  final String productId;

  /// True for a buy flow, false for a silent/explicit ownership query.
  final bool isPurchase;

  final Completer<ProPurchaseResult> completer =
      Completer<ProPurchaseResult>();

  void resolve(ProPurchaseResult result) {
    if (!completer.isCompleted) completer.complete(result);
  }
}
