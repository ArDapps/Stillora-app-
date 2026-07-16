import 'package:equatable/equatable.dart';

enum ResizeMode { fit, fill }

enum VideoEffect { none }

/// One layer for a Reel composite. [x]/[y] are the normalised top-left (0..1)
/// and [scale] is the layer width as a fraction of the output width.
/// [start]/[end] are the seconds during which the layer is drawn — used by 3D
/// object overlays to sync to the voice/audio window. When null the layer shows
/// for the whole reel (the default for background + media layers).
class ReelLayerSpec extends Equatable {
  const ReelLayerSpec({
    required this.path,
    required this.isImage,
    required this.x,
    required this.y,
    required this.scale,
    this.start,
    this.end,
  });

  final String path;
  final bool isImage;
  final double x;
  final double y;
  final double scale;
  final double? start;
  final double? end;

  Map<String, Object?> toMap() => {
    'path': path,
    'isImage': isImage,
    'x': x,
    'y': y,
    'scale': scale,
    if (start != null) 'start': start,
    if (end != null) 'end': end,
  };

  @override
  List<Object?> get props => [path, isImage, x, y, scale, start, end];
}

/// One overlay for a watermark composite. [x]/[y] are the normalised top-left
/// (0..1) and [scale] is the layer width as a fraction of the output width.
/// [start]/[end] are the seconds within the base video during which the overlay
/// is shown. [fadeIn]/[fadeOut] are the seconds over which the overlay ramps its
/// opacity up at [start] and down before [end] (0 = a hard cut). The fade
/// windows are clamped so they never overlap past the middle of the visible
/// span.
class WatermarkLayerSpec extends Equatable {
  const WatermarkLayerSpec({
    required this.path,
    required this.isImage,
    required this.x,
    required this.y,
    required this.scale,
    required this.start,
    required this.end,
    this.fadeIn = 0,
    this.fadeOut = 0,
  });

  final String path;
  final bool isImage;
  final double x;
  final double y;
  final double scale;
  final double start;
  final double end;
  final double fadeIn;
  final double fadeOut;

  Map<String, Object?> toMap() => {
    'path': path,
    'isImage': isImage,
    'x': x,
    'y': y,
    'scale': scale,
    'start': start,
    'end': end,
    'fadeIn': fadeIn,
    'fadeOut': fadeOut,
  };

  @override
  List<Object?> get props =>
      [path, isImage, x, y, scale, start, end, fadeIn, fadeOut];
}

/// A rectangular region of the frame to blur out — used to hide a burned-in
/// watermark (e.g. TikTok's). Coordinates are normalised to the frame
/// (0..1): [x]/[y] are the top-left, [w]/[h] the size. [start]/[end] are the
/// seconds during which the blur is applied (the whole clip when equal to the
/// full duration). [strength] is the blur radius as a fraction of the region's
/// smaller side (0.05..1.0); higher is blurrier.
class BlurRegionSpec extends Equatable {
  const BlurRegionSpec({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.start,
    required this.end,
    this.strength = 0.5,
  });

  final double x;
  final double y;
  final double w;
  final double h;
  final double start;
  final double end;
  final double strength;

  Map<String, Object?> toMap() => {
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    'start': start,
    'end': end,
    'strength': strength,
  };

  @override
  List<Object?> get props => [x, y, w, h, start, end, strength];
}

/// A baked color grade to apply to a finished video as a post-process pass.
///
/// The values are the *derived*, engine-ready form of the app's colour sliders
/// (see the app-side `ColorAdjust`). The three per-channel [rGain]/[gGain]/
/// [bGain] multipliers fold exposure + warmth + tint into one diagonal matrix,
/// while [brightness]/[contrast]/[saturation] map straight onto CoreImage's
/// `CIColorControls` and ffmpeg's `eq`. Keeping the maths in one Dart place lets
/// the Flutter live preview, the ffmpeg desktop pass and the macOS CoreImage
/// pass all produce the same look.
class ColorAdjustSpec extends Equatable {
  const ColorAdjustSpec({
    this.rGain = 1,
    this.gGain = 1,
    this.bGain = 1,
    this.brightness = 0,
    this.contrast = 1,
    this.saturation = 1,
    this.sharpness = 0,
  });

  factory ColorAdjustSpec.fromMap(Map<Object?, Object?> map) => ColorAdjustSpec(
    rGain: (map['rGain'] as num?)?.toDouble() ?? 1,
    gGain: (map['gGain'] as num?)?.toDouble() ?? 1,
    bGain: (map['bGain'] as num?)?.toDouble() ?? 1,
    brightness: (map['brightness'] as num?)?.toDouble() ?? 0,
    contrast: (map['contrast'] as num?)?.toDouble() ?? 1,
    saturation: (map['saturation'] as num?)?.toDouble() ?? 1,
    sharpness: (map['sharpness'] as num?)?.toDouble() ?? 0,
  );

  /// Per-channel multipliers (1 = unchanged) encoding exposure + warmth + tint.
  final double rGain;
  final double gGain;
  final double bGain;

  /// Additive brightness in [-1, 1] (0 = unchanged).
  final double brightness;

  /// Contrast multiplier around mid-grey (1 = unchanged).
  final double contrast;

  /// Saturation multiplier (1 = unchanged, 0 = greyscale).
  final double saturation;

  /// Luminance sharpening amount in [0, 1] (0 = none).
  final double sharpness;

  /// A grade that changes nothing — callers can skip the extra pass entirely.
  bool get isIdentity =>
      rGain == 1 &&
      gGain == 1 &&
      bGain == 1 &&
      brightness == 0 &&
      contrast == 1 &&
      saturation == 1 &&
      sharpness == 0;

  Map<String, Object?> toMap() => {
    'rGain': rGain,
    'gGain': gGain,
    'bGain': bGain,
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'sharpness': sharpness,
  };

  @override
  List<Object?> get props => [
    rGain,
    gGain,
    bGain,
    brightness,
    contrast,
    saturation,
    sharpness,
  ];
}

enum ExportStage {
  preparingImage,
  generatingVideo,
  mergingAudio,
  savingVideo,
  done,
}

class ExportProgress extends Equatable {
  const ExportProgress({required this.stage, this.percentage, this.message});

  factory ExportProgress.fromMap(Map<Object?, Object?> map) {
    final stageName =
        map['stage'] as String? ?? ExportStage.generatingVideo.name;
    return ExportProgress(
      stage: ExportStage.values.firstWhere(
        (stage) => stage.name == stageName,
        orElse: () => ExportStage.generatingVideo,
      ),
      percentage: (map['percentage'] as num?)?.toDouble(),
      message: map['message'] as String?,
    );
  }

  final ExportStage stage;
  final double? percentage;
  final String? message;

  @override
  List<Object?> get props => [stage, percentage, message];
}

class ExportResult extends Equatable {
  const ExportResult({
    required this.outputPath,
    required this.width,
    required this.height,
    required this.durationSeconds,
  });

  factory ExportResult.fromMap(Map<Object?, Object?> map) {
    return ExportResult(
      outputPath: map['outputPath'] as String,
      width: map['width'] as int,
      height: map['height'] as int,
      durationSeconds: map['durationSeconds'] as int,
    );
  }

  final String outputPath;
  final int width;
  final int height;
  final int durationSeconds;

  @override
  List<Object?> get props => [outputPath, width, height, durationSeconds];
}
