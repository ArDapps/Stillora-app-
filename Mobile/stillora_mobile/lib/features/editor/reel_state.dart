import '../../core/i18n/app_strings.dart';
import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;
import 'package:video_player/video_player.dart';

import '../../core/storage/app_preferences.dart';
import '../export/export_controller.dart' show videoEngineProvider;
import '../gallery/gallery_controller.dart';
import '../gallery/local_export_record.dart';
import 'editor_state.dart'
    show MediaKind, estimateExportBytes, mediaKindForPath;
import 'local_editor_media_store.dart';
import 'video_preset.dart';
import '../../core/pro/pro_gate.dart';

const _reelVideoExtensions = {
  'mp4',
  'mov',
  'm4v',
  'webm',
  'avi',
  'mkv',
  '3gp',
  'm2ts',
};
const _reelImageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
const _reelMediaExtensions = [..._reelImageExtensions, ..._reelVideoExtensions];

enum ReelMockup { none, iphoneTitanium, androidGraphite }

extension ReelMockupMeta on ReelMockup {
  String label(AppStrings s) => switch (this) {
    ReelMockup.none => s.rlLayerReel,
    ReelMockup.iphoneTitanium => 'iPhone 3D',
    ReelMockup.androidGraphite => 'Android 3D',
  };

  /// English short form — also what the stored export record uses.
  String get shortLabel => switch (this) {
    ReelMockup.none => 'Layers',
    ReelMockup.iphoneTitanium => 'iPhone',
    ReelMockup.androidGraphite => 'Android',
  };

  String shortLabelOf(AppStrings s) => switch (this) {
    ReelMockup.none => s.rlLayers,
    ReelMockup.iphoneTitanium => 'iPhone',
    ReelMockup.androidGraphite => 'Android',
  };
}

ReelMockup reelMockupByName(String? name) => ReelMockup.values.firstWhere(
  (mockup) => mockup.name == name,
  orElse: () => ReelMockup.iphoneTitanium,
);

class ReelLayer extends Equatable {
  const ReelLayer({
    required this.path,
    required this.kind,
    this.x = 0,
    this.y = 0,
    this.scale = 1,
    this.durationSeconds,
  });

  factory ReelLayer.fromPath(String path) =>
      ReelLayer(path: path, kind: mediaKindForPath(path));

  final String path;
  final MediaKind kind;
  final double x;
  final double y;
  final double scale;
  final int? durationSeconds;

  bool get isVideo => kind == MediaKind.video;

  String get name {
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    return slash == -1 ? path : path.substring(slash + 1);
  }

  ReelLayer copyWith({
    double? x,
    double? y,
    double? scale,
    int? durationSeconds,
  }) => ReelLayer(
    path: path,
    kind: kind,
    x: x ?? this.x,
    y: y ?? this.y,
    scale: scale ?? this.scale,
    durationSeconds: durationSeconds ?? this.durationSeconds,
  );

  @override
  List<Object?> get props => [path, kind, x, y, scale, durationSeconds];
}

class ReelState extends Equatable {
  const ReelState({
    this.layers = const [],
    this.audioPath,
    this.audioDurationSeconds,
    this.mockup = ReelMockup.iphoneTitanium,
    this.preset = defaultVideoPreset,
    this.exportQuality = defaultExportQuality,
  });

  final List<ReelLayer> layers;
  final String? audioPath;
  final int? audioDurationSeconds;
  final ReelMockup mockup;
  final VideoPreset preset;
  final ExportQuality exportQuality;

  ReelLayer? get base => layers.isEmpty ? null : layers.first;
  bool get hasMedia => layers.isNotEmpty;
  bool get hasAudio => audioPath != null;
  bool get isMockupMode => mockup != ReelMockup.none;
  bool get hasMockupVideo => isMockupMode && (base?.isVideo ?? false);

  double get aspectRatio => preset.width / preset.height;
  ({int width, int height}) get outputResolution =>
      scaledResolution(preset, exportQuality);

