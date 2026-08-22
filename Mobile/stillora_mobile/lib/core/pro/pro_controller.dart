import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pro_config.dart';
import 'pro_purchase_service.dart';
import 'pro_store.dart';

@immutable
class ProStatus {
  const ProStatus({this.isPro = false, this.busy = false, this.message});

  /// True once the lifetime unlock is owned. There is no expiry and no
  /// subscription renewal — once true it stays true on this device.
  final bool isPro;

  /// A purchase or restore is in flight; the CTA shows a spinner.
  final bool busy;

  /// One-shot result text for the paywall to surface, cleared by
  /// [ProController.clearMessage] once shown.
  final String? message;

  ProStatus copyWith({bool? isPro, bool? busy, String? message}) => ProStatus(
    isPro: isPro ?? this.isPro,
    busy: busy ?? this.busy,
    message: message,
  );
}

/// Owns the lifetime-Pro entitlement for the whole app. Everything that gates a
/// feature or hides an ad watches this.
final proControllerProvider = NotifierProvider<ProController, ProStatus>(
  ProController.new,
);

/// Convenience for the many widgets that only care about the boolean.
final isProProvider = Provider<bool>(
  (ref) => ref.watch(proControllerProvider).isPro,
);

class ProController extends Notifier<ProStatus> {
  @override
  ProStatus build() {
    final status = ProStatus(isPro: ref.read(proStoreProvider).isPro);

    // Unlocks nobody asked for: a slow payment method clearing while the app
    // is open, or a purchase made on another device. Without this the user
    // would have paid and still be looking at a Free app until they relaunch.
    final StreamSubscription<void> granted = ref
        .read(proPurchaseServiceProvider)
        .entitlementGranted
        .listen((_) => _grant());
    ref.onDispose(granted.cancel);

    // Ask the store what this account already owns, once per launch. Without
    // this, someone who bought Pro on their iPhone would open the Mac app and
    // be shown Free until they thought to press "Restore Purchase".
    Future.microtask(syncEntitlement);
    return status;
  }

  /// Silent, non-prompting reconciliation with the store. Only ever *grants*
  /// Pro — a store that is offline, rate-limited or unreachable must never
  /// revoke a lifetime unlock the user already paid for.
  Future<void> syncEntitlement() async {
    if (state.isPro) return;
    final owned = await ref
        .read(proPurchaseServiceProvider)
        .hasActiveEntitlement(ref.read(proConfigProvider));
    if (!owned) return;
    await _grant();
  }

  Future<void> _grant() async {
    if (state.isPro) return;
    await ref.read(proStoreProvider).setPro(true);
    state = state.copyWith(isPro: true);
  }

  Future<void> purchaseLifetime() =>
      _run((service, config) => service.purchaseLifetime(config));

  Future<void> restorePurchases() =>
      _run((service, config) => service.restorePurchases(config));

  void clearMessage() {
    if (state.message == null) return;
    state = state.copyWith();
  }

  /// Local-only entitlement flip, used by the debug/test paths. Purchases go
  /// through [purchaseLifetime] so the store stays the source of truth.
  @visibleForTesting
  Future<void> setPro(bool value) async {
    await ref.read(proStoreProvider).setPro(value);
    state = state.copyWith(isPro: value);
  }

  Future<void> _run(
    Future<ProPurchaseResult> Function(ProPurchaseService, ProConfig) action,
  ) async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    final result = await action(
      ref.read(proPurchaseServiceProvider),
      ref.read(proConfigProvider),
    );
    if (result.unlocked) {
      await ref.read(proStoreProvider).setPro(true);
    }
    state = ProStatus(
      isPro: result.unlocked || state.isPro,
      message: result.message,
    );
  }
}
