import 'package:equatable/equatable.dart';

import 'editor_duration.dart';

// A single timeline entry (image or video) plus the file-type helpers that
// classify it. Split out of `editor_state.dart` unchanged.

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
const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};

/// Extensions offered by the desktop file picker (was `_desktopMediaExtensions`
/// — made public so the controller can reach it from its own file).
const desktopMediaExtensions = [..._imageExtensions, ..._videoExtensions];

MediaKind mediaKindForPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) {
    return MediaKind.image;
  }
  final ext = path.substring(dot + 1).toLowerCase();
  return _videoExtensions.contains(ext) ? MediaKind.video : MediaKind.image;
}

/// Default per-clip audio volume (full source loudness). 0 = muted.
const defaultClipVolume = 1.0;

double normalizeClipVolume(double volume) => volume.clamp(0.0, 1.0);

class MediaItem extends Equatable {
  const MediaItem({
    required this.path,
    required this.kind,
    this.durationSeconds = defaultDurationSeconds,
    this.volume = defaultClipVolume,
    this.width = 0,
    this.height = 0,
  });

  factory MediaItem.fromPath(
    String path, {
    int durationSeconds = defaultDurationSeconds,
    double volume = defaultClipVolume,
    int width = 0,
    int height = 0,
  }) => MediaItem(
    path: path,
    kind: mediaKindForPath(path),
    durationSeconds: normalizeDurationSeconds(durationSeconds),
    volume: normalizeClipVolume(volume),
    width: width,
    height: height,
  );

  final String path;
  final MediaKind kind;

  /// How many seconds this clip occupies in the exported timeline.
  final int durationSeconds;

  /// Loudness of this clip's own soundtrack in the export, 0..1. Only video
  /// clips carry audio; 0 mutes the clip. Applied on platforms that keep the
  /// source video's audio (iOS/macOS single-video export).
  final double volume;

  /// Native pixel size of the source, measured after the file is added (0 until
  /// probed / when it could not be read). Feeds the "Original Size" preset so
  /// the export keeps the source's own dimensions instead of a fixed square.
  final int width;
  final int height;

  bool get isMuted => volume <= 0;

  /// True once the native size has been measured.
  bool get hasDimensions => width > 0 && height > 0;

  /// A `1920×1080` style label, or null before the size is known.
  String? get dimensionsLabel => hasDimensions ? '$width×$height' : null;

  String get name {
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    return slash == -1 ? path : path.substring(slash + 1);
  }

  MediaItem copyWith({
    int? durationSeconds,
    double? volume,
    int? width,
    int? height,
  }) => MediaItem(
    path: path,
    kind: kind,
    durationSeconds: normalizeDurationSeconds(
      durationSeconds ?? this.durationSeconds,
    ),
    volume: normalizeClipVolume(volume ?? this.volume),
    width: width ?? this.width,
    height: height ?? this.height,
  );

  @override
  List<Object?> get props => [
    path,
    kind,
    durationSeconds,
    volume,
    width,
    height,
  ];
}
