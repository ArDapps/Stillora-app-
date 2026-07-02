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
/// is shown.
class WatermarkLayerSpec extends Equatable {
  const WatermarkLayerSpec({
    required this.path,
    required this.isImage,
    required this.x,
    required this.y,
    required this.scale,
    required this.start,
    required this.end,
  });

  final String path;
  final bool isImage;
  final double x;
  final double y;
  final double scale;
  final double start;
  final double end;

  Map<String, Object?> toMap() => {
    'path': path,
    'isImage': isImage,
    'x': x,
    'y': y,
    'scale': scale,
    'start': start,
    'end': end,
  };

  @override
  List<Object?> get props => [path, isImage, x, y, scale, start, end];
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
