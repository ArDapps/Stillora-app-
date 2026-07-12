import 'package:flutter_test/flutter_test.dart';
import 'package:stillora_mobile/features/compress/compress_state.dart';

void main() {
  const source = CompressState(
    videoPath: '/tmp/in.mp4',
    videoName: 'in.mp4',
    sourceWidth: 1920,
    sourceHeight: 1080,
    sourceDurationSeconds: 60,
    sourceBytes: 100 * 1024 * 1024,
  );

  test('keeps the source resolution (compressor never rescales)', () {
    final res = source.outputResolution;

    expect(res.width, 1920);
    expect(res.height, 1080);
  });

  test('output dimensions are forced even for the encoder', () {
    const odd = CompressState(
      sourceWidth: 1081,
      sourceHeight: 607,
      sourceBytes: 1000,
    );

    final res = odd.outputResolution;
    expect(res.width.isEven, isTrue);
    expect(res.height.isEven, isTrue);
  });

  test('target size is the chosen fraction of the source', () {
    final balanced = source.copyWith(level: CompressLevel.balanced);

    // 45% of 100 MB.
    expect(
      balanced.targetBytes,
      (source.sourceBytes * CompressLevel.balanced.sizeFraction).round(),
    );
  });

  test('a stronger level always yields a smaller target', () {
    final high = source.copyWith(level: CompressLevel.high).targetBytes;
    final balanced = source.copyWith(level: CompressLevel.balanced).targetBytes;
    final tiny = source.copyWith(level: CompressLevel.tiny).targetBytes;

    expect(balanced, lessThan(high));
    expect(tiny, lessThan(balanced));
  });

  test('every level targets a real reduction below the source', () {
    for (final level in CompressLevel.values) {
      final s = source.copyWith(level: level);
      expect(s.targetBytes, lessThan(s.sourceBytes),
          reason: '${level.label} should be smaller than the source');
      expect(s.savingsPercent, greaterThan(0));
    }
  });

  test('muting shaves extra off the target', () {
    final withAudio = source.copyWith(level: CompressLevel.small);
    final muted = withAudio.copyWith(muteAudio: true);

    expect(muted.targetBytes, lessThan(withAudio.targetBytes));
  });

  test('falls back to a resolution estimate when the size is unknown', () {
    final noSize = source.copyWith(sourceBytes: 0);

    // Still produces a positive, level-scaled target and a nominal saving.
    expect(noSize.targetBytes, greaterThan(0));
    expect(noSize.savingsPercent, greaterThan(0));
  });

  test('never targets below the hard floor', () {
    const tinySource = CompressState(
      sourceWidth: 640,
      sourceHeight: 480,
      sourceDurationSeconds: 1,
      sourceBytes: 1000, // 1 KB source
      level: CompressLevel.tiny,
    );

    expect(tinySource.targetBytes, greaterThanOrEqualTo(64 * 1024));
  });
}
