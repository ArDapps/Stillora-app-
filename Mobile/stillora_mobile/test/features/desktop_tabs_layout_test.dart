import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/features/compress/compress_screen.dart';
import 'package:stillora_mobile/features/convert/convert_screen.dart';
import 'package:stillora_mobile/features/images_to_pdf/images_to_pdf_screen.dart';
import 'package:stillora_mobile/features/silence/silence_screen.dart';
import 'package:stillora_mobile/features/speed/speed_screen.dart';
import 'package:stillora_mobile/features/text_overlay/text_overlay_screen.dart';
import 'package:stillora_mobile/features/watermark/watermark_screen.dart';

void main() {
  // Every refactored tool tab must lay out cleanly on a desktop-sized surface:
  // the live preview pane on the right, the controls scrolling on the left, and
  // no RenderFlex overflow in either the empty state or a short window.

  final tabs = <String, Widget>{
    'Speed': const SpeedView(),
    'Remove Silence': const SilenceView(),
    'Compress': const CompressView(),
    'Convert': const ConvertView(),
    'Text': const TextOverlayView(),
    'Watermark': const WatermarkView(),
    'PDF Converter': const ImagesToPdfView(),
  };

  Future<void> pump(WidgetTester tester, Widget view, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    // runAsync lets the ad slot's network call settle so no timer is left
    // pending at teardown (same trick as desktop_sidebar_test).
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: view)),
        ),
      );
    });
    await tester.pump();
  }

  for (final entry in tabs.entries) {
    testWidgets('${entry.key} shows a right-hand preview pane on desktop', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await pump(tester, entry.value, const Size(1400, 900));

        expect(find.text('LIVE PREVIEW'), findsOneWidget);

        // The pane sits in the right half of the window.
        final pane = tester.getRect(find.text('LIVE PREVIEW'));
        expect(pane.left, greaterThan(700));

        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('${entry.key} offers a Start over control', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await pump(tester, entry.value, const Size(1400, 900));

        expect(find.text('Start over'), findsOneWidget);

        // Nothing is loaded in a fresh tab, so it starts disabled — it must not
        // be tappable into a confirm dialog with no inputs to clear.
        final button = tester.widget<TextButton>(
          find.ancestor(
            of: find.text('Start over'),
            matching: find.byType(TextButton),
          ),
        );
        expect(button.onPressed, isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('${entry.key} does not overflow in a short desktop window', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await pump(tester, entry.value, const Size(960, 600));
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