  int get outputDurationSeconds {
    if (audioDurationSeconds != null) return audioDurationSeconds!;
    final durations = [
      for (final layer in layers)
        if (layer.durationSeconds != null) layer.durationSeconds!,
    ];
    if (durations.isEmpty) return 0;
    return durations.reduce((a, b) => a > b ? a : b);
  }

  int get estimatedExportBytes {
    final res = outputResolution;
    return estimateExportBytes(
      width: res.width,
      height: res.height,
      durationSeconds: outputDurationSeconds <= 0 ? 5 : outputDurationSeconds,
      hasVideo: layers.any((layer) => layer.isVideo),
      hasAudio: hasAudio,
    );
  }

  ReelState copyWith({
    List<ReelLayer>? layers,
    String? audioPath,
    bool clearAudio = false,
    int? audioDurationSeconds,
    ReelMockup? mockup,
    VideoPreset? preset,
    ExportQuality? exportQuality,
  }) => ReelState(
    layers: layers ?? this.layers,
    audioPath: clearAudio ? null : audioPath ?? this.audioPath,
    audioDurationSeconds: clearAudio
        ? null
        : audioDurationSeconds ?? this.audioDurationSeconds,
    mockup: mockup ?? this.mockup,
    preset: preset ?? this.preset,
    exportQuality: exportQuality ?? this.exportQuality,
  );

  @override
  List<Object?> get props => [
    layers,
    audioPath,
    audioDurationSeconds,
    mockup,
    preset,
    exportQuality,
  ];
}

final reelControllerProvider = NotifierProvider<ReelController, ReelState>(
  ReelController.new,
);

class ReelController extends Notifier<ReelState> {
  final _mediaStore = LocalEditorMediaStore();

  @override
  ReelState build() {
    final prefs = ref.read(appPreferencesProvider);
    return _restore(prefs) ?? const ReelState();
  }

