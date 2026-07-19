import 'package:equatable/equatable.dart';

import '../color/color_adjust.dart';
import '../editor/editor_state.dart' show MediaKind, mediaKindForPath;
import '../editor/video_preset.dart';

/// The controller and its provider live in a sibling file; re-exported here
/// so importers keep a single entry point for the watermark feature.
export 'watermark_controller.dart';

const defaultOverlayScale = 0.3;
const minOverlayScale = 0.05;
const maxOverlayScale = 2.0;

/// A logo / image / video laid over the base video (a watermark). Position is
/// the layer's normalised top-left (0..1); [scale] is its width as a fraction of
/// the frame width. [start]/[end] are the seconds within the base video during
/// which the overlay is visible.
class WatermarkOverlay extends Equatable {
  const WatermarkOverlay({
    required this.path,
    required this.kind,
    this.x = 0.06,
    this.y = 0.06,
    this.scale = defaultOverlayScale,
    this.start = 0,
    this.end = 0,
    this.sourceDurationSeconds,
  });

  factory WatermarkOverlay.fromPath(String path, {double end = 0}) =>
      WatermarkOverlay(path: path, kind: mediaKindForPath(path), end: end);

  final String path;
  final MediaKind kind;
  final double x;
  final double y;
  final double scale;

  /// Visible window inside the base video, in seconds. The overlay is hidden
  /// before [start] and after [end].
  final double start;
  final double end;

  /// Measured length of a video overlay (null for images / not measured yet).
  final int? sourceDurationSeconds;

  bool get isVideo => kind == MediaKind.video;

  String get name {
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    return slash == -1 ? path : path.substring(slash + 1);
  }

  WatermarkOverlay copyWith({
    double? x,
    double? y,
    double? scale,
    double? start,
    double? end,
    int? sourceDurationSeconds,
  }) => WatermarkOverlay(
    path: path,
    kind: kind,
    x: (x ?? this.x).clamp(0.0, 1.0),
    y: (y ?? this.y).clamp(0.0, 1.0),
    scale: (scale ?? this.scale).clamp(minOverlayScale, maxOverlayScale),
    start: start ?? this.start,
    end: end ?? this.end,
    sourceDurationSeconds: sourceDurationSeconds ?? this.sourceDurationSeconds,
  );

  /// Whether the overlay should be drawn at base playback position [seconds].
  bool isVisibleAt(double seconds) => seconds >= start && seconds < end;

  @override
  List<Object?> get props => [
    path,
    kind,
    x,
    y,
    scale,
    start,
    end,
    sourceDurationSeconds,
  ];
}

class WatermarkState extends Equatable {
  const WatermarkState({
    this.baseVideoPath,
    this.baseWidth = 0,
    this.baseHeight = 0,
    this.baseDurationSeconds = 0,
    this.overlays = const [],
    this.selectedOverlay = 0,
    this.color = ColorAdjust.identity,
    this.quality,
  });

  final String? baseVideoPath;
  final int baseWidth;
  final int baseHeight;
  final int baseDurationSeconds;
  final List<WatermarkOverlay> overlays;
  final int selectedOverlay;

  /// Colour grade baked onto the watermarked video (desktop). Neutral default.
  final ColorAdjust color;

  /// Output resolution tier. `null` = Original (keep the source resolution).
  /// Otherwise the short edge is scaled to the tier (720p/1080p/2K/4K), aspect
  /// preserved so nothing is cropped.
  final ExportQuality? quality;

  bool get hasBase => baseVideoPath != null;
  bool get hasOverlays => overlays.isNotEmpty;
  bool get canExport => hasBase && hasOverlays;

  double get aspectRatio =>
      (baseWidth > 0 && baseHeight > 0) ? baseWidth / baseHeight : 9 / 16;

  /// Output dimensions: the source size for Original, otherwise the source
  /// scaled to the chosen quality tier (short edge → tier, aspect preserved).
  /// The native engine re-derives the exact size from the video's true display
  /// aspect, so this is used for the on-screen estimate/label.
  ({int width, int height}) get outputResolution {
    final w = baseWidth > 0 ? baseWidth : 1080;
    final h = baseHeight > 0 ? baseHeight : 1920;
    final q = quality;
    if (q == null) {
      return (width: w - (w.isOdd ? 1 : 0), height: h - (h.isOdd ? 1 : 0));
    }
    return scaleDimensionsToQuality(w, h, q);
  }

  WatermarkState copyWith({
    String? baseVideoPath,
    bool clearBase = false,
    int? baseWidth,
    int? baseHeight,
    int? baseDurationSeconds,
    List<WatermarkOverlay>? overlays,
    int? selectedOverlay,
    ColorAdjust? color,
    ExportQuality? quality,
    bool clearQuality = false,
  }) => WatermarkState(
    baseVideoPath: clearBase ? null : baseVideoPath ?? this.baseVideoPath,
    baseWidth: clearBase ? 0 : baseWidth ?? this.baseWidth,
    baseHeight: clearBase ? 0 : baseHeight ?? this.baseHeight,
    baseDurationSeconds: clearBase
        ? 0
        : baseDurationSeconds ?? this.baseDurationSeconds,
    overlays: clearBase ? const [] : overlays ?? this.overlays,
    selectedOverlay: selectedOverlay ?? this.selectedOverlay,
    color: clearBase ? ColorAdjust.identity : color ?? this.color,
    quality: clearBase || clearQuality ? null : quality ?? this.quality,
  );

  @override
  List<Object?> get props => [
    baseVideoPath,
    baseWidth,
    baseHeight,
    baseDurationSeconds,
    overlays,
    selectedOverlay,
    color,
    quality,
  ];
}
