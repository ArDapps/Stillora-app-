import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/storage/app_preferences.dart';
import 'video_preset.dart';

enum ResizeMode { fit, fill }

enum MediaKind { image, video }

const defaultDurationSeconds = 10;
const minDurationSeconds = 1;
const maxDurationSeconds = 300;
const _unset = Object();

const _videoExtensions = {
  'mp4',
  'mov',
  'm4v',
  'webm',
  'avi',
  'mkv',
  '3gp',
  'm2ts',
};
const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
const _desktopMediaExtensions = [..._imageExtensions, ..._videoExtensions];

MediaKind mediaKindForPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) {
    return MediaKind.image;
  }
  final ext = path.substring(dot + 1).toLowerCase();
  return _videoExtensions.contains(ext) ? MediaKind.video : MediaKind.image;
}

class MediaItem extends Equatable {
  const MediaItem({
    required this.path,
    required this.kind,
    this.durationSeconds = defaultDurationSeconds,
  });

  factory MediaItem.fromPath(
    String path, {
    int durationSeconds = defaultDurationSeconds,
  }) => MediaItem(
    path: path,
    kind: mediaKindForPath(path),
    durationSeconds: normalizeDurationSeconds(durationSeconds),
  );

  final String path;
  final MediaKind kind;

  /// How many seconds this clip occupies in the exported timeline.
  final int durationSeconds;

  String get name {
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    return slash == -1 ? path : path.substring(slash + 1);
  }

  MediaItem copyWith({int? durationSeconds}) => MediaItem(
    path: path,
    kind: kind,
    durationSeconds: normalizeDurationSeconds(
      durationSeconds ?? this.durationSeconds,
    ),
  );

  @override
  List<Object?> get props => [path, kind, durationSeconds];
}

class EditorState extends Equatable {
  const EditorState({
    this.media = const [],
    this.selectedIndex = 0,
    this.audioPath,
    this.audioDurationSeconds,
    this.preset = defaultVideoPreset,
    this.durationSeconds = defaultDurationSeconds,
    this.resizeMode = ResizeMode.fit,
  });

  final List<MediaItem> media;
  final int selectedIndex;
  final String? audioPath;
  final int? audioDurationSeconds;
  final VideoPreset preset;
  final int durationSeconds;
  final ResizeMode resizeMode;

  MediaItem? get selectedMedia =>
      media.isEmpty ? null : media[selectedIndex.clamp(0, media.length - 1)];

  /// Primary path handed to the engine for backwards compatibility.
  String? get imagePath => mediaPaths.isNotEmpty ? mediaPaths.first : null;

  /// Every selected media item in timeline order.
  List<String> get mediaPaths => [for (final item in media) item.path];

  /// Picked images in timeline order. Older native engines use this as a
  /// fallback, while mixed timeline export uses [mediaPaths].
  List<String> get imagePaths => [
    for (final item in media)
      if (item.kind == MediaKind.image) item.path,
  ];

  bool get hasImages => imagePaths.isNotEmpty;

  bool get hasVideos => media.any((item) => item.kind == MediaKind.video);

  bool get exportsMixedTimeline => hasImages && hasVideos;

  bool get exportsImageSlideshow => hasImages && !hasVideos;

  bool get exportsVideoSource =>
      !hasImages && media.length == 1 && selectedMedia?.kind == MediaKind.video;

  bool get hasMedia => media.isNotEmpty;

  bool get canExport => media.isNotEmpty;

  /// Per-clip durations in timeline order. Parallel to [mediaPaths].
  List<int> get clipDurations => [
    for (final item in media) item.durationSeconds,
  ];

  /// Total length of the exported video. With media this is the sum of every
  /// clip's duration; with no media it falls back to the baseline
  /// [durationSeconds] used by the duration controls.
  int get totalDurationSeconds => media.isEmpty
      ? durationSeconds
      : media.fold(0, (sum, item) => sum + item.durationSeconds);

