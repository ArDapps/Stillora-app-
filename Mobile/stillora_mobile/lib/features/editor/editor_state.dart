import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'video_preset.dart';

enum ResizeMode { fit, fill }

enum MediaKind { image, video }

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
    this.preset = defaultVideoPreset,
    this.durationSeconds = 10,
    this.resizeMode = ResizeMode.fit,
  });

  final List<MediaItem> media;
  final int selectedIndex;
  final String? audioPath;
  final VideoPreset preset;
  final int durationSeconds;
  final ResizeMode resizeMode;

  MediaItem? get selectedMedia =>
      media.isEmpty ? null : media[selectedIndex.clamp(0, media.length - 1)];

  /// Primary path handed to the engine. A selected video is exported on its
  /// own; otherwise this is the first image of the slideshow.
  String? get imagePath {
    final selected = selectedMedia;
    if (selected != null && selected.kind == MediaKind.video) {
      return selected.path;
    }
    return imagePaths.isNotEmpty ? imagePaths.first : selected?.path;
  }

  /// All picked images, in selection order. These are rendered as a slideshow
  /// when exporting. Videos are excluded — a video selection is exported on its
  /// own via [selectedMedia].
  List<String> get imagePaths => [
    for (final item in media)
      if (item.kind == MediaKind.image) item.path,
  ];

  bool get hasMedia => media.isNotEmpty;

  bool get canExport => media.isNotEmpty;

  EditorState copyWith({
    List<MediaItem>? media,
    int? selectedIndex,
    String? audioPath,
    bool clearAudio = false,
    VideoPreset? preset,
    int? durationSeconds,
    ResizeMode? resizeMode,
  }) {
    return EditorState(
      media: media ?? this.media,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      audioPath: clearAudio ? null : audioPath ?? this.audioPath,
      preset: preset ?? this.preset,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      resizeMode: resizeMode ?? this.resizeMode,
    );
  }

  @override
  List<Object?> get props => [
    media,
    selectedIndex,
    audioPath,
    preset,
    durationSeconds,
    resizeMode,
  ];
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

  void clearMedia() => state = state.copyWith(media: const [], selectedIndex: 0);

  void setAudioPath(String path) => state = state.copyWith(audioPath: path);

  void removeAudio() => state = state.copyWith(clearAudio: true);

  void setPreset(VideoPreset preset) => state = state.copyWith(preset: preset);

  void setDuration(int seconds) =>
      state = state.copyWith(durationSeconds: seconds);

  void setResizeMode(ResizeMode resizeMode) {
    state = state.copyWith(resizeMode: resizeMode);
  }
}
