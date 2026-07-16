import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show MissingPluginException, PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;
import 'package:video_player/video_player.dart';

import '../../core/platform/import_directory.dart';
import '../../core/platform/platform_info.dart';
import '../editor/local_editor_media_store.dart';
import '../editor/video_preset.dart';
import '../export/export_controller.dart' show videoEngineProvider;
import '../gallery/gallery_controller.dart';
import '../gallery/local_export_record.dart';
import '../watermark/watermark_state.dart' show watermarkExportSupported;

const _videoExtensions = {'mp4', 'mov', 'm4v', 'webm', 'avi', 'mkv', '3gp', 'm2ts'};
const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};

/// How to hide the watermark: paint the user's logo over it, or blur the area.
enum RemoveMode { logo, blur }

/// A rectangular target over the watermark, normalised to the frame (0..1).
/// TikTok's watermark alternates between an upper and a lower band, so the tool
/// ships one preset for each; the user can enable either/both and nudge them.
class WatermarkTarget extends Equatable {
  const WatermarkTarget({
    required this.label,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.enabled = false,
  });

  final String label;
  final double x;
  final double y;
  final double w;
  final double h;
  final bool enabled;

  WatermarkTarget copyWith({
    double? x,
    double? y,
    double? w,
    double? h,
    bool? enabled,
  }) =>
      WatermarkTarget(
        label: label,
        x: (x ?? this.x).clamp(0.0, 1.0),
        y: (y ?? this.y).clamp(0.0, 1.0),
        w: (w ?? this.w).clamp(0.05, 1.0),
        h: (h ?? this.h).clamp(0.03, 1.0),
        enabled: enabled ?? this.enabled,
      );

  @override
  List<Object?> get props => [label, x, y, w, h, enabled];
}

/// TikTok burns its @username + logo near the top and the bottom of the frame,
/// bouncing between them. These two bands cover both dwell positions.
const _defaultTargets = <WatermarkTarget>[
  WatermarkTarget(label: 'Top', x: 0.08, y: 0.06, w: 0.6, h: 0.10, enabled: true),
  WatermarkTarget(label: 'Bottom', x: 0.08, y: 0.83, w: 0.6, h: 0.10, enabled: true),
];

class RemoveWatermarkState extends Equatable {
  const RemoveWatermarkState({
    this.baseVideoPath,
    this.baseWidth = 0,
    this.baseHeight = 0,
    this.baseDurationSeconds = 0,
    this.mode = RemoveMode.blur,
    this.targets = _defaultTargets,
    this.selectedTarget = 0,
    this.strength = 0.6,
    this.logoPath,
    this.quality,
  });

  final String? baseVideoPath;
  final int baseWidth;
  final int baseHeight;
  final int baseDurationSeconds;
  final RemoveMode mode;
  final List<WatermarkTarget> targets;
  final int selectedTarget;

  /// Blur strength (0..1) for [RemoveMode.blur].
  final double strength;

  /// The logo image overlaid in [RemoveMode.logo].
  final String? logoPath;

  final ExportQuality? quality;

  bool get hasBase => baseVideoPath != null;
  List<WatermarkTarget> get enabledTargets =>
      [for (final t in targets) if (t.enabled) t];
  bool get hasTarget => enabledTargets.isNotEmpty;

  bool get canExport =>
      hasBase &&
      hasTarget &&
      (mode == RemoveMode.blur || logoPath != null);

  double get aspectRatio =>
      (baseWidth > 0 && baseHeight > 0) ? baseWidth / baseHeight : 9 / 16;

  ({int width, int height}) get outputResolution {
    final w = baseWidth > 0 ? baseWidth : 1080;
    final h = baseHeight > 0 ? baseHeight : 1920;
    final q = quality;
    if (q == null) {
      return (width: w - (w.isOdd ? 1 : 0), height: h - (h.isOdd ? 1 : 0));
    }
    return scaleDimensionsToQuality(w, h, q);
  }

