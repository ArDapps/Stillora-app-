import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;
import 'package:video_player/video_player.dart';

import '../../core/platform/import_directory.dart';
import '../../core/platform/platform_info.dart' show isDesktopPlatform;
import '../editor/editor_state.dart' show estimateExportBytes;
import '../editor/local_editor_media_store.dart';
import '../export/desktop_ffmpeg_video_engine.dart';
import '../export/export_controller.dart' show videoEngineProvider;
import '../gallery/gallery_controller.dart';
import '../gallery/local_export_record.dart';

/// Compression strength — how small the output should be, expressed as a target
/// fraction of the source file size (HandBrake's "target quality" idea). Lower
/// fractions mean a smaller file at lower quality. The engine is handed this as
/// a hard `maxOutputBytes` cap, so the result is always smaller than the source.
enum CompressLevel {
  high('High quality', 'Barely visible loss', 0.70),
  balanced('Balanced', 'Best size / quality trade', 0.45),
  small('Small', 'Fine for sharing', 0.28),
  tiny('Tiny', 'Smallest — lower quality', 0.16);

  const CompressLevel(this.label, this.note, this.sizeFraction);

  final String label;
  final String note;

  /// Target output size as a fraction of the source file size.
  final double sizeFraction;
}

const defaultCompressLevel = CompressLevel.balanced;

/// State for the "Compress" section: upload a video and re-encode it to a
/// smaller MP4 (HandBrake-style). The size lever is a target fraction of the
/// source size — the engine caps the output to that many bytes (`fileLengthLimit`
/// on AVFoundation, a derived bitrate on ffmpeg), keeping the source resolution.
class CompressState extends Equatable {
  const CompressState({
    this.videoPath,
    this.videoName,
    this.sourceWidth = 0,
    this.sourceHeight = 0,
    this.sourceDurationSeconds = 0,
    this.sourceBytes = 0,
    this.level = defaultCompressLevel,
    this.muteAudio = false,
  });

  final String? videoPath;
  final String? videoName;
  final int sourceWidth;
  final int sourceHeight;
  final int sourceDurationSeconds;

  /// Actual size of the uploaded file, shown as the "before" figure and used to
  /// derive the size cap.
  final int sourceBytes;

  /// Target compression strength.
  final CompressLevel level;

  /// Drop the audio track for an even smaller (silent) file.
  final bool muteAudio;

  bool get hasVideo => videoPath != null;

  /// Absolute minimum we'll ever target, so a very short/aggressive combination
  /// can't ask for an unplayably small file.
  static const _floorBytes = 64 * 1024;

  /// Output resolution — the source size, kept as-is (a compressor should not
  /// change the frame), forced even for the encoder. Falls back to a portrait
  /// 1080 canvas when the source dimensions are unknown.
  ({int width, int height}) get outputResolution {
    if (sourceWidth <= 0 || sourceHeight <= 0) {
      return (width: 1080, height: 1920);
    }
    return (width: _even(sourceWidth), height: _even(sourceHeight));
  }

  /// The size cap handed to the engine. Derived from the real source size when
  /// known; otherwise from the shared bitrate estimate at the source resolution.
  /// Muting shaves off the audio budget too.
  int get targetBytes {
    final int base;
    if (sourceBytes > 0) {
      base = sourceBytes;
    } else {
      final res = outputResolution;
      base = estimateExportBytes(
        width: res.width,
        height: res.height,
        durationSeconds: sourceDurationSeconds < 1 ? 1 : sourceDurationSeconds,
        hasVideo: true,
        hasAudio: true,
      );
    }
    var target = (base * level.sizeFraction).round();
    if (muteAudio) target = (target * 0.9).round();
    return target < _floorBytes ? _floorBytes : target;
  }

  /// Shown as the estimated output size — we cap to [targetBytes], so that's the
  /// figure the user should expect (give or take the encoder's tolerance).
  int get estimatedBytes => targetBytes;

  /// Estimated size reduction vs. the source (0..100).
  int get savingsPercent {
    if (sourceBytes <= 0 || estimatedBytes >= sourceBytes) {
      // Fall back to the level's nominal reduction when we can't measure.
      return ((1 - level.sizeFraction) * 100).round();
    }
    return ((1 - estimatedBytes / sourceBytes) * 100).round();
  }

  static int _even(int value) => value.isOdd ? value + 1 : value;

