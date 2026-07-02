import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/types.dart';
import 'stillora_video_engine_method_channel.dart';

abstract class StilloraVideoEnginePlatform extends PlatformInterface {
  /// Constructs a StilloraVideoEnginePlatform.
  StilloraVideoEnginePlatform() : super(token: _token);

  static final Object _token = Object();

  static StilloraVideoEnginePlatform _instance =
      MethodChannelStilloraVideoEngine();

  /// The default instance of [StilloraVideoEnginePlatform] to use.
  ///
  /// Defaults to [MethodChannelStilloraVideoEngine].
  static StilloraVideoEnginePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [StilloraVideoEnginePlatform] when
  /// they register themselves.
  static set instance(StilloraVideoEnginePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<ExportProgress> get progressStream {
    throw UnimplementedError('progressStream has not been implemented.');
  }

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
    throw UnimplementedError('exportVideo has not been implemented.');
  }

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
    throw UnimplementedError('exportReel has not been implemented.');
  }

  Future<ExportResult> exportWatermark({
    required String videoPath,
    required List<WatermarkLayerSpec> overlays,
    required int width,
    required int height,
    required int durationSeconds,
  }) {
    throw UnimplementedError('exportWatermark has not been implemented.');
  }

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
    throw UnimplementedError('removeSilence has not been implemented.');
  }

  Future<void> cancelExport() {
    throw UnimplementedError('cancelExport has not been implemented.');
  }

  Future<void> clearTemporaryFiles() {
    throw UnimplementedError('clearTemporaryFiles has not been implemented.');
  }
}
