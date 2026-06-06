import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/types.dart';
import 'stillora_video_engine_platform_interface.dart';

/// An implementation of [StilloraVideoEnginePlatform] that uses method channels.
class MethodChannelStilloraVideoEngine extends StilloraVideoEnginePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('stillora_video_engine');

  @override
  Stream<ExportProgress> get progressStream {
    return const EventChannel('stillora_video_engine/progress')
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map(
          (event) =>
              ExportProgress.fromMap((event as Map).cast<Object?, Object?>()),
        );
  }

  @override
  Future<ExportResult> exportVideo({
    required String imagePath,
    List<String> mediaPaths = const [],
    List<String> imagePaths = const [],
    List<int> clipDurations = const [],
    String? audioPath,
    required int durationSeconds,
    required int width,
    required int height,
    ResizeMode resizeMode = ResizeMode.fit,
    VideoEffect effect = VideoEffect.none,
  }) async {
    final result = await methodChannel.invokeMapMethod<Object?, Object?>(
      'exportVideo',
      {
        'imagePath': imagePath,
        'mediaPaths': mediaPaths.isEmpty ? [imagePath] : mediaPaths,
        'imagePaths': imagePaths.isEmpty ? [imagePath] : imagePaths,
        'clipDurations': clipDurations,
        'audioPath': audioPath,
        'durationSeconds': durationSeconds,
        'width': width,
        'height': height,
        'resizeMode': resizeMode.name,
        'effect': effect.name,
      },
    );

    if (result == null) {
      throw PlatformException(
        code: 'export_failed',
        message: 'The video engine did not return an export result.',
      );
    }

    return ExportResult.fromMap(result);
  }

  @override
  Future<void> cancelExport() {
    return methodChannel.invokeMethod<void>('cancelExport');
  }

  @override
  Future<void> clearTemporaryFiles() {
    return methodChannel.invokeMethod<void>('clearTemporaryFiles');
  }
}
