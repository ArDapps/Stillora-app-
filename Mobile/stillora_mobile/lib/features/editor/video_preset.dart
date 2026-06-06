import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VideoPreset extends Equatable {
  const VideoPreset({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
    required this.ratioLabel,
    required this.icon,
    this.usesOriginalSize = false,
  });

  final String id;
  final String label;
  final int width;
  final int height;
  final String ratioLabel;

  /// Platform/format glyph shown on the preset card.
  final IconData icon;
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
    icon: FontAwesomeIcons.instagram,
  ),
  VideoPreset(
    id: 'tiktok',
    label: 'TikTok',
    width: 1080,
    height: 1920,
    ratioLabel: '9:16',
    icon: FontAwesomeIcons.tiktok,
  ),
  VideoPreset(
    id: 'stories',
    label: 'Stories',
    width: 1080,
    height: 1920,
    ratioLabel: '9:16',
    icon: FontAwesomeIcons.facebook,
  ),
  VideoPreset(
    id: 'shorts',
    label: 'YouTube Shorts',
    width: 1080,
    height: 1920,
    ratioLabel: '9:16',
    icon: FontAwesomeIcons.youtube,
  ),
  VideoPreset(
    id: 'square',
    label: 'Square Post',
    width: 1080,
    height: 1080,
    ratioLabel: '1:1',
    icon: FontAwesomeIcons.squareInstagram,
  ),
  VideoPreset(
    id: 'portrait',
    label: 'Portrait Post',
    width: 1080,
    height: 1350,
    ratioLabel: '4:5',
    icon: FontAwesomeIcons.instagram,
  ),
  VideoPreset(
    id: 'landscape',
    label: 'YouTube Landscape',
    width: 1920,
    height: 1080,
    ratioLabel: '16:9',
    icon: FontAwesomeIcons.youtube,
  ),
  VideoPreset(
    id: 'original',
    label: 'Original Size',
    width: 0,
    height: 0,
    ratioLabel: 'Original',
    icon: FontAwesomeIcons.image,
    usesOriginalSize: true,
  ),
];

const defaultVideoPreset = VideoPreset(
  id: 'reels',
  label: 'Reels',
  width: 1080,
  height: 1920,
  ratioLabel: '9:16',
  icon: FontAwesomeIcons.instagram,
);

VideoPreset presetById(String id) {
  return videoPresets.firstWhere(
    (preset) => preset.id == id,
    orElse: () => videoPresets.first,
  );
}
