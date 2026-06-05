import 'package:equatable/equatable.dart';

class LocalExportRecord extends Equatable {
  const LocalExportRecord({
    required this.id,
    required this.outputPath,
    required this.preset,
    required this.width,
    required this.height,
    required this.durationSeconds,
    required this.createdAt,
    this.thumbnailPath,
  });

  final String id;
  final String outputPath;
  final String? thumbnailPath;
  final String preset;
  final int width;
  final int height;
  final int durationSeconds;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'outputPath': outputPath,
    'thumbnailPath': thumbnailPath,
    'preset': preset,
    'width': width,
    'height': height,
    'durationSeconds': durationSeconds,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LocalExportRecord.fromJson(Map<String, dynamic> json) {
    return LocalExportRecord(
      id: json['id'] as String,
      outputPath: json['outputPath'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      preset: json['preset'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      durationSeconds: json['durationSeconds'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    outputPath,
    thumbnailPath,
    preset,
    width,
    height,
    durationSeconds,
    createdAt,
  ];
}
