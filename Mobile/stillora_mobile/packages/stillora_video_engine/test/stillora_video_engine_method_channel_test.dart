import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelStilloraVideoEngine platform =
      MethodChannelStilloraVideoEngine();
  const MethodChannel channel = MethodChannel('stillora_video_engine');
  late Map<Object?, Object?> exportArguments;

  setUp(() {
    exportArguments = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'exportVideo') {
            exportArguments =
                (methodCall.arguments as Map<Object?, Object?>?) ?? {};
            return {
              'outputPath': '/tmp/export.mp4',
              'width': 1080,
              'height': 1920,
              'durationSeconds': 10,
            };
          }
          if (methodCall.method == 'exportReel') {
            exportArguments =
                (methodCall.arguments as Map<Object?, Object?>?) ?? {};
            return {
              'outputPath': '/tmp/reel.mp4',
              'width': 1080,
              'height': 1920,
              'durationSeconds': 10,
            };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('exportVideo', () async {
    final result = await platform.exportVideo(
      imagePath: '/tmp/image.jpg',
      durationSeconds: 10,
      width: 1080,
      height: 1920,
    );

    expect(result.outputPath, '/tmp/export.mp4');
    expect(exportArguments['mediaPaths'], ['/tmp/image.jpg']);
    expect(exportArguments['imagePaths'], ['/tmp/image.jpg']);
  });

  test('exportVideo forwards image timeline paths', () async {
    await platform.exportVideo(
      imagePath: '/tmp/image-a.jpg',
      imagePaths: const ['/tmp/image-a.jpg', '/tmp/image-b.png'],
      durationSeconds: 12,
      width: 1080,
      height: 1920,
    );

    expect(exportArguments['imagePath'], '/tmp/image-a.jpg');
    expect(exportArguments['imagePaths'], [
      '/tmp/image-a.jpg',
      '/tmp/image-b.png',
    ]);
  });

  test('exportVideo forwards mixed media timeline paths', () async {
    await platform.exportVideo(
      imagePath: '/tmp/clip.mp4',
      mediaPaths: const [
        '/tmp/clip.mp4',
        '/tmp/image-a.jpg',
        '/tmp/image-b.png',
      ],
      imagePaths: const ['/tmp/image-a.jpg', '/tmp/image-b.png'],
      durationSeconds: 12,
      width: 1080,
      height: 1920,
    );

    expect(exportArguments['imagePath'], '/tmp/clip.mp4');
    expect(exportArguments['mediaPaths'], [
      '/tmp/clip.mp4',
      '/tmp/image-a.jpg',
      '/tmp/image-b.png',
    ]);
    expect(exportArguments['imagePaths'], [
      '/tmp/image-a.jpg',
      '/tmp/image-b.png',
    ]);
  });

  test('exportReel forwards mockup choice', () async {
    await platform.exportReel(
      layers: const [
        ReelLayerSpec(
          path: '/tmp/app-demo.mp4',
          isImage: false,
          x: 0,
          y: 0,
          scale: 1,
        ),
      ],
      durationSeconds: 10,
      width: 1080,
      height: 1920,
      mockup: 'iphoneTitanium',
    );

    expect(exportArguments['mockup'], 'iphoneTitanium');
  });
}
