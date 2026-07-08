import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;
import 'package:video_player/video_player.dart';

import '../editor/editor_state.dart' show estimateExportBytes;
import '../editor/local_editor_media_store.dart';
import '../editor/video_preset.dart';
import '../export/export_controller.dart' show videoEngineProvider;
import '../gallery/gallery_controller.dart';
import '../gallery/local_export_record.dart';

class SilenceState extends Equatable {
  const SilenceState({
    this.videoPath,
    this.videoName,
    this.sourceWidth = 0,
    this.sourceHeight = 0,
    this.sourceDurationSeconds = 0,
    this.quality = defaultExportQuality,
    this.sensitivity = 0.5,
    this.speed = 1,
    this.muteAudio = false,
    this.newAudioPath,
    this.newAudioName,
  });

  final String? videoPath;
  final String? videoName;
  final int sourceWidth;
  final int sourceHeight;
  final int sourceDurationSeconds;
  final ExportQuality quality;

  /// 0 = only near-silence removed, 1 = aggressive. Maps to a dB threshold.
  final double sensitivity;

  /// Playback speed multiplier (1x..4x) applied after cutting silence. With a
  /// replacement soundtrack, this speeds the video only — the new audio plays at
  /// normal speed and the video loops to match it.
  final int speed;

  /// Drop the original audio (silent output). Implied when [newAudioPath] is set.
  final bool muteAudio;

  /// Optional replacement soundtrack. When set, the original audio is removed,
  /// the video loops to this track's length, and the audio is not sped up.
  final String? newAudioPath;
  final String? newAudioName;

  bool get hasVideo => videoPath != null;
  bool get hasNewAudio => newAudioPath != null;

  /// Whether the exported file ends up with no audio at all.
  bool get isSilentOutput => muteAudio && newAudioPath == null;

  /// dB BELOW the loudest part that still counts as silence. −35 (gentle) cuts
  /// little; −15 (aggressive) cuts more. The native detector is peak-relative so
  /// it works on real recordings (which always have some room tone).
  double get thresholdDb => -35 + sensitivity * 20;

  ({int width, int height}) get outputResolution => sourceWidth > 0
      ? scaleDimensionsToQuality(sourceWidth, sourceHeight, quality)
      : scaledResolution(defaultVideoPreset, quality);

  /// Rough upper-bound size (the kept video is shorter once silence is cut).
  int get estimatedBytes => estimateExportBytes(
        width: outputResolution.width,
        height: outputResolution.height,
        durationSeconds: sourceDurationSeconds <= 0 ? 10 : sourceDurationSeconds,
        hasVideo: true,
        hasAudio: true,
      );

  SilenceState copyWith({
    String? videoPath,
    String? videoName,
    int? sourceWidth,
    int? sourceHeight,
    int? sourceDurationSeconds,
    ExportQuality? quality,
    double? sensitivity,
    int? speed,
    bool? muteAudio,
    String? newAudioPath,
    String? newAudioName,
    bool clearNewAudio = false,
  }) => SilenceState(
    videoPath: videoPath ?? this.videoPath,
    videoName: videoName ?? this.videoName,
    sourceWidth: sourceWidth ?? this.sourceWidth,
    sourceHeight: sourceHeight ?? this.sourceHeight,
    sourceDurationSeconds: sourceDurationSeconds ?? this.sourceDurationSeconds,
    quality: quality ?? this.quality,
    sensitivity: sensitivity ?? this.sensitivity,
    speed: speed ?? this.speed,
    muteAudio: muteAudio ?? this.muteAudio,
    newAudioPath: clearNewAudio ? null : newAudioPath ?? this.newAudioPath,
    newAudioName: clearNewAudio ? null : newAudioName ?? this.newAudioName,
  );

  @override
  List<Object?> get props => [
    videoPath,
    videoName,
    sourceWidth,
    sourceHeight,
    sourceDurationSeconds,
    quality,
    sensitivity,
    speed,
    muteAudio,
    newAudioPath,
    newAudioName,
  ];
}

final silenceControllerProvider =
    NotifierProvider<SilenceController, SilenceState>(SilenceController.new);

class SilenceController extends Notifier<SilenceState> {
  final _mediaStore = LocalEditorMediaStore();

  @override
  SilenceState build() => const SilenceState();

  Future<void> pickVideo() async {
    final path = await _pickVideoPath();
    if (path == null) return;
    final local = await _mediaStore.materializePath(
      path,
      kind: EditorMediaStoreKind.media,
    );
    if (local == null) return;
    final name = local.split(RegExp(r'[/\\]')).last;
    state = state.copyWith(videoPath: local, videoName: name);
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
      // Leave dimensions at 0; output falls back to the default preset size.
    } finally {
      await controller.dispose();
    }
  }

  void setQuality(ExportQuality quality) =>
      state = state.copyWith(quality: quality);

  void setSensitivity(double value) =>
      state = state.copyWith(sensitivity: value.clamp(0, 1));

  void setSpeed(int speed) => state = state.copyWith(speed: speed);

  void setMuteAudio(bool value) => state = state.copyWith(muteAudio: value);

  /// Picks a replacement soundtrack. Selecting one also removes the original
  /// audio (the new track takes over and sets the output length).
  Future<void> pickNewAudio() async {
    final raw = await _pickAudioPath();
    if (raw == null) return;
    final local = await _mediaStore.materializePath(
      raw,
      kind: EditorMediaStoreKind.audio,
    );
    if (local == null) return;
    final name = local.split(RegExp(r'[/\\]')).last;
    state = state.copyWith(
      newAudioPath: local,
      newAudioName: name,
      muteAudio: true,
    );
  }

  void removeNewAudio() => state = state.copyWith(clearNewAudio: true);

  void reset() => state = const SilenceState();

  /// Runs detection + cut + export and saves the result to the Library.
  Future<engine.ExportResult?> run() async {
    final path = state.videoPath;
    if (path == null) return null;
    final res = state.outputResolution;
    final result = await ref.read(videoEngineProvider).removeSilence(
          videoPath: path,
          width: res.width,
          height: res.height,
          thresholdDb: state.thresholdDb,
          speed: state.speed,
          muteAudio: state.muteAudio,
          newAudioPath: state.newAudioPath,
        );
    final now = DateTime.now();
    await ref.read(galleryControllerProvider.notifier).addRecord(
          LocalExportRecord(
            id: now.microsecondsSinceEpoch.toString(),
            outputPath: result.outputPath,
            preset: 'Silence cut · ${state.quality.label}',
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

  Future<String?> _pickAudioPath() async {
    final result = await pickImportFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav'],
    );
    return result?.files.single.path;
  }
}
