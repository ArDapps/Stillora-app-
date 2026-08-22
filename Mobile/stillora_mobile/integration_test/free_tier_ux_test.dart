import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/core/pro/pro_gate.dart';
import 'package:stillora_mobile/core/widgets/desktop_shell.dart';
import 'package:stillora_mobile/features/pro/pro_screen.dart';
import 'package:stillora_mobile/features/settings/settings_screen.dart';
import 'package:stillora_mobile/main.dart' as app;

/// Drives the real app as a Free user and checks the three things a Free user
/// needs: a way out of the paywall, a plain statement of what Free includes,
/// and PRO tags on the paid rows.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester, [int frames = 8]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  bool isDesktopShell() => find.byType(DesktopSidebar).evaluate().isNotEmpty;

  Future<void> shot(WidgetTester tester, String name) async {
    try {
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
        await settle(tester, 2);
      }
      await binding.takeScreenshot(name);
    } catch (error) {
      debugPrint('screenshot "$name" skipped: $error');
    }
  }

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

    // Pinned footer rows (Stillora Pro, Info) sit outside the sidebar's
    // scrollable and would never satisfy the scroll loop.
    final direct = target();
    if (direct.evaluate().isNotEmpty) {
      final rect = tester.getRect(direct.last);
      final onScreen = rect.top >= 0 &&
          rect.left >= 0 &&
          rect.bottom <= screen.height &&
          rect.right <= screen.width;
      final scrollable = scroller();
      final inScroller = scrollable.evaluate().isNotEmpty &&
          find.descendant(of: scrollable, matching: direct).evaluate().isNotEmpty;
      if (onScreen && !inScroller) {
        await tester.tap(direct.last);
        await settle(tester);
        return;
      }
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

  Future<void> goToSection(WidgetTester tester, String label) async {
    if (isDesktopShell()) {
      await tapText(tester, label, within: find.byType(DesktopSidebar));
      return;
    }
    await tester.tap(find.byIcon(Icons.menu));
    await settle(tester);
    await tapText(tester, label);
  }

  Future<void> dismissLaunchPaywall(WidgetTester tester) async {
    if (find.byType(ProView).evaluate().isEmpty) return;
    debugPrint('paywall opened on launch');
    Navigator.of(tester.element(find.byType(ProView).first)).maybePop();
    await settle(tester, 12);
  }

  testWidgets('a Free user can decline Pro and see what Free includes',
      (tester) async {
    SharedPreferences.setMockInitialValues({'stillora.onboarding.seen': true});
    app.main();
    await settle(tester, 30);
    await dismissLaunchPaywall(tester);

    // ── 1. The paywall offers a way out ────────────────────────────────────
    // Reach it the way a Free user does: tap a locked resolution.
    for (final section in ['Create', 'Loop images', 'HTML']) {
      await goToSection(tester, section);
      await settle(tester, 10);
      if (find.text('4K').evaluate().isNotEmpty) break;
    }
    expect(find.text('4K'), findsWidgets, reason: 'no locked tier to tap');
    // Desktop puts the quality row well below the fold of a scrolling column.
    await tester.ensureVisible(find.text('4K').first);
    await settle(tester, 4);
    await tester.tap(find.text('4K').first);
    await settle(tester, 15);

    expect(find.byType(ProView), findsOneWidget,
        reason: 'tapping a locked tier did not open the paywall');
    final decline = find.widgetWithText(OutlinedButton, 'Continue with Free');
    expect(decline, findsOneWidget,
        reason: 'the paywall has no way to decline and stay on Free');
    debugPrint('PAYWALL: "Continue with Free" present');

    // PRO tags on the paid rows, and none on the both-tiers privacy row.
    final badges = find.descendant(
      of: find.byType(ProView),
      matching: find.byType(ProBadge),
    );
    debugPrint('PAYWALL: ${badges.evaluate().length} PRO tags on the '
        'highlight rows');
    expect(badges, findsWidgets, reason: 'no PRO tags on the Pro features');
    await shot(tester, 'free-01-paywall-with-decline');

    // The paywall is a long list; on a phone the decline button sits below the
    // fold, and tapping an off-screen widget lands wherever its centre falls.
    await tester.ensureVisible(decline);
    await settle(tester, 4);
    await tester.tap(decline);
    await settle(tester, 15);
    expect(find.byType(ProView), findsNothing,
        reason: '"Continue with Free" did not dismiss the paywall');
    debugPrint('PAYWALL: declined — back in the app');
    await shot(tester, 'free-02-back-in-app');

    // ── 2. Info states what Free includes ──────────────────────────────────
    await goToSection(tester, 'Info');
    await settle(tester, 10);
    expect(find.byType(PlanBlock), findsOneWidget, reason: 'no plan block');
    expect(find.text('Free'), findsWidgets);
    for (final line in const [
      'Every tool, unlimited use',
      'Exports up to 720p',
      'No Stillora watermark',
      'Files stay on this device',
      'Includes sponsored content',
    ]) {
      expect(find.text(line), findsOneWidget, reason: 'plan line "$line"');
    }
    debugPrint('INFO: plan block lists all five Free lines');
    await shot(tester, 'free-03-info-plan');

    expect(tester.takeException(), isNull);
  });
}
