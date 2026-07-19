import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/features/tabs/app_tabs_screen.dart';

/// Verifies the phone navigation drawer scrolls instead of overflowing on a
/// short screen (it previously threw a 37px RenderFlex bottom overflow because
/// the nav items + footer were taller than the viewport).
///
/// The drawer is pumped in isolation (not the whole tab screen) so gallery/ad
/// dependencies don't muddy the layout under test.
void main() {
  Widget harness() {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('t')),
        drawer: AppNavDrawer(activeView: 0, onSelect: (_) {}),
        body: const SizedBox.expand(),
      ),
    );
  }

  testWidgets('phone drawer scrolls without overflowing', (tester) async {
    // A real phone surface — the size the reported overflow happened on.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(harness());
      await tester.pump();

      // Open the navigation drawer via the AppBar hamburger.
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // No RenderFlex overflow was thrown while laying the drawer out.
      expect(tester.takeException(), isNull);

      // The drawer is present and its nav list is scrollable (the fix).
      expect(find.byType(Drawer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(Scrollable),
        ),
        findsWidgets,
      );

      // Native-engine sections show on iOS.
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('Remove Silence'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the nav list actually scrolls to reveal the last item', (
    tester,
  ) async {
    // A deliberately short screen forces the list to overflow its viewport, so
    // the bottom items are only reachable by scrolling.
    tester.view.physicalSize = const Size(390, 560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(harness());
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Scroll the drawer list up; the bottom-most "Info" item comes into view.
      await tester.drag(find.text('Create'), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Info'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
