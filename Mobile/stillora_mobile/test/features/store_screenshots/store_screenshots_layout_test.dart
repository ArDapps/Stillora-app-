import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/core/widgets/section_split_view.dart';
import 'package:stillora_mobile/features/store_screenshots/store_screenshots_screen.dart';
import 'package:stillora_mobile/features/store_screenshots/store_screenshots_state.dart';
import 'package:stillora_mobile/features/tabs/app_sections.dart';
import 'package:stillora_mobile/features/tabs/app_tabs_screen.dart';

/// Store Screenshots ships on every platform, so it has to lay out on a 320pt
/// phone and in a wide desktop window alike.
void main() {
  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    // runAsync lets the ad slot's network call settle so no timer is pending.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: StoreScreenshotsView())),
        ),
      );
    });
    await tester.pump();
  }

  testWidgets('lays out on a phone without overflowing', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pump(tester, const Size(390, 844));
      expect(tester.takeException(), isNull);

      expect(find.text('App Store & Play screenshots'), findsOneWidget);
      expect(find.text('Add screenshots'), findsWidgets);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('survives a small phone', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await pump(tester, const Size(320, 568));
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a phone hides the preview panel until screens are added', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pump(tester, const Size(390, 844));
      // Nothing picked yet, so the section follows the same rule as every
      // other one: no empty preview above the controls.
      expect(find.byType(LivePreviewPanel), findsNothing);
      // The export button survives the panel, at the foot of the controls.
      await tester.scrollUntilVisible(find.text('Export zip'), 300);
      expect(find.text('Export zip'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop splits the controls and the preview pane', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pump(tester, const Size(1400, 900));
      expect(tester.takeException(), isNull);
      // Desktop keeps its pinned pane even before anything is added.
      expect(find.byType(LivePreviewPanel), findsOneWidget);
      expect(find.text('LIVE PREVIEW'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('opens with a submittable default selection', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pump(tester, const Size(390, 844));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(StoreScreenshotsView)),
      );
      final state = container.read(storeScreenshotsControllerProvider);
      // Required sizes for both stores, and nothing queued to render yet.
      expect(state.selectedTargetIds, contains('iphone-6-9'));
      expect(state.selectedTargetIds, contains('play-phone'));
      expect(state.hasImages, isFalse);
      expect(state.canExport, isFalse, reason: 'no images means no export');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the drawer lists the section on Android too', (tester) async {
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

      // Pure Dart, so it is not gated the way the iOS-engine sections are.
      expect(find.text('Store Screenshots'), findsOneWidget);
      // And the renamed section reads by its new name.
      expect(find.text('Reformat Image'), findsOneWidget);
      expect(find.text('Convert'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('the section is registered with a view of its own', () {
    // A section whose viewIndex has no entry in `views` crashes on selection.
    expect(
      AppSection.storeShots.viewIndex,
      lessThan(AppTabsScreen.views.length),
    );
    expect(
      AppTabsScreen.views[AppSection.storeShots.viewIndex],
      isA<StoreScreenshotsView>(),
    );
  });
}
