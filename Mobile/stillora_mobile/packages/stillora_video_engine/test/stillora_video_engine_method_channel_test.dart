import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillora_video_engine/stillora_video_engine_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelStilloraVideoEngine platform =
      MethodChannelStilloraVideoEngine();
  const MethodChannel channel = MethodChannel('stillora_video_engine');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'exportVideo') {
            return {
              'outputPath': '/tmp/export.mp4',
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
  });
}
