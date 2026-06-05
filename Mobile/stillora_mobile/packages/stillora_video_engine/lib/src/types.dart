import 'package:equatable/equatable.dart';

enum ResizeMode { fit, fill }

enum VideoEffect { none }

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
