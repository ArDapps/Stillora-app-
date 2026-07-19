import 'package:equatable/equatable.dart';

import '../color/color_adjust.dart';
import 'editor_duration.dart';
import 'editor_export_estimate.dart';
import 'editor_media_item.dart';
import 'video_preset.dart';
import 'video_styles.dart';

// The immutable Create-flow state and its derived getters.
// Split out of `editor_state.dart` unchanged.

const _unset = Object();

class EditorState extends Equatable {
  const EditorState({
    this.media = const [],
    this.selectedIndex = 0,
    this.audioPath,
    this.audioDurationSeconds,
    this.audioIsNarration = false,
    this.preset = defaultVideoPreset,
    this.durationSeconds = defaultDurationSeconds,
    this.resizeMode = ResizeMode.fit,
    this.exportQuality = defaultExportQuality,
    this.effect = ClipEffect.none,
    this.transition = FrameTransition.none,
    this.color = ColorAdjust.identity,
  });

  final List<MediaItem> media;
  final int selectedIndex;
  final String? audioPath;
  final int? audioDurationSeconds;

  /// Preview style applied to the Create output (preview-only).
  final ClipEffect effect;
  final FrameTransition transition;

  /// Colour grade baked onto the exported video (desktop). Neutral by default.
  final ColorAdjust color;

  /// True when the attached audio came from the Voice Narration recorder rather
  /// than a picked soundtrack file. Only affects how the editor labels it.
  final bool audioIsNarration;

  final VideoPreset preset;
  final int durationSeconds;
  final ResizeMode resizeMode;
  final ExportQuality exportQuality;

  /// Final encode dimensions: the preset's aspect ratio scaled to the chosen
  /// [exportQuality].
  ({int width, int height}) get outputResolution =>
      scaledResolution(preset, exportQuality);

  /// Rough estimate of the exported file size in bytes for the Create flow.
  int get estimatedExportBytes => estimateExportBytes(
    width: outputResolution.width,
    height: outputResolution.height,
    durationSeconds: totalDurationSeconds,
    hasVideo: hasVideos,
    hasAudio: audioPath != null,
  );

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

  /// Per-clip audio volumes (0..1) in timeline order. Parallel to [mediaPaths].
  List<double> get clipVolumes => [for (final item in media) item.volume];

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
    bool? audioIsNarration,
    VideoPreset? preset,
    int? durationSeconds,
    ResizeMode? resizeMode,
    ExportQuality? exportQuality,
    ClipEffect? effect,
    FrameTransition? transition,
    ColorAdjust? color,
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
      audioIsNarration: clearAudio
          ? false
          : audioIsNarration ?? this.audioIsNarration,
      preset: preset ?? this.preset,
      durationSeconds: normalizeDurationSeconds(
        durationSeconds ?? this.durationSeconds,
      ),
      resizeMode: resizeMode ?? this.resizeMode,
      exportQuality: exportQuality ?? this.exportQuality,
      effect: effect ?? this.effect,
      transition: transition ?? this.transition,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [
    media,
    selectedIndex,
    audioPath,
    audioDurationSeconds,
    audioIsNarration,
    preset,
    durationSeconds,
    resizeMode,
    exportQuality,
    effect,
    transition,
    color,
  ];
}
