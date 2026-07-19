import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/core/widgets/section_split_view.dart';
import 'package:stillora_mobile/features/preview/section_video_preview.dart';

void main() {
  // Every tool tab now renders through SectionSplitView: controls scroll on the
  // left, the live preview stays pinned on the right. These tests lock in that
  // split on desktop, the stacked fallback on phones, and that neither layout
  // overflows with a tall preview + long control list.

  Widget harness(Widget child) => MaterialApp(home: Scaffold(body: child));

  Widget section() => SectionSplitView(
    previewCaption: 'CAPTION',
    preview: const SectionVideoPreview(
      videoPath: null,
      sourceWidth: 1080,
      sourceHeight: 1920,
      emptyLabel: 'EMPTY_STATE',
    ),
    controls: [
      for (var i = 0; i < 30; i++) SizedBox(height: 60, child: Text('ROW_$i')),
    ],
  );

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(harness(section()));
    await tester.pump();
  }

  testWidgets('desktop puts the preview beside the controls, on the right', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpAt(tester, const Size(1400, 900));

      expect(find.text('EMPTY_STATE'), findsOneWidget);
      expect(find.text('LIVE PREVIEW'), findsOneWidget);

      // The preview pane sits to the right of the first control row, and both
      // are on screen at once — the point of the split.
      final preview = tester.getRect(find.text('LIVE PREVIEW'));
      final firstControl = tester.getRect(find.text('ROW_0'));
      expect(preview.left, greaterThan(firstControl.right));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('preview stays pinned while the controls scroll', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpAt(tester, const Size(1400, 900));
      final before = tester.getRect(find.text('LIVE PREVIEW'));

      await tester.drag(find.text('ROW_1'), const Offset(0, -400));
      await tester.pump();

      expect(find.text('ROW_0'), findsNothing); // controls did scroll away
      expect(tester.getRect(find.text('LIVE PREVIEW')), before);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('phone stacks the preview above the controls', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpAt(tester, const Size(390, 844));

      final preview = tester.getRect(find.text('LIVE PREVIEW'));
      final firstControl = tester.getRect(find.text('ROW_0'));
      expect(preview.bottom, lessThan(firstControl.top));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a short desktop window does not overflow the preview pane', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      // 1080×1920 preview content in a 560pt-tall window is the worst case.
      await pumpAt(tester, const Size(1000, 560));
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