  EditorState copyWith({
    List<MediaItem>? media,
    int? selectedIndex,
    String? audioPath,
    bool clearAudio = false,
    Object? audioDurationSeconds = _unset,
    VideoPreset? preset,
    int? durationSeconds,
    ResizeMode? resizeMode,
  }) {
    final int? nextAudioDurationSeconds;
    if (clearAudio) {
      nextAudioDurationSeconds = null;
    } else if (identical(audioDurationSeconds, _unset)) {
      nextAudioDurationSeconds = this.audioDurationSeconds;
    } else {
      nextAudioDurationSeconds = audioDurationSeconds as int?;
    }

    return EditorState(
      media: media ?? this.media,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      audioPath: clearAudio ? null : audioPath ?? this.audioPath,
      audioDurationSeconds: nextAudioDurationSeconds,
      preset: preset ?? this.preset,
      durationSeconds: normalizeDurationSeconds(
        durationSeconds ?? this.durationSeconds,
      ),
      resizeMode: resizeMode ?? this.resizeMode,
    );
  }

  @override
  List<Object?> get props => [
    media,
    selectedIndex,
    audioPath,
    audioDurationSeconds,
    preset,
    durationSeconds,
    resizeMode,
  ];
}

int normalizeDurationSeconds(num seconds) {
  return seconds.round().clamp(minDurationSeconds, maxDurationSeconds).toInt();
}

final editorControllerProvider =
    NotifierProvider<EditorController, EditorState>(EditorController.new);

class EditorController extends Notifier<EditorState> {
  @override
  EditorState build() {
    final prefs = ref.read(appPreferencesProvider);
    return _restoreSession(prefs) ?? const EditorState();
  }

