import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'pro_purchase_service.dart';
import 'pro_store.dart';

/// A price as the store itself reports it, already converted and formatted for
/// the buyer's storefront. Always wins over the configured [ProConfig] values,
/// which are only what to show before the store has answered.
@immutable
class StorePrice {
  const StorePrice({
    required this.label,
    required this.currencyCode,
    required this.amount,
  });

  /// Display string straight from the store, e.g. `R$ 99,90`.
  final String label;

  final String currencyCode;
  final double amount;
}

/// Everything about the one-time "Stillora Pro — Lifetime" purchase that a
/// build or the backend may want to change without shipping a new binary: the
/// store product id, the displayed price and the free/paid resolution split.
///
/// Resolution order, cheapest first:
///  1. `--dart-define` values baked in at build time ([ProConfig.fromEnvironment]).
///  2. The last payload fetched from the backend, cached on device — so the
///     price the user last saw survives an offline launch.
///  3. A fresh fetch of `/api/pro-config`, applied when it arrives.
///
/// Every step is fail-soft: a missing/invalid remote payload leaves the
/// previous value in place. Stillora never blocks the UI on this.
class ProConfig {
  const ProConfig({
    required this.productId,
    required this.priceLabel,
    required this.currencyCode,
    required this.amount,
  });

  /// Store product identifier (App Store / Play / Microsoft Store) for the
  /// non-consumable lifetime unlock.
  final String productId;

  /// Price exactly as it should be shown, already formatted with its symbol
  /// (e.g. `$19.99`). The store's own localized price wins over this when a
  /// purchase flow is available — this is the pre-store-query display value.
  final String priceLabel;

  final String currencyCode;

  /// Numeric price, kept alongside [priceLabel] for analytics/receipts.
  final double amount;

  /// Build-time defaults. Override per build with, e.g.
  /// `--dart-define=STILLORA_PRO_PRICE_LABEL=€21,99`.
  static const fromEnvironment = ProConfig(
    productId: String.fromEnvironment(
      'STILLORA_PRO_PRODUCT_ID',
      defaultValue: 'stillora_pro_lifetime',
    ),
    priceLabel: String.fromEnvironment(
      'STILLORA_PRO_PRICE_LABEL',
      defaultValue: r'$19.99',
    ),
    currencyCode: String.fromEnvironment(
      'STILLORA_PRO_CURRENCY',
      defaultValue: 'USD',
    ),
    amount: 19.99,
  );

  ProConfig copyWith({
    String? productId,
    String? priceLabel,
    String? currencyCode,
    double? amount,
  }) => ProConfig(
    productId: productId ?? this.productId,
    priceLabel: priceLabel ?? this.priceLabel,
    currencyCode: currencyCode ?? this.currencyCode,
    amount: amount ?? this.amount,
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'priceLabel': priceLabel,
    'currencyCode': currencyCode,
    'amount': amount,
  };

  /// Merges a (possibly partial, possibly junk) payload onto [base]. Any field
  /// that is missing or of the wrong type keeps its previous value, so a bad
  /// remote config can never blank out the price shown on the paywall.
  static ProConfig merge(ProConfig base, Map<String, dynamic>? json) {
    if (json == null) return base;
    final amount = json['amount'];
    return base.copyWith(
      productId:
          json['productId'] is String &&
              (json['productId'] as String).isNotEmpty
          ? json['productId'] as String
          : null,
      priceLabel:
          json['priceLabel'] is String &&
              (json['priceLabel'] as String).isNotEmpty
          ? json['priceLabel'] as String
          : null,
      currencyCode: json['currencyCode'] is String
          ? json['currencyCode'] as String
          : null,
      amount: amount is num ? amount.toDouble() : null,
    );
  }
}

/// The live Pro configuration. Reads synchronously (build-time defaults +
/// cached remote payload) so the paywall can render on the first frame, then
/// refreshes from the backend in the background.
final proConfigProvider = NotifierProvider<ProConfigController, ProConfig>(
  ProConfigController.new,
);

class ProConfigController extends Notifier<ProConfig> {
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ),
  );

  @override
  ProConfig build() {
    final cached = ref.read(proStoreProvider).cachedConfig;
    return ProConfig.merge(ProConfig.fromEnvironment, cached);
  }

  /// Pulls the latest price/product id, then lets the store overrule the price
  /// with its own localized one. Safe to call on every paywall open — every
  /// step is independent and a failure leaves the current value in place.
  Future<void> refresh() async {
    await _refreshRemote();
    await _refreshStorePrice();
  }

  Future<void> _refreshRemote() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${AppConstants.apiBaseUrl}/api/pro-config',
      );
      final data = response.data;
      if (data == null) return;
      final next = ProConfig.merge(ProConfig.fromEnvironment, data);
      state = next;
      await _cache(next);
    } catch (_) {
      // Offline, 404, malformed JSON — keep whatever we are already showing.
    }
  }

  /// Replaces the price with what the store quotes for this storefront, so the
  /// paywall shows the currency the user will actually be charged in. Cached
  /// like the remote payload, so the next launch renders it on the first frame
  /// instead of flashing the configured US price first.
  ///
  /// The product id is never taken from here — that is the input to the query,
  /// not an answer.
  Future<void> _refreshStorePrice() async {
    try {
      final price = await ref.read(proPurchaseServiceProvider).storePrice(state);
      if (price == null || price.label.isEmpty) return;
      final next = state.copyWith(
        priceLabel: price.label,
        currencyCode: price.currencyCode,
        amount: price.amount,
      );
      state = next;
      await _cache(next);
    } catch (_) {
      // No store, no product, no network — the configured price stands.
    }
  }

  Future<void> _cache(ProConfig config) =>
      ref.read(proStoreProvider).setCachedConfig(config.toJson());
}
