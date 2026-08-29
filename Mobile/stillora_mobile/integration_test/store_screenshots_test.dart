import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/core/widgets/desktop_shell.dart';
import 'package:stillora_mobile/features/pro/pro_screen.dart';
import 'package:stillora_mobile/main.dart' as app;

/// Drives the new Store Screenshots section in the real app: opens it from the
/// drawer, exercises the size picker, the orientation switch and the fit/format
/// controls, and checks the export button reflects what is selected.
///
/// `pumpAndSettle` is unusable (the brand glow animates forever), so every wait
/// is a fixed number of frames, matching the other integration tests.
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

  /// Scrolls the open drawer until [label] is visible, then taps it. The
  /// drawer's nav list is lazily built and, on iOS where no section is gated
  /// away, DOCUMENT TOOLS sits below the fold — so a plain `find.text` there
  /// finds nothing at all.
  Future<void> tapInDrawer(WidgetTester tester, String label) async {
    Finder scroller() => find
        .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
        .first;

    for (var attempt = 0; attempt < 14; attempt++) {
      final finder = find.text(label);
      if (finder.evaluate().isNotEmpty) {
        await tester.ensureVisible(finder.last);
        await settle(tester, 3);
        await tester.tap(finder.last, warnIfMissed: false);
        await settle(tester, 10);
        return;
      }
      if (scroller().evaluate().isEmpty) break;
      await tester.drag(scroller(), const Offset(0, -220));
      await settle(tester, 4);
    }
    fail('could not bring "$label" into view in the drawer');
  }

  /// Scrolls the section until [label] is on screen, then taps it.
  Future<bool> scrollToAndTap(WidgetTester tester, String label) async {
    for (var attempt = 0; attempt < 16; attempt++) {
      final finder = find.text(label);
      if (finder.evaluate().isNotEmpty) {
        await tester.ensureVisible(finder.first);
        await settle(tester, 3);
        await tester.tap(finder.first, warnIfMissed: false);
        await settle(tester, 6);
        return true;
      }
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) return false;
      await tester.drag(scrollable.last, const Offset(0, -300));
      await settle(tester, 3);
    }
    return false;
  }

  Future<bool> scrollTo(WidgetTester tester, String label) async {
    for (var attempt = 0; attempt < 16; attempt++) {
      if (find.text(label).evaluate().isNotEmpty) return true;
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) return false;
      await tester.drag(scrollable.last, const Offset(0, -300));
      await settle(tester, 3);
    }
    return false;
  }

  testWidgets('Store Screenshots opens and its controls respond', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'stillora.onboarding.seen': true});
    app.main();
    await settle(tester, 30);

    if (find.byType(ProView).evaluate().isNotEmpty) {
      Navigator.of(tester.element(find.byType(ProView).first)).maybePop();
      await settle(tester, 12);
    }

    // ── Reach the section ────────────────────────────────────────────────
    if (isDesktopShell()) {
      await tester.tap(find.text('Store Screenshots').first);
    } else {
      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);
      // The rename shipped alongside the new section — check it while the
      // drawer is still at the top, where Reformat Image is listed.
      expect(
        find.text('Convert'),
        findsNothing,
        reason: 'Convert should now read "Reformat Image"',
      );
      await tapInDrawer(tester, 'Store Screenshots');
    }
    await settle(tester, 16);

    expect(find.text('App Store & Play screenshots'), findsOneWidget);
    debugPrint('OK  section opens');
    await shot(tester, 'store-01-open');

    // Nothing added yet, so on a phone there is no empty preview panel.
    if (!isDesktopShell()) {
      expect(find.text('LIVE PREVIEW'), findsNothing);
      debugPrint('OK  no empty preview before adding screens');
    }

    // ── The size table is really there ───────────────────────────────────
    expect(await scrollTo(tester, 'Sizes'), isTrue, reason: 'no Sizes step');
    // Apple's required iPhone size, with its exact pixel dimensions.
    expect(await scrollTo(tester, '6.9"'), isTrue);
    expect(
      find.text('1320×2868'),
      findsWidgets,
      reason: 'the 6.9" iPhone size is wrong or missing',
    );
    debugPrint('OK  iPhone 6.9" listed at 1320x2868');
    await shot(tester, 'store-02-sizes');

    // ── Orientation flips the published dimensions ───────────────────────
    expect(await scrollToAndTap(tester, 'Landscape'), isTrue);
    expect(
      find.text('2868×1320'),
      findsWidgets,
      reason: 'Landscape did not swap the iPhone axes',
    );
    // An Apple Watch has one orientation and must not rotate with it.
    if (await scrollTo(tester, 'Ultra 3')) {
      expect(
        find.text('422×514'),
        findsWidgets,
        reason: 'the watch size rotated, which the store would reject',
      );
      debugPrint('OK  watch size stayed portrait in landscape mode');
    }
    await shot(tester, 'store-03-landscape');

    expect(await scrollToAndTap(tester, 'Portrait'), isTrue);
    expect(find.text('1320×2868'), findsWidgets);
    debugPrint('OK  orientation switch works both ways');

    // ── Fit / background / format all respond ────────────────────────────
    for (final label in ['Fill', 'Fit', 'White', 'Midnight', 'JPEG', 'PNG']) {
      expect(
        await scrollToAndTap(tester, label),
        isTrue,
        reason: 'could not tap "$label"',
      );
    }
    expect(tester.takeException(), isNull);
    debugPrint('OK  fit, background and format controls all tap');
    await shot(tester, 'store-04-look');

    // ── Export stays disabled with no images ─────────────────────────────
    expect(await scrollTo(tester, 'Export zip'), isTrue);
    final button = tester.widget<FilledButton>(
      find
          .ancestor(
            of: find.textContaining('Export zip'),
            matching: find.byType(FilledButton),
          )
          .first,
    );
    expect(
      button.onPressed,
      isNull,
      reason: 'export should be disabled until screens are added',
    );
    debugPrint('OK  export disabled with an empty queue');

    // ── "Required only" resets the selection ─────────────────────────────
    expect(await scrollToAndTap(tester, 'Required only'), isTrue);
    expect(tester.takeException(), isNull);
    debugPrint('OK  "Required only" applies without error');
    await shot(tester, 'store-05-required');

    expect(tester.takeException(), isNull);
  });
}