  /// Restores the last saved session. Returns null if nothing was saved or
  /// if the saved data is unreadable. Media items whose files no longer exist
  /// on disk are silently dropped (handles cleaned-up mobile temp paths).
  EditorState? _restoreSession(AppPreferences prefs) {
    final data = prefs.savedEditorSession;
    if (data == null) return null;
    try {
      final rawMedia =
          (data['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final media = [
        for (final item in rawMedia)
          if (File(item['path'] as String).existsSync())
            MediaItem.fromPath(
              item['path'] as String,
              durationSeconds:
                  (item['d'] as int?) ?? defaultDurationSeconds,
            ),
      ];
      final audioPath = data['audioPath'] as String?;
      final validAudio =
          audioPath != null && File(audioPath).existsSync() ? audioPath : null;
      return EditorState(
        media: media,
        selectedIndex: 0,
        audioPath: validAudio,
        audioDurationSeconds:
            validAudio != null ? data['audioDurationSeconds'] as int? : null,
        preset: presetById(data['presetId'] as String? ?? 'reels'),
        durationSeconds: normalizeDurationSeconds(
          (data['durationSeconds'] as int?) ?? defaultDurationSeconds,
        ),
        resizeMode: data['resizeMode'] == 'fill' ? ResizeMode.fill : ResizeMode.fit,
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves the current state to SharedPreferences asynchronously.
  void _persist() {
    final prefs = ref.read(appPreferencesProvider);
    unawaited(prefs.saveEditorSession({
      'media': [
        for (final item in state.media)
          {'path': item.path, 'd': item.durationSeconds},
      ],
      'audioPath': state.audioPath,
      'audioDurationSeconds': state.audioDurationSeconds,
      'presetId': state.preset.id,
      'durationSeconds': state.durationSeconds,
      'resizeMode': state.resizeMode == ResizeMode.fill ? 'fill' : 'fit',
    }));
  }

  /// Lets the user pick multiple images, videos, or a mix of both.
  Future<void> pickMedia() async {
    final paths = await _pickMediaPaths();
    if (paths.isEmpty) {
      return;
    }
    // Spread the baseline duration evenly so the initial timeline keeps the
    // familiar total (e.g. 10s split across the chosen clips).
    final durations = _distributeEvenly(paths.length, state.durationSeconds);
    final items = [
      for (var i = 0; i < paths.length; i++)
        MediaItem.fromPath(paths[i], durationSeconds: durations[i]),
    ];
    state = state.copyWith(media: items, selectedIndex: 0);
    _persist();
  }

  /// Appends more media to the current selection.
  Future<void> addMedia() async {
    final paths = await _pickMediaPaths();
    if (paths.isEmpty) {
      return;
    }
    final existing = {for (final item in state.media) item.path};
    // New clips adopt the current average clip length so the timeline grows
    // predictably; the user can fine-tune each one afterwards.
    final defaultClip = _defaultClipSeconds(state.media);
    final additions = [
      for (final path in paths)
        if (!existing.contains(path))
          MediaItem.fromPath(path, durationSeconds: defaultClip),
    ];
    if (additions.isEmpty) {
      return;
    }
    state = state.copyWith(media: [...state.media, ...additions]);
    _persist();
  }

  Future<List<String>> _pickMediaPaths() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _desktopMediaExtensions,
      );
      return [
        for (final file in result?.files ?? const <PlatformFile>[])
          if (file.path != null) file.path!,
      ];
    }

    final picker = ImagePicker();
    final files = await picker.pickMultipleMedia();
    return [for (final file in files) file.path];
  }

  /// Sets the duration of a single clip without touching the others.
  void setClipDuration(int index, int seconds) {
    if (index < 0 || index >= state.media.length) {
      return;
    }
    final next = [...state.media];
    next[index] = next[index].copyWith(
      durationSeconds: normalizeDurationSeconds(seconds),
    );
    state = state.copyWith(media: next);
    _persist();
  }

  int _defaultClipSeconds(List<MediaItem> media) {
    if (media.isEmpty) {
      return state.durationSeconds;
    }
    final total = media.fold(0, (sum, item) => sum + item.durationSeconds);
    return normalizeDurationSeconds((total / media.length).round());
  }

  /// Splits [total] seconds across [count] clips as evenly as possible, handing
  /// the remainder to the earliest clips so the parts sum back to [total].
  List<int> _distributeEvenly(int count, int total) {
    if (count <= 0) {
      return const [];
    }
    final clamped = normalizeDurationSeconds(total);
    final base = clamped ~/ count;
    final remainder = clamped - base * count;
    return [
      for (var i = 0; i < count; i++)
        (base + (i < remainder ? 1 : 0)).clamp(
          minDurationSeconds,
          maxDurationSeconds,
        ),
    ];
  }

  void selectMedia(int index) {
    if (index < 0 || index >= state.media.length) {
      return;
    }
    state = state.copyWith(selectedIndex: index);
  }

  void removeMediaAt(int index) {
    if (index < 0 || index >= state.media.length) {
      return;
    }
    final next = [...state.media]..removeAt(index);
    var selected = state.selectedIndex;
    if (selected >= next.length) {
      selected = next.isEmpty ? 0 : next.length - 1;
    } else if (index < selected) {
      selected -= 1;
    }
    state = state.copyWith(media: next, selectedIndex: selected);
    _persist();
  }

  void reorderMedia(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.media.length) {
      return;
    }
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 || targetIndex >= state.media.length) {
      return;
    }
    final next = [...state.media];
    final moved = next.removeAt(oldIndex);
    next.insert(targetIndex, moved);
    state = state.copyWith(media: next, selectedIndex: targetIndex);
    _persist();
  }

  void clearMedia() {
    state = state.copyWith(media: const [], selectedIndex: 0);
    _persist();
  }

  Future<void> setAudioPath(String path) async {
    state = state.copyWith(audioPath: path, audioDurationSeconds: null);
    final duration = await _readMediaDurationSeconds(path);
    if (state.audioPath != path || duration == null) {
      return;
    }
    final durations = _distributeEvenly(state.media.length, duration);
    final next = state.media.isEmpty
        ? state.media
        : [
            for (var i = 0; i < state.media.length; i++)
              state.media[i].copyWith(durationSeconds: durations[i]),
          ];
    state = state.copyWith(
      media: next,
      audioDurationSeconds: duration,
      durationSeconds: duration,
    );
    _persist();
  }

  void removeAudio() {
    state = state.copyWith(clearAudio: true);
    _persist();
  }

  void setPreset(VideoPreset preset) {
    state = state.copyWith(preset: preset);
    _persist();
  }

  /// Sets the overall target duration and re-splits it evenly across every
  /// clip. Use [setClipDuration] to bias an individual clip afterwards.
  void setDuration(int seconds) {
    final normalized = normalizeDurationSeconds(seconds);
    if (state.media.isEmpty) {
      state = state.copyWith(durationSeconds: normalized);
      _persist();
      return;
    }
    final durations = _distributeEvenly(state.media.length, normalized);
    final next = [
      for (var i = 0; i < state.media.length; i++)
        state.media[i].copyWith(durationSeconds: durations[i]),
    ];
    state = state.copyWith(media: next, durationSeconds: normalized);
    _persist();
  }

  void setResizeMode(ResizeMode resizeMode) {
    state = state.copyWith(resizeMode: resizeMode);
    _persist();
  }

  Future<int?> _readMediaDurationSeconds(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final duration = controller.value.duration;
      if (duration <= Duration.zero) {
        return null;
      }
      return normalizeDurationSeconds(duration.inMilliseconds / 1000);
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }
}