  RemoveWatermarkState copyWith({
    String? baseVideoPath,
    bool clearBase = false,
    int? baseWidth,
    int? baseHeight,
    int? baseDurationSeconds,
    RemoveMode? mode,
    List<WatermarkTarget>? targets,
    int? selectedTarget,
    double? strength,
    String? logoPath,
    bool clearLogo = false,
    ExportQuality? quality,
    bool clearQuality = false,
  }) =>
      RemoveWatermarkState(
        baseVideoPath: clearBase ? null : baseVideoPath ?? this.baseVideoPath,
        baseWidth: clearBase ? 0 : baseWidth ?? this.baseWidth,
        baseHeight: clearBase ? 0 : baseHeight ?? this.baseHeight,
        baseDurationSeconds:
            clearBase ? 0 : baseDurationSeconds ?? this.baseDurationSeconds,
        mode: mode ?? this.mode,
        targets: clearBase ? _defaultTargets : targets ?? this.targets,
        selectedTarget: selectedTarget ?? this.selectedTarget,
        strength: strength ?? this.strength,
        logoPath: clearBase || clearLogo ? null : logoPath ?? this.logoPath,
        quality: clearBase || clearQuality ? null : quality ?? this.quality,
      );

  @override
  List<Object?> get props => [
        baseVideoPath,
        baseWidth,
        baseHeight,
        baseDurationSeconds,
        mode,
        targets,
        selectedTarget,
        strength,
        logoPath,
        quality,
      ];
}

/// Thrown when blur removal is requested on a platform whose native engine
/// doesn't implement it yet (iOS/Android/macOS). The UI turns this into a hint
/// to use Logo mode or run on Windows/Linux.
class BlurUnavailableException implements Exception {
  const BlurUnavailableException();
}

final removeWatermarkControllerProvider =
    NotifierProvider<RemoveWatermarkController, RemoveWatermarkState>(
  RemoveWatermarkController.new,
);

class RemoveWatermarkController extends Notifier<RemoveWatermarkState> {
  final _mediaStore = LocalEditorMediaStore();

  @override
  RemoveWatermarkState build() => const RemoveWatermarkState();

  Future<void> pickBaseVideo() async {
    final path = await _pickVideoPath();
    if (path == null) return;
    final local =
        await _mediaStore.materializePath(path, kind: EditorMediaStoreKind.media);
    if (local == null) return;
    state = RemoveWatermarkState(baseVideoPath: local);
    final meta = await _readVideoMeta(local);
    if (state.baseVideoPath != local || meta == null) return;
    state = state.copyWith(
      baseWidth: meta.width,
      baseHeight: meta.height,
      baseDurationSeconds: meta.seconds,
    );
  }

  Future<void> pickLogo() async {
    final path = await _pickImagePath();
    if (path == null) return;
    final local =
        await _mediaStore.materializePath(path, kind: EditorMediaStoreKind.media);
    if (local == null) return;
    state = state.copyWith(logoPath: local, mode: RemoveMode.logo);
  }

  void setMode(RemoveMode mode) => state = state.copyWith(mode: mode);

  void setStrength(double strength) =>
      state = state.copyWith(strength: strength.clamp(0.05, 1.0));

  void selectTarget(int index) {
    if (index < 0 || index >= state.targets.length) return;
    state = state.copyWith(selectedTarget: index);
  }

  void toggleTarget(int index, bool enabled) {
    if (index < 0 || index >= state.targets.length) return;
    final next = [...state.targets];
    next[index] = next[index].copyWith(enabled: enabled);
    state = state.copyWith(targets: next, selectedTarget: index);
  }

  void setTargetRect(int index, {double? x, double? y, double? w, double? h}) {
    if (index < 0 || index >= state.targets.length) return;
    final next = [...state.targets];
    next[index] = next[index].copyWith(x: x, y: y, w: w, h: h);
    state = state.copyWith(targets: next);
  }

  void setQuality(ExportQuality? quality) => state = quality == null
      ? state.copyWith(clearQuality: true)
      : state.copyWith(quality: quality);

  Future<void> cancel() async {
    try {
      await ref.read(videoEngineProvider).cancelExport();
    } catch (_) {}
  }

