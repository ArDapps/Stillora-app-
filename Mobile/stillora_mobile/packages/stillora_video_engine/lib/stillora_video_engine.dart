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
  });

  /// Composites a Reel: every layer drawn at its position/size over a black
  /// canvas, shorter videos looped to [durationSeconds], plus optional audio.
  /// When [mockup] is not `none`, the first video layer is rendered inside an
  /// animated device frame.
  Future<ExportResult> exportReel({
    required List<ReelLayerSpec> layers,
    String? audioPath,
    required int width,
    required int height,
    required int durationSeconds,
    String effect = 'none',
    String transition = 'none',
    String mockup = 'none',
  });

  /// Burns [overlays] onto [videoPath], each shown only within its
  /// [WatermarkLayerSpec.start]..end time window, preserving the base video's
  /// own audio. Output keeps [width]x[height] and runs [durationSeconds].
  Future<ExportResult> exportWatermark({
    required String videoPath,
    required List<WatermarkLayerSpec> overlays,
    required int width,
    required int height,
    required int durationSeconds,
  });

  /// Detects and removes silent (non-speech) stretches from [videoPath], merges
  /// what remains, and exports it scaled to [width]x[height].
  ///
  /// [muteAudio] drops the original audio (silent output). [newAudioPath] adds a
  /// replacement soundtrack: the original audio is dropped, the speed-up applies
  /// to the video only (the new audio plays at normal speed), and the video is
  /// looped to match the new audio's length.
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
  }) {
    return _platform.exportVideo(
      imagePath: imagePath,
      mediaPaths: mediaPaths,
      imagePaths: imagePaths,
      clipDurations: clipDurations,
      clipVolumes: clipVolumes,
      audioPath: audioPath,
      durationSeconds: durationSeconds,
      width: width,
      height: height,
      resizeMode: resizeMode,
      effect: effect,
    );
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
  }) {
    return _platform.exportReel(
      layers: layers,
      audioPath: audioPath,
      width: width,
      height: height,
      durationSeconds: durationSeconds,
      effect: effect,
      transition: transition,
      mockup: mockup,
    );
  }

  @override
  Future<ExportResult> exportWatermark({
    required String videoPath,
    required List<WatermarkLayerSpec> overlays,
    required int width,
    required int height,
    required int durationSeconds,
  }) {
    return _platform.exportWatermark(
      videoPath: videoPath,
      overlays: overlays,
      width: width,
      height: height,
      durationSeconds: durationSeconds,
    );
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
  }) {
    return _platform.removeSilence(
      videoPath: videoPath,
      width: width,
      height: height,
      thresholdDb: thresholdDb,
      minSilenceMs: minSilenceMs,
      paddingMs: paddingMs,
      speed: speed,
      muteAudio: muteAudio,
      newAudioPath: newAudioPath,
    );
  }

  @override
  Future<void> cancelExport() => _platform.cancelExport();

  @override
  Future<void> clearTemporaryFiles() => _platform.clearTemporaryFiles();
}
