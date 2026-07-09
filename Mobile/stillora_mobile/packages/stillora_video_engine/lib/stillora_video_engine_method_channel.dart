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
    List<double> clipVolumes = const [],
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
        'clipVolumes': clipVolumes,
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
  Future<ExportResult> renderHtml({
    String? html,
    String? url,
    required int width,
    required int height,
    required int durationMs,
    int fps = 30,
    String? audioPath,
  }) async {
    final result = await methodChannel.invokeMapMethod<Object?, Object?>(
      'renderHtml',
      {
        'html': html,
        'url': url,
        'width': width,
        'height': height,
        'durationMs': durationMs,
        'fps': fps,
        'audioPath': audioPath,
      },
    );
    if (result == null) {
      throw PlatformException(
        code: 'render_failed',
        message: 'The video engine did not return an HTML render result.',
      );
    }
    return ExportResult.fromMap(result);
  }

  @override
  Future<ExportResult> exportReel({
    required List<ReelLayerSpec> layers,
    String? audioPath,
    required int width,
    required int height,
    required int durationSeconds,
    String effect = 'none',
    String transition = 'none',
    String mockup = 'none',
  }) async {
    final result = await methodChannel.invokeMapMethod<Object?, Object?>(
      'exportReel',
      {
        'layers': [for (final layer in layers) layer.toMap()],
        'audioPath': audioPath,
        'width': width,
        'height': height,
        'durationSeconds': durationSeconds,
        'effect': effect,
        'transition': transition,
        'mockup': mockup,
      },
    );
    if (result == null) {
      throw PlatformException(
        code: 'export_failed',
        message: 'The video engine did not return a reel export result.',
      );
    }
    return ExportResult.fromMap(result);
  }

  @override
  Future<ExportResult> exportWatermark({
    required String videoPath,
    required List<WatermarkLayerSpec> overlays,
    required int width,
    required int height,
    required int durationSeconds,
  }) async {
    final result = await methodChannel.invokeMapMethod<Object?, Object?>(
      'exportWatermark',
      {
        'videoPath': videoPath,
        'overlays': [for (final o in overlays) o.toMap()],
        'width': width,
        'height': height,
        'durationSeconds': durationSeconds,
      },
    );
    if (result == null) {
      throw PlatformException(
        code: 'export_failed',
        message: 'The video engine did not return a watermark export result.',
      );
    }
    return ExportResult.fromMap(result);
  }

  @override
  Future<ExportResult> removeSilence({
    required String videoPath,
    required int width,
    required int height,
    double thresholdDb = -35,
    int minSilenceMs = 400,
    int paddingMs = 100,
    int speed = 1,
    bool muteAudio = false,
    String? newAudioPath,
  }) async {
    final result = await methodChannel
        .invokeMapMethod<Object?, Object?>('removeSilence', {
          'videoPath': videoPath,
          'width': width,
          'height': height,
          'thresholdDb': thresholdDb,
          'minSilenceMs': minSilenceMs,
          'paddingMs': paddingMs,
          'speed': speed,
          'muteAudio': muteAudio,
          'newAudioPath': newAudioPath,
        });
    if (result == null) {
      throw PlatformException(
        code: 'export_failed',
        message: 'The video engine did not return a result.',
      );
    }
    return ExportResult.fromMap(result);
  }

  @override
  Future<ExportResult> colorGrade({
    required String videoPath,
    required ColorAdjustSpec adjust,
    required int width,
    required int height,
    required int durationSeconds,
  }) async {
    final result = await methodChannel.invokeMapMethod<Object?, Object?>(
      'colorGrade',
      {
        'videoPath': videoPath,
        'adjust': adjust.toMap(),
        'width': width,
        'height': height,
        'durationSeconds': durationSeconds,
      },
    );
    if (result == null) {
      throw PlatformException(
        code: 'export_failed',
        message: 'The video engine did not return a colour-grade result.',
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
