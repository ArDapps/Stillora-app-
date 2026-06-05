import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart';
import 'package:stillora_video_engine/stillora_video_engine_platform_interface.dart';

class MockStilloraVideoEnginePlatform
    with MockPlatformInterfaceMixin
    implements StilloraVideoEnginePlatform {
  var cancelled = false;

  @override
  Stream<ExportProgress> get progressStream => const Stream.empty();

  @override
  Future<ExportResult> exportVideo({
    required String imagePath,
    List<String> mediaPaths = const [],
    List<String> imagePaths = const [],
    String? audioPath,
    required int durationSeconds,
    required int width,
    required int height,
    ResizeMode resizeMode = ResizeMode.fit,
    VideoEffect effect = VideoEffect.none,
  }) async {
    return ExportResult(
      outputPath: '/tmp/stillora.mp4',
      width: width,
      height: height,
      durationSeconds: durationSeconds,
    );
  }

  @override
  Future<void> cancelExport() async {
    cancelled = true;
  }

  @override
  Future<void> clearTemporaryFiles() async {}
}

void main() {
  final StilloraVideoEnginePlatform initialPlatform =
      StilloraVideoEnginePlatform.instance;

  test('$MethodChannelStilloraVideoEngine is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelStilloraVideoEngine>());
  });

  test('exportVideo delegates to the platform implementation', () async {
    final fakePlatform = MockStilloraVideoEnginePlatform();
    StilloraVideoEnginePlatform.instance = fakePlatform;
    final stilloraVideoEnginePlugin = PlatformStilloraVideoEngine();

    final result = await stilloraVideoEnginePlugin.exportVideo(
      imagePath: '/tmp/source.jpg',
      durationSeconds: 10,
      width: 1080,
      height: 1920,
    );

    expect(result.outputPath, '/tmp/stillora.mp4');
    expect(result.durationSeconds, 10);
  });

  test('cancelExport delegates to the platform implementation', () async {
    final fakePlatform = MockStilloraVideoEnginePlatform();
    StilloraVideoEnginePlatform.instance = fakePlatform;

    await PlatformStilloraVideoEngine().cancelExport();

    expect(fakePlatform.cancelled, isTrue);
  });
}
