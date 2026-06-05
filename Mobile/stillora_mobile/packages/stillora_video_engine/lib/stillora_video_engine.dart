import 'dart:async';

import 'src/types.dart';
import 'stillora_video_engine_platform_interface.dart';

export 'src/types.dart';
export 'stillora_video_engine_method_channel.dart'
    show MethodChannelStilloraVideoEngine;

abstract interface class StilloraVideoEngine {
  Stream<ExportProgress> get progressStream;

  Future<ExportResult> exportVideo({
    required String imagePath,
    String? audioPath,
    required int durationSeconds,
    required int width,
    required int height,
    ResizeMode resizeMode = ResizeMode.fit,
    VideoEffect effect = VideoEffect.none,
  });

  Future<void> cancelExport();

  Future<void> clearTemporaryFiles();
}

class PlatformStilloraVideoEngine implements StilloraVideoEngine {
  PlatformStilloraVideoEngine({StilloraVideoEnginePlatform? platform})
    : _platform = platform ?? StilloraVideoEnginePlatform.instance;

  final StilloraVideoEnginePlatform _platform;

  @override
  Stream<ExportProgress> get progressStream => _platform.progressStream;

  @override
  Future<ExportResult> exportVideo({
    required String imagePath,
    String? audioPath,
    required int durationSeconds,
    required int width,
    required int height,
    ResizeMode resizeMode = ResizeMode.fit,
    VideoEffect effect = VideoEffect.none,
  }) {
    return _platform.exportVideo(
      imagePath: imagePath,
      audioPath: audioPath,
      durationSeconds: durationSeconds,
      width: width,
      height: height,
      resizeMode: resizeMode,
      effect: effect,
    );
  }

  @override
  Future<void> cancelExport() => _platform.cancelExport();

  @override
  Future<void> clearTemporaryFiles() => _platform.clearTemporaryFiles();
}
