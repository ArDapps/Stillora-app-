import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/features/editor/editor_state.dart';
import 'package:stillora_mobile/features/editor/video_preset.dart';
import 'package:stillora_mobile/features/editor/widgets/output_size_controls.dart';

void main() {
  // OutputSizeControls is the same widget on the mobile preset screen and the
  // desktop preset card, so these phone-sized render checks cover both.

  Future<void> pump(
    WidgetTester tester,
    EditorState editor, {
    void Function(int, int)? onCustomSize,
    void Function(int)? onReferenceSelected,
  }) async {
    tester.view.physicalSize = const Size(390, 844); // a phone
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OutputSizeControls(
              editor: editor,
              onCustomSize: onCustomSize ?? (_, _) {},
              onReferenceSelected: onReferenceSelected ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows nothing for a fixed-ratio preset', (tester) async {
    await pump(tester, EditorState(preset: presetById('reels')));
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('Custom Size shows width/height fields and reports edits', (
    tester,
  ) async {
    final edits = <(int, int)>[];
    await pump(
      tester,
      EditorState(preset: presetById('custom')),
      onCustomSize: (w, h) => edits.add((w, h)),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    // Seeds a concrete size on first frame, then a typed value flows through.
    expect(edits, isNotEmpty);

    await tester.enterText(find.byType(TextField).first, '1280');
    await tester.pump();
    expect(edits.last.$1, 1280);
  });

  testWidgets(
    'Original Size with several clips shows a chip per clip and reports the pick',
    (tester) async {
      final picks = <int>[];
      final editor = EditorState(
        preset: presetById('original'),
        media: [
          MediaItem.fromPath('/a.mp4', width: 1920, height: 1080),
          MediaItem.fromPath('/b.mp4', width: 1080, height: 1920),
        ],
      );
      await pump(tester, editor, onReferenceSelected: picks.add);

      expect(find.byType(ChoiceChip), findsNWidgets(2));
      expect(find.textContaining('1920×1080'), findsOneWidget);

      await tester.tap(find.textContaining('1080×1920'));
      await tester.pump();
      expect(picks, [1]);
    },
  );

  testWidgets('Original Size with a single clip shows no picker', (
    tester,
  ) async {
    await pump(
      tester,
      EditorState(
        preset: presetById('original'),
        media: [MediaItem.fromPath('/a.mp4', width: 1920, height: 1080)],
      ),
    );
    expect(find.byType(ChoiceChip), findsNothing);
  });
}
