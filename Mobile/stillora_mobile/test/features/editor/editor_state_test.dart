import 'package:flutter_test/flutter_test.dart';
import 'package:stillora_mobile/features/editor/editor_state.dart';
import 'package:stillora_mobile/features/editor/video_preset.dart';

void main() {
  test('duration selection supports MVP values', () {
    var state = const EditorState();

    state = state.copyWith(durationSeconds: 30);

    expect(state.durationSeconds, 30);
  });

  group('output size', () {
    final original = presetById('original');
    final custom = presetById('custom');

    test(
      'Original Size uses the source clip dimensions, not a fixed square',
      () {
        final state = EditorState(
          preset: original,
          exportQuality: ExportQuality.fhd1080,
          media: [MediaItem.fromPath('/clip.mp4', width: 3840, height: 2160)],
        );
        // 4K 16:9 source at the 1080p tier keeps the aspect (1920×1080), rather
        // than the old 1080×1080 square.
        expect(state.outputResolution, (width: 1920, height: 1080));
      },
    );

    test(
      'Original Size follows the chosen reference clip when several exist',
      () {
        var state = EditorState(
          preset: original,
          exportQuality: ExportQuality.fhd1080,
          media: [
            MediaItem.fromPath('/wide.mp4', width: 1920, height: 1080),
            MediaItem.fromPath('/tall.mp4', width: 1080, height: 1920),
          ],
        );
        expect(state.outputResolution, (width: 1920, height: 1080));

        state = state.copyWith(originalReferenceIndex: 1);
        expect(state.outputResolution, (width: 1080, height: 1920));
      },
    );

    test(
      'Original Size falls back to the tier square until a clip is measured',
      () {
        final state = EditorState(
          preset: original,
          exportQuality: ExportQuality.fhd1080,
          media: [MediaItem.fromPath('/clip.mp4')], // width/height still 0
        );
        expect(state.outputResolution, (width: 1080, height: 1080));
      },
    );

    test('Custom Size uses the exact typed dimensions, even-adjusted', () {
      final state = EditorState(
        preset: custom,
        customWidth: 1281, // odd → bumped to even
        customHeight: 721,
      );
      expect(state.outputResolution, (width: 1282, height: 722));
    });
  });

  test('custom duration has no artificial upper limit', () {
    var state = const EditorState();

    state = state.copyWith(durationSeconds: 999);
    expect(state.durationSeconds, 999);

    state = state.copyWith(durationSeconds: 0);
    expect(state.durationSeconds, minDurationSeconds);
  });

  test('duration slider expands to include long values', () {
    expect(durationSliderMax(60), defaultDurationSliderMaxSeconds);
    expect(durationSliderMax(301), 600);
    expect(durationSliderMax(3600), 3600);
  });

  test('duration adjustment step scales for long projects', () {
    expect(durationAdjustmentStep(30), 1);
    expect(durationAdjustmentStep(60), 10);
    expect(durationAdjustmentStep(600), 60);
  });

  test('long audio-sized projects retain their full duration', () {
    final state = const EditorState().copyWith(
      durationSeconds: 1800,
      audioDurationSeconds: 1800,
    );

    expect(state.durationSeconds, 1800);
    expect(state.audioDurationSeconds, 1800);
  });

  test('fit and fill resize modes are explicit', () {
    const initial = EditorState();
    final filled = initial.copyWith(resizeMode: ResizeMode.fill);

    expect(initial.resizeMode, ResizeMode.fit);
    expect(filled.resizeMode, ResizeMode.fill);
  });

  test('media is required before export', () {
    const empty = EditorState();
    final ready = empty.copyWith(
      media: [MediaItem.fromPath('/local/image.jpg')],
    );

    expect(empty.canExport, isFalse);
    expect(ready.canExport, isTrue);
    expect(ready.imagePath, '/local/image.jpg');
  });

  test('mixed media keeps timeline order for export', () {
    final ready = const EditorState().copyWith(
      media: [
        MediaItem.fromPath('/local/clip.mp4'),
        MediaItem.fromPath('/local/photo-a.jpg'),
        MediaItem.fromPath('/local/photo-b.png'),
      ],
      selectedIndex: 0,
    );

    expect(ready.imagePath, '/local/clip.mp4');
    expect(ready.mediaPaths, [
      '/local/clip.mp4',
      '/local/photo-a.jpg',
      '/local/photo-b.png',
    ]);
    expect(ready.imagePaths, ['/local/photo-a.jpg', '/local/photo-b.png']);
    expect(ready.exportsMixedTimeline, isTrue);
    expect(ready.exportsVideoSource, isFalse);
  });

  test('narration flag is set with audio and cleared with it', () {
    const empty = EditorState();
    expect(empty.audioIsNarration, isFalse);

    final withNarration = empty.copyWith(
      audioPath: '/tmp/narration.m4a',
      audioIsNarration: true,
    );
    expect(withNarration.audioIsNarration, isTrue);
    expect(withNarration.audioPath, '/tmp/narration.m4a');

    final cleared = withNarration.copyWith(clearAudio: true);
    expect(cleared.audioPath, isNull);
    expect(cleared.audioIsNarration, isFalse);
  });
}
