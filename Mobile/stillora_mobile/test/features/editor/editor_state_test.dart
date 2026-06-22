import 'package:flutter_test/flutter_test.dart';
import 'package:stillora_mobile/features/editor/editor_state.dart';

void main() {
  test('duration selection supports MVP values', () {
    var state = const EditorState();

    state = state.copyWith(durationSeconds: 30);

    expect(state.durationSeconds, 30);
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
