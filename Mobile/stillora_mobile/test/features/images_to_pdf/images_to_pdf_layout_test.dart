import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/features/images_to_pdf/images_to_pdf_screen.dart';
import 'package:stillora_mobile/features/tabs/app_tabs_screen.dart';

/// The desktop split layout is covered by desktop_tabs_layout_test; this is the
/// phone side, which stacks the page list above the controls in one scroll
/// column. A section that overflows on a 390pt screen is unusable, and the
/// controls are tall enough here (four step cards) that it is a real risk.
void main() {
  Future<void> pumpPhone(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    // runAsync lets the ad slot's network call settle so no timer is left
    // pending at teardown.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: ImagesToPdfView())),
        ),
      );
    });
    await tester.pump();
  }

  testWidgets('lays out on a phone without overflowing', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpPhone(tester, const Size(390, 844));
      expect(tester.takeException(), isNull);

      // Stacked, not split: with nothing queued there is no page list to
      // preview, so the section opens on its setup cards and the export button
      // waits at the foot of them.
      expect(find.text('Add images or PDFs'), findsWidgets);
      await tester.scrollUntilVisible(find.text('Export PDF'), 300);
      expect(find.text('Export PDF'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('survives a small phone', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpPhone(tester, const Size(320, 568));
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the export button is disabled until pages are queued', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpPhone(tester, const Size(390, 844));
      // It sits at the foot of the setup cards while the queue is empty.
      await tester.scrollUntilVisible(find.text('Export PDF'), 300);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Export PDF'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the phone drawer offers PDF Converter on Android too', (
    tester,
  ) async {
    // Android hides the sections that depend on the iOS-only native engine.
    // This one is pure Dart plus a cross-platform plugin, so it must show.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('t')),
            drawer: AppNavDrawer(activeView: 0, onSelect: (_) {}),
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('PDF Converter'), findsOneWidget);
      // Sanity check that the gate is still doing its job for the others.
      expect(find.text('Speed'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
