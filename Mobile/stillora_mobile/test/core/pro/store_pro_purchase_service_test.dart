import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import 'package:stillora_mobile/core/pro/pro_config.dart';
import 'package:stillora_mobile/core/pro/pro_purchase_service.dart';
import 'package:stillora_mobile/core/pro/store_pro_purchase_service.dart';

/// The real product id, so the tests exercise the same matching the app does.
const _config = ProConfig.fromEnvironment;
final _id = _config.productId;

void main() {
  late _FakeStore store;
  late StoreProPurchaseService service;

  setUp(() {
    store = _FakeStore();
    service = StoreProPurchaseService(
      productId: () => _id,
      platform: store,
      queryTimeout: const Duration(milliseconds: 50),
      purchaseTimeout: const Duration(milliseconds: 200),
    );
  });

  tearDown(() {
    service.dispose();
    store.dispose();
  });

  group('acknowledgement', () {
    test('every delivered purchase is completed — Google refunds the ones that '
        'are not, within 3 days', () async {
      store.emit(_purchase(PurchaseStatus.purchased));
      await _settle();

      expect(store.completed, <String>[_id]);
    });

    test('restored and failed purchases are completed too', () async {
      store
        ..emit(_purchase(PurchaseStatus.restored))
        ..emit(_purchase(PurchaseStatus.error));
      await _settle();

      expect(store.completed, <String>[_id, _id]);
    });

    test('a purchase for an unknown product is still completed', () async {
      store.emit(_purchase(PurchaseStatus.purchased, id: 'some_other_product'));
      await _settle();

      expect(store.completed, <String>['some_other_product']);
    });

    test('a purchase that does not ask to be completed is left alone', () async {
      store.emit(_purchase(PurchaseStatus.purchased, pendingComplete: false));
      await _settle();

      expect(store.completed, isEmpty);
    });

    test('nothing is ever consumed — the unlock is non-consumable', () async {
      store.emit(_purchase(PurchaseStatus.purchased));
      await service.purchaseLifetime(_config);
      await service.restorePurchases(_config);
      await _settle();

      expect(store.consumed, isEmpty);
    });
  });

  group('buying', () {
    test('a completed purchase unlocks Pro', () async {
      final result = service.purchaseLifetime(_config);
      await _settle();
      store.emit(_purchase(PurchaseStatus.purchased));

      expect((await result).unlocked, isTrue);
    });

    test('backing out of the sheet is a cancel, not an error', () async {
      final result = service.purchaseLifetime(_config);
      await _settle();
      store.emit(_purchase(PurchaseStatus.canceled));

      final value = await result;
      expect(value.status, ProPurchaseStatus.cancelled);
      expect(value.message, isNull, reason: 'a plain cancel says nothing');
    });

    test('a slow payment method reports pending, and unlocks when it clears',
        () async {
      final granted = <void>[];
      service.entitlementGranted.listen(granted.add);

      final result = service.purchaseLifetime(_config);
      await _settle();
      store.emit(_purchase(PurchaseStatus.pending));

      final value = await result;
      expect(value.status, ProPurchaseStatus.pending);
      expect(value.unlocked, isFalse);
      expect(granted, isEmpty);

      // Hours later, still in the same session.
      store.emit(_purchase(PurchaseStatus.purchased));
      await _settle();

      expect(granted, hasLength(1));
    });

    test('a product the store will not sell fails without opening a sheet',
        () async {
      store.products.clear();

      final value = await service.purchaseLifetime(_config);
      expect(value.status, ProPurchaseStatus.failed);
      expect(store.buyCalls, isZero);
    });

    test('an unreachable store reports unavailable, never a silent unlock',
        () async {
      store.available = false;

      final value = await service.purchaseLifetime(_config);
      expect(value.status, ProPurchaseStatus.unavailable);
      expect(value.unlocked, isFalse);
    });

    test('the order carries an obfuscated account id, never the raw one', () async {
      service.dispose();
      service = StoreProPurchaseService(
        productId: () => _id,
        accountId: () => 'user-42',
        platform: store,
        purchaseTimeout: const Duration(milliseconds: 200),
      );

      final result = service.purchaseLifetime(_config);
      await _settle();
      store.emit(_purchase(PurchaseStatus.purchased));
      await result;

      final sent = store.lastPurchaseParam!.applicationUserName!;
      expect(sent, isNot(contains('user-42')));
      expect(sent, hasLength(64), reason: "Play caps it at 64");
    });

    test('a signed-out buyer sends no account id at all', () async {
      final result = service.purchaseLifetime(_config);
      await _settle();
      store.emit(_purchase(PurchaseStatus.purchased));
      await result;

      expect(store.lastPurchaseParam!.applicationUserName, isNull);
    });
  });

  group('ownership', () {
    test('an unlock owned on another device is found without prompting',
        () async {
      store.owned.add(_purchase(PurchaseStatus.restored));

      expect(await service.hasActiveEntitlement(_config), isTrue);
      expect(store.buyCalls, isZero, reason: 'a silent check never charges');
    });

    test('an account that owns nothing reports nothing to restore', () async {
      final value = await service.restorePurchases(_config);

      expect(value.status, ProPurchaseStatus.nothingToRestore);
      expect(value.unlocked, isFalse);
    });

    test('a failed query means unknown, not refunded', () async {
      store.queryThrows = true;

      final value = await service.restorePurchases(_config);
      expect(value.unlocked, isFalse);
      expect(value.status, ProPurchaseStatus.nothingToRestore,
          reason: 'the caller may only ever grant on this path');
    });

    test('an offline store never claims the account owns nothing on a buy path',
        () async {
      store.available = false;

      expect(await service.hasActiveEntitlement(_config), isFalse);
    });

    test("someone else's product in the account does not unlock Stillora Pro",
        () async {
      store.owned.add(
        _purchase(PurchaseStatus.restored, id: 'another_app_product'),
      );

      expect(await service.hasActiveEntitlement(_config), isFalse);
    });
  });

  group('price', () {
    test("the store's localized price wins over the configured one", () async {
      store.products
        ..clear()
        ..add(_product(price: 'R\$ 99,90', currency: 'BRL', raw: 99.90));

      final price = await service.storePrice(_config);
      expect(price!.label, r'R$ 99,90');
      expect(price.currencyCode, 'BRL');
      expect(price.amount, 99.90);
    });

    test('no store means no override — the configured price stands', () async {
      store.available = false;

      expect(await service.storePrice(_config), isNull);
    });
  });
}

