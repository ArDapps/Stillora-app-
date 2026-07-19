import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Font-size range as a fraction of the frame height (responsive across export
/// resolutions). 0.03 ≈ a caption, 0.16 ≈ a big title.
const minFontScale = 0.02;
const maxFontScale = 0.30;
const defaultFontScale = 0.09;

/// The curated font families offered in the picker. `null` = the platform's
/// default UI font. The preview and the export PNG both render through Flutter's
/// text engine with the same family, so the export always matches the preview
/// even when a family falls back.
const kTextFontFamilies = <(String label, String? family)>[
  ('Default', null),
  ('Sans', 'Helvetica'),
  ('Serif', 'Georgia'),
  ('Slab', 'Times New Roman'),
  ('Mono', 'Courier'),
];

/// Quick-start style presets (bonus): each seeds a new layer's look.
enum TextPreset { title, subtitle, caption, cta }

extension TextPresetX on TextPreset {
  String get label => switch (this) {
    TextPreset.title => 'Title',
    TextPreset.subtitle => 'Subtitle',
    TextPreset.caption => 'Caption',
    TextPreset.cta => 'CTA',
  };

  /// The default text shown when the preset seeds a fresh layer.
  String get seedText => switch (this) {
    TextPreset.title => 'Your Title',
    TextPreset.subtitle => 'Your subtitle here',
    TextPreset.caption => 'caption text',
    TextPreset.cta => 'Tap to learn more',
  };
}

/// One text overlay laid over the base video. [x]/[y] are the layer's normalised
/// **centre** (0..1) so dragging feels natural and the position survives an
/// export resolution change. [fontScale] is the font size as a fraction of the
/// frame height (responsive). [start]/[end] bound when it's visible and
/// [fadeIn]/[fadeOut] dissolve it in/out.
class TextLayer extends Equatable {
  const TextLayer({
    required this.id,
    this.text = 'Your text',
    this.x = 0.5,
    this.y = 0.5,
    this.fontScale = defaultFontScale,
    this.fontFamily,
    this.fontWeight = FontWeight.w700,
    this.color = Colors.white,
    this.backgroundColor,
    this.strokeWidth = 0,
    this.strokeColor = Colors.black,
    this.shadow = false,
    this.align = TextAlign.center,
    this.opacity = 1,
    this.start = 0,
    this.end = 0,
    this.fadeIn = 0.4,
    this.fadeOut = 0.4,
  });

  final String id;
  final String text;
  final double x;
  final double y;
  final double fontScale;
  final String? fontFamily;
  final FontWeight fontWeight;
  final Color color;

  /// Optional filled box behind the text (null = transparent).
  final Color? backgroundColor;

  /// Optional outline. 0 = no stroke.
  final double strokeWidth;
  final Color strokeColor;

  /// Optional soft drop shadow behind the text.
  final bool shadow;

  final TextAlign align;

  /// Constant layer opacity 0..1 (baked into the export); separate from the
  /// time-based [fadeIn]/[fadeOut] ramps.
  final double opacity;

  /// Visible window inside the base video, in seconds.
  final double start;
  final double end;

  /// Fade ramp lengths, in seconds (0 = a hard cut).
  final double fadeIn;
  final double fadeOut;

  TextLayer copyWith({
    String? text,
    double? x,
    double? y,
    double? fontScale,
    Object? fontFamily = _noChange,
    FontWeight? fontWeight,
    Color? color,
    Object? backgroundColor = _noChange,
    double? strokeWidth,
    Color? strokeColor,
    bool? shadow,
    TextAlign? align,
    double? opacity,
    double? start,
    double? end,
    double? fadeIn,
    double? fadeOut,
  }) => TextLayer(
    id: id,
    text: text ?? this.text,
    x: (x ?? this.x).clamp(0.0, 1.0),
    y: (y ?? this.y).clamp(0.0, 1.0),
    fontScale: (fontScale ?? this.fontScale).clamp(minFontScale, maxFontScale),
    fontFamily: fontFamily == _noChange
        ? this.fontFamily
        : fontFamily as String?,
    fontWeight: fontWeight ?? this.fontWeight,
    color: color ?? this.color,
    backgroundColor: backgroundColor == _noChange
        ? this.backgroundColor
        : backgroundColor as Color?,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    strokeColor: strokeColor ?? this.strokeColor,
    shadow: shadow ?? this.shadow,
    align: align ?? this.align,
    opacity: (opacity ?? this.opacity).clamp(0.0, 1.0),
    start: start ?? this.start,
    end: end ?? this.end,
    fadeIn: fadeIn ?? this.fadeIn,
    fadeOut: fadeOut ?? this.fadeOut,
  );

  bool isVisibleAt(double seconds) => seconds >= start && seconds < end;

  /// The layer's opacity at playback position [seconds], folding the constant
  /// [opacity] with the fade ramps. Used to make the preview match the export.
  double opacityAt(double seconds) {
    if (seconds < start || seconds >= end) return 0;
    final span = end - start;
    final fi = fadeIn.clamp(0.0, span / 2);
    final fo = fadeOut.clamp(0.0, span / 2);
    var a = 1.0;
    if (fi > 0 && seconds < start + fi) a = (seconds - start) / fi;
    if (fo > 0 && seconds > end - fo) {
      a = a < (end - seconds) / fo ? a : (end - seconds) / fo;
    }
    return (a.clamp(0.0, 1.0)) * opacity;
  }

  @override
  List<Object?> get props => [
    id,
    text,
    x,
    y,
    fontScale,
    fontFamily,
    fontWeight,
    color,
    backgroundColor,
    strokeWidth,
    strokeColor,
    shadow,
    align,
    opacity,
    start,
    end,
    fadeIn,
    fadeOut,
  ];
}

const _noChange = Object();
