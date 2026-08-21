import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/core/widgets/desktop_shell.dart';
import 'package:stillora_mobile/main.dart' as app;

/// Captures the Stillora Pro paywall from the real running app, for the
/// in-app-purchase review screenshot App Store Connect requires on
/// `stillora_pro_lifetime`.
///
/// One frame, `pro-paywall.png`: the whole paywall — title, what Pro unlocks,
/// and the priced "Unlock Lifetime Pro" CTA — fits above the fold on a phone,
/// which is exactly what Apple wants to see on the product.
///
/// Run against a booted simulator:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/pro_paywall_screenshot_test.dart \
///     -d `device-id`
///
/// PNGs land in `screenshots/`. Follows `appearance_test.dart`'s conventions:
/// `pumpAndSettle` is unusable because the brand glow animates forever, so
/// every wait is a fixed number of frames.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester, [int frames = 8]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  bool isDesktopShell() => find.byType(DesktopSidebar).evaluate().isNotEmpty;

  Future<void> shot(WidgetTester tester, String name) async {
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await settle(tester, 2);
    }
    await binding.takeScreenshot(name);
  }

  /// Scrolls [label] into its scrollable's viewport, then taps it. A finder
  /// matching is not enough: a ListView keeps items just past the fold in the
  /// tree, and those sit inside the screen but outside the clipped viewport.
  Future<void> tapText(WidgetTester tester, String label, {Finder? within}) async {
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    Finder target() => within == null
        ? find.text(label)
        : find.descendant(of: within, matching: find.text(label));

    Finder scroller() {
      if (within != null) {
        final scoped =
            find.descendant(of: within, matching: find.byType(Scrollable));
        if (scoped.evaluate().isNotEmpty) return scoped.first;
      }
      if (find.byType(Drawer).evaluate().isNotEmpty) {
        return find
            .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
            .first;
      }
      return find.byType(Scrollable).last;
    }

    for (var attempt = 0; attempt < 14; attempt++) {
      final finder = target();
      final scrollable = scroller();
      final bounds = scrollable.evaluate().isNotEmpty
          ? tester.getRect(scrollable)
          : Offset.zero & screen;

      var delta = -220.0;
      if (finder.evaluate().isNotEmpty) {
        final rect = tester.getRect(finder.last);
        if (rect.top >= bounds.top && rect.bottom <= bounds.bottom) {
          await tester.tap(finder.last);
          await settle(tester);
          return;
        }
        if (rect.top < bounds.top) delta = 220.0;
      }
      if (scrollable.evaluate().isEmpty) break;
      await tester.drag(scrollable, Offset(0, delta));
      await settle(tester, 4);
    }
    fail('could not bring "$label" into view to tap it');
  }

  testWidgets('Stillora Pro paywall — IAP review screenshot', (tester) async {
    SharedPreferences.setMockInitialValues({'stillora.onboarding.seen': true});
    app.main();
    await settle(tester, 30);

    // ACCOUNT / APP sits at the bottom of the navigation, so this scrolls.
    if (isDesktopShell()) {
      await tapText(tester, 'Stillora Pro', within: find.byType(DesktopSidebar));
    } else {
      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);
      await tapText(tester, 'Stillora Pro');
    }

    // The page must be the real paywall, not an empty tab.
    expect(
      find.text('Unlock the full power of your private media toolkit.'),
      findsOneWidget,
    );
    expect(find.text('One-time purchase. No subscription.'), findsOneWidget);

    // Guarantee the priced CTA is in frame before capturing.
    final page = find.byType(Scrollable).last;
    for (var attempt = 0; attempt < 8; attempt++) {
      final cta = find.textContaining('Unlock Lifetime Pro');
      if (cta.evaluate().isNotEmpty) {
        final rect = tester.getRect(cta.first);
        final bounds = tester.getRect(page);
        if (rect.top >= bounds.top && rect.bottom <= bounds.bottom) break;
      }
      await tester.drag(page, const Offset(0, -200));
      await settle(tester, 4);
    }

    expect(find.textContaining('Unlock Lifetime Pro'), findsOneWidget);
    expect(find.text('Restore Purchase'), findsOneWidget);

    await settle(tester, 10);
    await shot(tester, 'pro-paywall');
  });
}
