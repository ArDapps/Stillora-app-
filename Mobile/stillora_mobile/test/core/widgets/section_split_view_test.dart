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

  Widget section({bool hasPreview = true, Widget? previewActions}) =>
      SectionSplitView(
        previewCaption: 'CAPTION',
        hasPreview: hasPreview,
        previewActions: previewActions,
        preview: const SectionVideoPreview(
          videoPath: null,
          sourceWidth: 1080,
          sourceHeight: 1920,
          emptyLabel: 'EMPTY_STATE',
        ),
        controls: [
          for (var i = 0; i < 30; i++)
            SizedBox(height: 60, child: Text('ROW_$i')),
        ],
      );

  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    bool hasPreview = true,
    Widget? previewActions,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      harness(section(hasPreview: hasPreview, previewActions: previewActions)),
    );
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

  // Before anything is loaded there is nothing to preview, and on a phone the
  // empty frame costs a third of the screen — pushing the pick/upload card that
  // would fill it below the fold. So the panel waits for content there, while
  // the desktop pane (which has the room) keeps showing the empty state.

  testWidgets('a phone hides the preview panel until there is content', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpAt(tester, const Size(390, 844), hasPreview: false);

      expect(find.text('LIVE PREVIEW'), findsNothing);
      expect(find.text('EMPTY_STATE'), findsNothing);
      // The controls take the space the panel gave up.
      expect(find.text('ROW_0'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android hides it too', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await pumpAt(tester, const Size(390, 844), hasPreview: false);
      expect(find.text('LIVE PREVIEW'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the phone panel comes back once content arrives', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpAt(tester, const Size(390, 844));
      expect(find.text('LIVE PREVIEW'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a hidden phone panel still leaves its pinned action on screen', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpAt(
        tester,
        const Size(390, 844),
        hasPreview: false,
        previewActions: const Text('EXPORT'),
      );

      expect(find.text('LIVE PREVIEW'), findsNothing);

      // The export button is the end of the flow, not part of the preview, so
      // it survives the panel — at the FOOT of the controls. Up top, with no
      // page list under it, a greyed-out export reads as a broken button
      // rather than the end of the flow; at the foot it matches where every
      // other section puts its export CTA.
      expect(
        find.text('EXPORT'),
        findsNothing,
        reason: 'the action should be at the foot, not the head, of the list',
      );
      await tester.scrollUntilVisible(find.text('EXPORT'), 300);
      expect(find.text('EXPORT'), findsOneWidget);
      expect(
        tester.getRect(find.text('EXPORT')).top,
        greaterThan(tester.getRect(find.text('ROW_29')).top),
        reason: 'the action should come after the last control row',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop keeps the empty preview pane', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpAt(tester, const Size(1400, 900), hasPreview: false);

      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('EMPTY_STATE'), findsOneWidget);
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
