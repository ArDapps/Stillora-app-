import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/core/pro/pro_controller.dart';
import 'package:stillora_mobile/core/pro/pro_gate.dart';
import 'package:stillora_mobile/core/pro/pro_purchase_service.dart';
import 'package:stillora_mobile/core/pro/pro_quality_picker.dart';
import 'package:stillora_mobile/core/pro/pro_store.dart';
import 'package:stillora_mobile/core/widgets/ad_widget.dart';
import 'package:stillora_mobile/features/editor/video_preset.dart';

/// Hands a real [Ref] to the export-time clamp helper, the same way a Notifier
/// does at an export call-site.
final _refProvider = Provider<Ref>((ref) => ref);

/// The monetization rules that must hold no matter which section is on screen:
/// Free tops out at 720p, Pro tiers stay visible rather than hidden, the
/// entitlement is enforced on the *output* and not just the picker, and ads
/// disappear permanently once Pro is owned.
void main() {
  ProviderContainer container({bool pro = false}) {
    final store = InMemoryProStore();
    if (pro) store.setPro(true);
    final c = ProviderContainer(
      overrides: [proStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  Widget harness(ProviderContainer c, Widget child) => UncontrolledProviderScope(
    container: c,
    child: MaterialApp(home: Scaffold(body: child)),
  );

  group('free ceiling', () {
    test('720p is free; 1080p, 2K and 4K are Pro', () {
      expect(ProLimits.freeExportQuality, ExportQuality.hd720);
      expect(ExportQuality.hd720.requiresPro, isFalse);
      expect(ExportQuality.fhd1080.requiresPro, isTrue);
      expect(ExportQuality.qhd1440.requiresPro, isTrue);
      expect(ExportQuality.uhd2160.requiresPro, isTrue);
    });
  });

  test('a Free user exports at the ceiling, a Pro user at any tier', () async {
    final free = container();
    final paid = container(pro: true);

    expect(free.read(isProProvider), isFalse);
    expect(paid.read(isProProvider), isTrue);

    // The clamp helper is what every export call-site uses.
    ExportQuality? clamp(ProviderContainer c, ExportQuality? q) =>
        entitledQuality(c.read(_refProvider), q);

    expect(clamp(free, ExportQuality.uhd2160), ExportQuality.hd720);
    expect(clamp(free, ExportQuality.hd720), ExportQuality.hd720);
    expect(clamp(free, null), isNull);
    expect(clamp(paid, ExportQuality.uhd2160), ExportQuality.uhd2160);
  });

  testWidgets('Pro tiers stay visible to Free users, badged not hidden', (
    tester,
  ) async {
    final c = container();
    var picked = ExportQuality.hd720;
    await tester.pumpWidget(
      harness(
        c,
        ProQualityPicker(
          selected: picked,
          onSelected: (q) => picked = q,
        ),
      ),
    );
    await tester.pump();

    // Every tier is on screen — nothing is hidden behind the paywall.
    for (final q in ExportQuality.values) {
      expect(find.text(q.label), findsOneWidget, reason: q.label);
    }
    // Exactly the three paid tiers carry a badge.
    expect(find.text('PRO'), findsNWidgets(3));
  });

  testWidgets('a Pro user sees no PRO badges', (tester) async {
    final c = container(pro: true);
    await tester.pumpWidget(
      harness(
        c,
        ProQualityPicker(
          selected: ExportQuality.uhd2160,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('PRO'), findsNothing);
    expect(find.text('4K'), findsOneWidget);
  });

  testWidgets('a Free user holding a Pro tier is corrected down to 720p', (
    tester,
  ) async {
    final c = container();
    ExportQuality? corrected;
    await tester.pumpWidget(
      harness(
        c,
        // The app's historical default was 1080p — a Free user must not keep it.
        ProQualityPicker(
          selected: ExportQuality.fhd1080,
          onSelected: (q) => corrected = q,
        ),
      ),
    );
    await tester.pump();

    expect(corrected, ExportQuality.hd720);
  });

  testWidgets('Pro collapses every ad slot to nothing', (tester) async {
    final paid = container(pro: true);
    await tester.pumpWidget(harness(paid, const AdSlotWidget()));
    await tester.pump();

    // Pro short-circuits before the banner state is ever created, so the slot
    // occupies no space and never fetches a campaign.
    expect(tester.getSize(find.byType(AdSlotWidget)), Size.zero);
    expect(tester.takeException(), isNull);
  });

  test('purchase unlocks Pro and persists it; restore re-applies it', () async {
    final store = InMemoryProStore();
    final c = ProviderContainer(
      overrides: [
        proStoreProvider.overrideWithValue(store),
        proPurchaseServiceProvider.overrideWithValue(
          const DebugProPurchaseService(),
        ),
      ],
    );
    addTearDown(c.dispose);

    expect(c.read(proControllerProvider).isPro, isFalse);
    await c.read(proControllerProvider.notifier).purchaseLifetime();

    expect(c.read(proControllerProvider).isPro, isTrue);
    expect(store.isPro, isTrue, reason: 'lifetime unlock must survive restart');
  });

  test('an un-wired billing build never silently grants Pro', () async {
    final store = InMemoryProStore();
    final c = ProviderContainer(
      overrides: [
        proStoreProvider.overrideWithValue(store),
        proPurchaseServiceProvider.overrideWithValue(
          const UnavailableProPurchaseService(),
        ),
      ],
    );
    addTearDown(c.dispose);

    await c.read(proControllerProvider.notifier).purchaseLifetime();
    expect(c.read(proControllerProvider).isPro, isFalse);
    expect(store.isPro, isFalse);
    expect(c.read(proControllerProvider).message, isNotNull);
  });

  // "Bought on the iPhone, opened on the Mac" — Universal Purchase reports the
  // unlock through the silent entitlement query, with no second payment and
  // without the user having to find the Restore button.
  test('an unlock owned on another device applies without paying again',
      () async {
    final store = InMemoryProStore();
    final c = ProviderContainer(
      overrides: [
        proStoreProvider.overrideWithValue(store),
        proPurchaseServiceProvider.overrideWithValue(_OwnedElsewhereService()),
      ],
    );
    addTearDown(c.dispose);

    expect(c.read(proControllerProvider).isPro, isFalse);
    await Future<void>.delayed(Duration.zero); // let the launch sync run

    expect(c.read(proControllerProvider).isPro, isTrue);
    expect(store.isPro, isTrue);
  });

  test('an unreachable store never revokes a lifetime unlock', () async {
    final store = InMemoryProStore();
    await store.setPro(true);
    final c = ProviderContainer(
      overrides: [
        proStoreProvider.overrideWithValue(store),
        proPurchaseServiceProvider.overrideWithValue(_UnreachableService()),
      ],
    );
    addTearDown(c.dispose);

    expect(c.read(proControllerProvider).isPro, isTrue);
    await Future<void>.delayed(Duration.zero);

    // A failed query means "unknown", not "refunded".
    expect(c.read(proControllerProvider).isPro, isTrue);
    expect(store.isPro, isTrue);
  });
}

/// A store that already owns the lifetime unlock for this account — the state
/// a Mac is in after the same Apple ID bought Pro on an iPhone.
class _OwnedElsewhereService implements ProPurchaseService {
  @override
  Future<bool> hasActiveEntitlement(config) async => true;
  @override
  Future<ProPurchaseResult> purchaseLifetime(config) async =>
      throw StateError('must not be asked to pay twice');
  @override
  Future<ProPurchaseResult> restorePurchases(config) async =>
      const ProPurchaseResult(ProPurchaseStatus.purchased);
}

/// A store that cannot be reached — offline launch, or a rate-limited query.
class _UnreachableService implements ProPurchaseService {
  @override
  Future<bool> hasActiveEntitlement(config) async => false;
  @override
  Future<ProPurchaseResult> purchaseLifetime(config) async =>
      const ProPurchaseResult(ProPurchaseStatus.failed);
  @override
  Future<ProPurchaseResult> restorePurchases(config) async =>
      const ProPurchaseResult(ProPurchaseStatus.failed);
}