/// Lets queued stream events and the awaits around them run.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

PurchaseDetails _purchase(
  PurchaseStatus status, {
  String? id,
  bool pendingComplete = true,
}) {
  return PurchaseDetails(
    productID: id ?? _id,
    purchaseID: 'txn-1',
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: '',
      source: 'test',
    ),
    transactionDate: null,
    status: status,
  )..pendingCompletePurchase = pendingComplete;
}

ProductDetails _product({
  String price = r'$19.99',
  String currency = 'USD',
  double raw = 19.99,
}) {
  return ProductDetails(
    id: _id,
    title: 'Stillora Pro — Lifetime',
    description: 'Unlock 4K exports, advanced tools, no ads.',
    price: price,
    rawPrice: raw,
    currencyCode: currency,
  );
}

/// A store that answers in memory, so the parts that cost real money —
/// acknowledgement, pending payments, a failed query — can be driven exactly.
class _FakeStore extends InAppPurchasePlatform {
  final StreamController<List<PurchaseDetails>> _updates =
      StreamController<List<PurchaseDetails>>.broadcast();

  final List<ProductDetails> products = <ProductDetails>[_product()];

  /// What `queryPurchases` / `currentEntitlements` reports this account owns.
  final List<PurchaseDetails> owned = <PurchaseDetails>[];

  final List<String> completed = <String>[];
  final List<String> consumed = <String>[];

  bool available = true;
  bool queryThrows = false;
  int buyCalls = 0;
  PurchaseParam? lastPurchaseParam;

  void emit(PurchaseDetails purchase) =>
      _updates.add(<PurchaseDetails>[purchase]);

  void dispose() => _updates.close();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async {
    final found =
        products.where((p) => identifiers.contains(p.id)).toList();
    return ProductDetailsResponse(
      productDetails: found,
      notFoundIDs: identifiers.difference(found.map((p) => p.id).toSet()).toList(),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCalls++;
    lastPurchaseParam = purchaseParam;
    return true;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    consumed.add(purchaseParam.productDetails.id);
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    if (queryThrows) {
      throw InAppPurchaseException(
        source: 'test',
        code: 'restore_failed',
        message: 'offline',
      );
    }
    if (owned.isNotEmpty) _updates.add(List<PurchaseDetails>.of(owned));
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);
}