  ReelState? _restore(AppPreferences prefs) {
    final data = prefs.savedReelSession;
    if (data == null) return null;
    try {
      final rawLayers =
          (data['layers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final layers = [
        for (final layer in rawLayers)
          if (File(layer['path'] as String).existsSync())
            ReelLayer(
              path: layer['path'] as String,
              kind: mediaKindForPath(layer['path'] as String),
              durationSeconds: layer['durationSeconds'] as int?,
            ),
      ];
      final audioPath = data['audioPath'] as String?;
      final validAudio = audioPath != null && File(audioPath).existsSync()
          ? audioPath
          : null;
      return ReelState(
        layers: layers,
        audioPath: validAudio,
        audioDurationSeconds: validAudio == null
            ? null
            : data['audioDurationSeconds'] as int?,
        mockup: reelMockupByName(data['mockup'] as String?),
        preset: presetById(
          data['presetId'] as String? ?? defaultVideoPreset.id,
        ),
        exportQuality: exportQualityByName(
          data['exportQuality'] as String? ?? defaultExportQuality.name,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void _persist() {
    unawaited(
      ref.read(appPreferencesProvider).saveReelSession({
        'layers': [
          for (final layer in state.layers)
            {'path': layer.path, 'durationSeconds': layer.durationSeconds},
        ],
        'audioPath': state.audioPath,
        'audioDurationSeconds': state.audioDurationSeconds,
        'mockup': state.mockup.name,
        'presetId': state.preset.id,
        'exportQuality': state.exportQuality.name,
      }),
    );
  }

  void setMockup(ReelMockup mockup) {
    state = state.copyWith(mockup: mockup);
    _persist();
  }

  void setPreset(VideoPreset preset) {
    state = state.copyWith(preset: preset);
    _persist();
  }

  void setExportQuality(ExportQuality quality) {
    state = state.copyWith(exportQuality: quality);
    _persist();
  }

  Future<void> addMedia() async {
    final raw = state.isMockupMode
        ? await _pickRawVideoPaths()
        : await _pickRawMediaPaths();
    if (raw.isEmpty) return;
    final paths = await _mediaStore.materializeMediaPaths([raw.first]);
    if (paths.isEmpty) return;
    final layer = ReelLayer.fromPath(paths.first);
    state = state.copyWith(layers: [layer]);
    _persist();
    if (layer.isVideo) {
      unawaited(_measureDuration(layer.path));
    }
  }

  Future<void> setAudioPath(String path) async {
    final localPath = await _mediaStore.materializePath(
      path,
      kind: EditorMediaStoreKind.audio,
    );
    if (localPath == null) return;
    state = state.copyWith(audioPath: localPath, audioDurationSeconds: null);
    _persist();
    final duration = await _readDurationSeconds(localPath);
    if (state.audioPath != localPath || duration == null) return;
    state = state.copyWith(audioDurationSeconds: duration);
    _persist();
  }

  void removeAudio() {
    state = state.copyWith(clearAudio: true);
    _persist();
  }

  void reset() {
    state = const ReelState();
    unawaited(ref.read(appPreferencesProvider).clearReelSession());
  }

  Future<engine.ExportResult?> exportBase() async {
    final base = state.base;
    if (base == null) return null;
    final mediaPaths = await _mediaStore.materializeMediaPaths([base.path]);
    if (mediaPaths.isEmpty) return null;
    final audioPath = await _mediaStore.materializeAudioPath(state.audioPath);
    // Free exports top out at 720p. Clamp here, not just in the picker, so the
    // tier is enforced on the output even when the picker never got built.
    state = state.copyWith(
      exportQuality: entitledQuality(ref, state.exportQuality)!,
    );
    final res = state.outputResolution;
    final duration = state.outputDurationSeconds <= 0
        ? 5
        : state.outputDurationSeconds;
    final videoEngine = ref.read(videoEngineProvider);

    late engine.ExportResult result;
    try {
      result = await videoEngine.exportReel(
        layers: [
          engine.ReelLayerSpec(
            path: mediaPaths.first,
            isImage: !base.isVideo,
            x: 0,
            y: 0,
            scale: 1,
          ),
        ],
        audioPath: audioPath,
        width: res.width,
        height: res.height,
        durationSeconds: duration,
        mockup: state.mockup.name,
      );
    } on MissingPluginException {
      result = await videoEngine.exportVideo(
        imagePath: mediaPaths.first,
        mediaPaths: [mediaPaths.first],
        imagePaths: base.isVideo ? const [] : [mediaPaths.first],
        clipDurations: [duration],
        audioPath: audioPath,
        durationSeconds: duration,
        width: res.width,
        height: res.height,
        resizeMode: engine.ResizeMode.fill,
      );
    }

    final now = DateTime.now();
    await ref
        .read(galleryControllerProvider.notifier)
        .addRecord(
          LocalExportRecord(
            id: now.microsecondsSinceEpoch.toString(),
            outputPath: result.outputPath,
            preset: '${state.mockup.shortLabel} Reel - ${state.preset.label}',
            width: result.width,
            height: result.height,
            durationSeconds: result.durationSeconds,
            createdAt: now,
          ),
        );
    return result;
  }

  Future<void> _measureDuration(String path) async {
    final duration = await _readDurationSeconds(path);
    if (duration == null) return;
    state = state.copyWith(
      layers: [
        for (final layer in state.layers)
          layer.path == path
              ? layer.copyWith(durationSeconds: duration)
              : layer,
      ],
    );
    _persist();
  }

  Future<List<String>> _pickRawMediaPaths() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final result = await pickImportFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: _reelMediaExtensions,
      );
      return [
        for (final file in result?.files ?? const <PlatformFile>[])
          if (file.path != null) file.path!,
      ];
    }
    final picker = ImagePicker();
    final file = await picker.pickMedia();
    return file == null ? const [] : [file.path];
  }

  Future<List<String>> _pickRawVideoPaths() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final result = await pickImportFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: _reelVideoExtensions.toList(),
      );
      return [
        for (final file in result?.files ?? const <PlatformFile>[])
          if (file.path != null) file.path!,
      ];
    }
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    return file == null ? const [] : [file.path];
  }

  Future<int?> _readDurationSeconds(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final duration = controller.value.duration;
      if (duration <= Duration.zero) return null;
      return (duration.inMilliseconds / 1000).round().clamp(1, 86400);
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }
}
