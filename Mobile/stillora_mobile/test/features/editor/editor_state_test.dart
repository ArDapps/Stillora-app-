import 'package:flutter_test/flutter_test.dart';
import 'package:stillora_mobile/features/editor/editor_state.dart';

void main() {
  test('duration selection supports MVP values', () {
    var state = const EditorState();

    state = state.copyWith(durationSeconds: 30);

    expect(state.durationSeconds, 30);
  });

  test('custom duration is clamped to export limits', () {
    var state = const EditorState();

    state = state.copyWith(durationSeconds: 999);
    expect(state.durationSeconds, maxDurationSeconds);

    state = state.copyWith(durationSeconds: 0);
    expect(state.durationSeconds, minDurationSeconds);
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
}