  CompressState copyWith({
    String? videoPath,
    String? videoName,
    int? sourceWidth,
    int? sourceHeight,
    int? sourceDurationSeconds,
    int? sourceBytes,
    CompressLevel? level,
    bool? muteAudio,
  }) =>
      CompressState(
        videoPath: videoPath ?? this.videoPath,
        videoName: videoName ?? this.videoName,
        sourceWidth: sourceWidth ?? this.sourceWidth,
        sourceHeight: sourceHeight ?? this.sourceHeight,
        sourceDurationSeconds:
            sourceDurationSeconds ?? this.sourceDurationSeconds,
        sourceBytes: sourceBytes ?? this.sourceBytes,
        level: level ?? this.level,
        muteAudio: muteAudio ?? this.muteAudio,
      );

  @override
  List<Object?> get props => [
        videoPath,
        videoName,
        sourceWidth,
        sourceHeight,
        sourceDurationSeconds,
        sourceBytes,
        level,
        muteAudio,
      ];
}

final compressControllerProvider =
    NotifierProvider<CompressController, CompressState>(CompressController.new);

class CompressController extends Notifier<CompressState> {
  final _mediaStore = LocalEditorMediaStore();

  /// Compression needs true bitrate control. On desktop that's the bundled
  /// ffmpeg engine (average-bitrate encoding), which reliably shrinks the file.
  /// AVFoundation's `fileLengthLimit` is ignored once a videoComposition is set,
  /// so the native engine can't cap size — hence Compress is desktop-only for
  /// now (see the drawer filter). One instance is kept so [cancel] can kill the
  /// same process [run] started.
  engine.StilloraVideoEngine? _engineInstance;
  engine.StilloraVideoEngine get _engine {
    final existing = _engineInstance;
    if (existing != null) return existing;
    // macOS has no bundled FFmpeg but ships a capable native (AVFoundation)
    // engine, so it uses the same native path as mobile. Windows/Linux bundle
    // FFmpeg and use it (AVFoundation isn't available there).
    final created = (isDesktopPlatform && !Platform.isMacOS)
        ? DesktopFfmpegVideoEngine()
        : ref.read(videoEngineProvider);
    _engineInstance = created;
    return created;
  }

  @override
  CompressState build() => const CompressState();

  Future<void> pickVideo() async {
    final path = await _pickVideoPath();
    if (path == null) return;
    final local = await _mediaStore.materializePath(
      path,
      kind: EditorMediaStoreKind.media,
    );
    if (local == null) return;
    final name = local.split(RegExp(r'[/\\]')).last;
    var bytes = 0;
    try {
      bytes = File(local).lengthSync();
    } catch (_) {
      // Leave at 0 — targetBytes falls back to a resolution-based estimate.
    }
    state = state.copyWith(
      videoPath: local,
      videoName: name,
      sourceBytes: bytes,
    );
    await _readMeta(local);
  }

  Future<void> _readMeta(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final size = controller.value.size;
      final secs = controller.value.duration.inMilliseconds / 1000;
      state = state.copyWith(
        sourceWidth: size.width.round(),
        sourceHeight: size.height.round(),
        sourceDurationSeconds: secs < 1 ? 1 : secs.round(),
      );
    } catch (_) {
      // Leave dimensions at 0; output falls back to the default canvas size.
    } finally {
      await controller.dispose();
    }
  }

  void setLevel(CompressLevel level) => state = state.copyWith(level: level);

  void setMuteAudio(bool value) => state = state.copyWith(muteAudio: value);

  void reset() => state = const CompressState();

  /// Aborts an in-flight export. The engine throws a cancellation error that
  /// [run]'s caller treats as a benign stop.
  Future<void> cancel() async {
    try {
      await _engine.cancelExport();
    } catch (_) {
      // Never let a cancel failure block the user.
    }
  }

  /// Re-encodes the video under the chosen size cap and saves it to the Library.
  /// Reuses the engine's `removeSilence` pipeline with silence detection
  /// disabled (`speed: 1`, an hour-long `minSilenceMs`), so nothing is cut — the
  /// video is transcoded at the source resolution with the [CompressState.targetBytes]
  /// cap driving the bitrate down.
  Future<engine.ExportResult?> run() async {
    final path = state.videoPath;
    if (path == null) return null;
    final res = state.outputResolution;
    final result = await _engine.removeSilence(
      videoPath: path,
      width: res.width,
      height: res.height,
      thresholdDb: -80,
      minSilenceMs: 3600000,
      paddingMs: 0,
      speed: 1,
      muteAudio: state.muteAudio,
      maxOutputBytes: state.targetBytes,
    );
    final now = DateTime.now();
    await ref.read(galleryControllerProvider.notifier).addRecord(
          LocalExportRecord(
            id: now.microsecondsSinceEpoch.toString(),
            outputPath: result.outputPath,
            preset: 'Compress · ${state.level.label}',
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
      final result = await pickImportFiles(type: FileType.video);
      return result?.files.single.path;
    }
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    return picked?.path;
  }
}
