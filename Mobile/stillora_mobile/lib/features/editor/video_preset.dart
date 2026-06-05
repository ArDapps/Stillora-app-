import 'package:equatable/equatable.dart';

class VideoPreset extends Equatable {
  const VideoPreset({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
    required this.ratioLabel,
    this.usesOriginalSize = false,
  });

  final String id;
  final String label;
  final int width;
  final int height;
  final String ratioLabel;
  final bool usesOriginalSize;

  @override
  List<Object?> get props => [
    id,
    label,
    width,
    height,
    ratioLabel,
    usesOriginalSize,
  ];
}

const videoPresets = [
  VideoPreset(
    id: 'reels',
    label: 'Reels',
    width: 1080,
    height: 1920,
    ratioLabel: '9:16',
  ),
  VideoPreset(
    id: 'tiktok',
    label: 'TikTok',
    width: 1080,
    height: 1920,
    ratioLabel: '9:16',
  ),
  VideoPreset(
    id: 'stories',
    label: 'Stories',
    width: 1080,
    height: 1920,
    ratioLabel: '9:16',
  ),
  VideoPreset(
    id: 'shorts',
    label: 'YouTube Shorts',
    width: 1080,
    height: 1920,
    ratioLabel: '9:16',
  ),
  VideoPreset(
    id: 'square',
    label: 'Square Post',
    width: 1080,
    height: 1080,
    ratioLabel: '1:1',
  ),
  VideoPreset(
    id: 'landscape',
    label: 'YouTube Landscape',
    width: 1920,
    height: 1080,
    ratioLabel: '16:9',
  ),
  VideoPreset(
    id: 'original',
    label: 'Original Size',
    width: 0,
    height: 0,
    ratioLabel: 'Original',
    usesOriginalSize: true,
  ),
];

const defaultVideoPreset = VideoPreset(
  id: 'reels',
  label: 'Reels',
  width: 1080,
  height: 1920,
  ratioLabel: '9:16',
);

VideoPreset presetById(String id) {
  return videoPresets.firstWhere(
    (preset) => preset.id == id,
    orElse: () => videoPresets.first,
  );
}
