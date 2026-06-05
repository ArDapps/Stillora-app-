import 'package:flutter_test/flutter_test.dart';
import 'package:stillora_mobile/features/editor/video_preset.dart';

void main() {
  test('social presets map to required resolutions', () {
    expect(presetById('reels').width, 1080);
    expect(presetById('reels').height, 1920);
    expect(presetById('square').width, 1080);
    expect(presetById('square').height, 1080);
    expect(presetById('landscape').width, 1920);
    expect(presetById('landscape').height, 1080);
  });

  test('original preset is represented as source-derived size', () {
    final preset = presetById('original');

    expect(preset.usesOriginalSize, isTrue);
    expect(preset.ratioLabel, 'Original');
  });
}
