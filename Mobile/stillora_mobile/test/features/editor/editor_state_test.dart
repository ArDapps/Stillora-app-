import 'package:flutter_test/flutter_test.dart';
import 'package:stillora_mobile/features/editor/editor_state.dart';

void main() {
  test('duration selection supports MVP values', () {
    var state = const EditorState();

    state = state.copyWith(durationSeconds: 30);

    expect(state.durationSeconds, 30);
  });

  test('fit and fill resize modes are explicit', () {
    const initial = EditorState();
    final filled = initial.copyWith(resizeMode: ResizeMode.fill);

    expect(initial.resizeMode, ResizeMode.fit);
    expect(filled.resizeMode, ResizeMode.fill);
  });

  test('image is required before export', () {
    const empty = EditorState();
    final ready = empty.copyWith(imagePath: '/local/image.jpg');

    expect(empty.canExport, isFalse);
    expect(ready.canExport, isTrue);
  });
}