  void reset() => state = const RemoveWatermarkState();

  /// Exports the cleaned video to the Library. Blur mode calls the engine's
  /// [engine.StilloraVideoEngine.removeWatermark]; logo mode paints the logo over
  /// each target via [engine.StilloraVideoEngine.exportWatermark].
  Future<engine.ExportResult?> export() async {
    if (!state.canExport) return null;
    final basePaths =
        await _mediaStore.materializeMediaPaths([state.baseVideoPath!]);
    if (basePaths.isEmpty) return null;
    final basePath = basePaths.first;
    final res = state.outputResolution;
    final duration =
        state.baseDurationSeconds <= 0 ? 5 : state.baseDurationSeconds;
    final videoEngine = ref.read(videoEngineProvider);
    final targets = state.enabledTargets;

    debugPrint(
      '[RemoveWatermark] mode=${state.mode} targets=${targets.length} '
      '${res.width}x${res.height} engine=${videoEngine.runtimeType}',
    );

    engine.ExportResult result;
    if (state.mode == RemoveMode.blur) {
      try {
        result = await videoEngine.removeWatermark(
          videoPath: basePath,
          regions: [
            for (final t in targets)
              engine.BlurRegionSpec(
                x: t.x,
                y: t.y,
                w: t.w,
                h: t.h,
                start: 0,
                end: duration.toDouble(),
                strength: state.strength,
              ),
          ],
          width: res.width,
          height: res.height,
          durationSeconds: duration,
        );
      } on MissingPluginException {
        throw const BlurUnavailableException();
      } on UnimplementedError {
        throw const BlurUnavailableException();
      } on PlatformException catch (e) {
        if (e.code == 'not_implemented' || e.code == 'unimplemented') {
          throw const BlurUnavailableException();
        }
        rethrow;
      }
    } else {
      // Logo mode: one overlay per target, logo width ≈ the target width.
      final logoPaths =
          await _mediaStore.materializeMediaPaths([state.logoPath!]);
      if (logoPaths.isEmpty) return null;
      final logo = logoPaths.first;
      result = await videoEngine.exportWatermark(
        videoPath: basePath,
        overlays: [
          for (final t in targets)
            engine.WatermarkLayerSpec(
              path: logo,
              isImage: true,
              x: t.x,
              y: t.y,
              scale: t.w,
              start: 0,
              end: duration.toDouble(),
            ),
        ],
        width: res.width,
        height: res.height,
        durationSeconds: duration,
      );
    }

    final now = DateTime.now();
    await ref.read(galleryControllerProvider.notifier).addRecord(
          LocalExportRecord(
            id: now.microsecondsSinceEpoch.toString(),
            outputPath: result.outputPath,
            preset: 'No Watermark',
            width: result.width,
            height: result.height,
            durationSeconds: result.durationSeconds,
            createdAt: now,
          ),
        );
    return result;
  }

  Future<String?> _pickVideoPath() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final result = await pickImportFiles(
        type: FileType.custom,
        allowedExtensions: _videoExtensions.toList(),
      );
      return result?.files.single.path;
    }
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    return file?.path;
  }

  Future<String?> _pickImagePath() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final result = await pickImportFiles(
        type: FileType.custom,
        allowedExtensions: _imageExtensions.toList(),
      );
      return result?.files.single.path;
    }
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    return file?.path;
  }

  Future<({int width, int height, int seconds})?> _readVideoMeta(
    String path,
  ) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final size = controller.value.size;
      final duration = controller.value.duration;
      if (size.width <= 0 || size.height <= 0) return null;
      final secs = (duration.inMilliseconds / 1000).round();
      return (
        width: size.width.round(),
        height: size.height.round(),
        seconds: secs < 1 ? 1 : secs,
      );
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }
}

/// Whether this platform can export a cleaned video today. Blur needs the FFmpeg
/// desktop engine (Windows/Linux); logo cover also works on macOS native.
bool get removeWatermarkSupported => watermarkExportSupported;

/// Whether real blur (not just logo cover) is available on this platform.
bool get blurRemovalSupported => useFfmpegDesktopExport;
