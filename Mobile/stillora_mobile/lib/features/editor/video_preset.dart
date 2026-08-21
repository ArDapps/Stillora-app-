import 'package:equatable/equatable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/i18n/app_strings.dart';

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

  /// English fallback; [labelOf] returns the translated name.
  final String label;
  final int width;
  final int height;
  final String ratioLabel;

  /// Platform/format glyph shown on the preset card.
  final FaIconData icon;
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
    label: 'Reels / Shorts / TikTok',
    width: 1080,
    height: 1920,
    ratioLabel: '9:16',
    icon: FontAwesomeIcons.instagram,
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

extension VideoPresetMeta on VideoPreset {
  /// Translated preset name for the chips and summary rows.
  String labelOf(AppStrings s) => switch (id) {
    'reels' => s.vpReels,
    'square' => s.vpSquarePost,
    'portrait' => s.vpPortraitPost,
    'landscape' => s.vpYoutube,
    'original' => s.vpOriginalSize,
    _ => label,
  };

  /// Short form used where the full preset name would not fit.
  String shortLabelOf(AppStrings s) =>
      id == 'reels' ? s.vpReelsShort : labelOf(s);

  /// The aspect chip — a ratio like `9:16`, or the translated "Original".
  String ratioLabelOf(AppStrings s) =>
      usesOriginalSize ? s.colOriginal : ratioLabel;
}

VideoPreset presetById(String id) {
  return videoPresets.firstWhere(
    (preset) => preset.id == id,
    orElse: () => videoPresets.first,
  );
}

/// Output resolution tier applied on top of a preset's aspect ratio. The preset
/// defines the shape (e.g. 9:16); the quality scales the pixel size so users can
/// trade file size for sharpness — a lower tier means a much smaller file.
/// Presets are authored at 1080p, so [shortSide] is the target for the smaller
/// of the two dimensions.
enum ExportQuality {
  hd720('720p', 720),
  fhd1080('1080p', 1080),
  qhd1440('2K', 1440),
  uhd2160('4K', 2160);

  const ExportQuality(this.label, this.shortSide);

  /// A resolution tier name — the same in every language.
  final String label;

  String note(AppStrings s) => switch (this) {
    ExportQuality.hd720 => s.eqSmallestFile,
    ExportQuality.fhd1080 => s.eqRecommended,
    ExportQuality.qhd1440 => s.eqSharper,
    ExportQuality.uhd2160 => s.eqLargestFile,
  };

  /// Target pixel length of the shorter edge of the exported video.
  final int shortSide;
}

const defaultExportQuality = ExportQuality.fhd1080;

ExportQuality exportQualityByName(String name) {
  return ExportQuality.values.firstWhere(
    (q) => q.name == name,
    orElse: () => defaultExportQuality,
  );
}

/// Scales arbitrary base dimensions to the chosen [quality] (the shorter edge
/// becomes [ExportQuality.shortSide]), preserving aspect ratio and keeping both
/// dimensions even (H.264/HEVC encoders require even width/height). Shared by
/// every section that exports video (Create, Loop, HTML → Video).
({int width, int height}) scaleDimensionsToQuality(
  int baseWidth,
  int baseHeight,
  ExportQuality quality,
) {
  final w = baseWidth <= 0 ? 1080 : baseWidth;
  final h = baseHeight <= 0 ? 1080 : baseHeight;
  final baseShort = w < h ? w : h;
  final scale = quality.shortSide / baseShort;

  int even(num value) {
    final rounded = value.round();
    return rounded.isOdd ? rounded + 1 : rounded;
  }

  return (width: even(w * scale), height: even(h * scale));
}

/// Scales a [VideoPreset] to the chosen [quality].
({int width, int height}) scaledResolution(
  VideoPreset preset,
  ExportQuality quality,
) => scaleDimensionsToQuality(preset.width, preset.height, quality);
