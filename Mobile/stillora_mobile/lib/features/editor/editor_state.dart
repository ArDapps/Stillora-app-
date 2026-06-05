import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

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

MediaKind mediaKindForPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) {
    return MediaKind.image;
  }
  final ext = path.substring(dot + 1).toLowerCase();
  return _videoExtensions.contains(ext) ? MediaKind.video : MediaKind.image;
}

class MediaItem extends Equatable {
  const MediaItem({required this.path, required this.kind});

  factory MediaItem.fromPath(String path) =>
      MediaItem(path: path, kind: mediaKindForPath(path));

  final String path;
  final MediaKind kind;

  String get name {
    final slash = path.lastIndexOf('/');
    return slash == -1 ? path : path.substring(slash + 1);
  }

  @override
  List<Object?> get props => [path, kind];
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
  EditorState build() => const EditorState();

  /// Lets the user pick multiple images, videos, or a mix of both.
  Future<void> pickMedia() async {
    final picker = ImagePicker();
    final files = await picker.pickMultipleMedia();
    if (files.isEmpty) {
      return;
    }
    final items = [for (final file in files) MediaItem.fromPath(file.path)];
    state = state.copyWith(media: items, selectedIndex: 0);
  }

  /// Appends more media to the current selection.
  Future<void> addMedia() async {
    final picker = ImagePicker();
    final files = await picker.pickMultipleMedia();
    if (files.isEmpty) {
      return;
    }
    final existing = {for (final item in state.media) item.path};
    final additions = [
      for (final file in files)
        if (!existing.contains(file.path)) MediaItem.fromPath(file.path),
    ];
    if (additions.isEmpty) {
      return;
    }
    state = state.copyWith(media: [...state.media, ...additions]);
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
  }

  void clearMedia() =>
      state = state.copyWith(media: const [], selectedIndex: 0);

  Future<void> setAudioPath(String path) async {
    state = state.copyWith(audioPath: path, audioDurationSeconds: null);
    final duration = await _readMediaDurationSeconds(path);
    if (state.audioPath != path || duration == null) {
      return;
    }
    state = state.copyWith(
      audioDurationSeconds: duration,
      durationSeconds: duration,
    );
  }

  void removeAudio() => state = state.copyWith(clearAudio: true);

  void setPreset(VideoPreset preset) => state = state.copyWith(preset: preset);

  void setDuration(int seconds) => state = state.copyWith(
    durationSeconds: normalizeDurationSeconds(seconds),
  );

  void setResizeMode(ResizeMode resizeMode) {
    state = state.copyWith(resizeMode: resizeMode);
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
