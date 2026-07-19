import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

/// A user-facing colour grade: eight sliders, each normalised so `0` is neutral.
///
/// This is the single source of truth for the colour maths. It derives an
/// [engine.ColorAdjustSpec] (per-channel gains + brightness/contrast/saturation)
/// that the ffmpeg desktop pass and the macOS CoreImage pass both consume, and a
/// [colorFilterMatrix] the Flutter live preview applies — so the preview a user
/// sees matches what actually gets baked into the exported file.
///
/// The preview matrix is a close approximation: gains, brightness, contrast and
/// saturation map exactly; sharpening ([sharpness]) can't be expressed as a
/// colour matrix, so the preview omits it (a minor edge effect only).
class ColorAdjust extends Equatable {
  const ColorAdjust({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
    this.tint = 0,
    this.vibrance = 0,
    this.exposure = 0,
    this.sharpness = 0,
  });

  /// All in [-1, 1] except [sharpness] in [0, 1]. 0 = no change.
  final double brightness;
  final double contrast;
  final double saturation;

  /// Warm (>0, orange) ↔ cool (<0, blue).
  final double warmth;

  /// Magenta (>0) ↔ green (<0).
  final double tint;

  /// Gentle saturation weighted toward the less-saturated pixels.
  final double vibrance;

  /// Mid-tone gain (>0 brighter, <0 darker) — multiplicative, unlike brightness.
  final double exposure;

  /// Luminance sharpening amount.
  final double sharpness;

  static const identity = ColorAdjust();

  bool get isIdentity =>
      brightness == 0 &&
      contrast == 0 &&
      saturation == 0 &&
      warmth == 0 &&
      tint == 0 &&
      vibrance == 0 &&
      exposure == 0 &&
      sharpness == 0;

  ColorAdjust copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? tint,
    double? vibrance,
    double? exposure,
    double? sharpness,
  }) => ColorAdjust(
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    saturation: saturation ?? this.saturation,
    warmth: warmth ?? this.warmth,
    tint: tint ?? this.tint,
    vibrance: vibrance ?? this.vibrance,
    exposure: exposure ?? this.exposure,
    sharpness: sharpness ?? this.sharpness,
  );

  // --- Derived, engine-ready values (one place, used by every backend) -------

  /// Exposure as a multiplicative RGB gain (1 = unchanged).
  double get _exposureGain => 1 + exposure * 0.6;

  double get _rGain {
    final warm = 1 + 0.25 * warmth; // warmth lifts red
    final magenta = 1 + 0.075 * tint; // magenta nudges red up
    return _exposureGain * warm * magenta;
  }

  double get _gGain {
    final green = 1 - 0.15 * tint; // magenta pulls green down (green pushes up)
    return _exposureGain * green;
  }

  double get _bGain {
    final cool = 1 - 0.25 * warmth; // warmth drops blue
    final magenta = 1 + 0.075 * tint; // magenta nudges blue up
    return _exposureGain * cool * magenta;
  }

  double get _ciBrightness => brightness * 0.4; // gentle additive, [-0.4, 0.4]
  double get _ciContrast => 1 + contrast; // [0, 2], 1 = neutral
  double get _ciSaturation => (1 + saturation + 0.5 * vibrance).clamp(0.0, 3.0);

  /// The derived grade the native/ffmpeg engines bake into the video.
  engine.ColorAdjustSpec toSpec() => engine.ColorAdjustSpec(
    rGain: _rGain,
    gGain: _gGain,
    bGain: _bGain,
    brightness: _ciBrightness,
    contrast: _ciContrast,
    saturation: _ciSaturation,
    sharpness: sharpness,
  );

  /// A 4×5 [ColorFilter.matrix] mirroring the derived grade for live preview.
  List<double> colorFilterMatrix() {
    // Compose (applied to the input vector in this order): gains → contrast →
    // brightness → saturation. Matrices are 5×5 homogeneous so offsets compose.
    final gains = _diag(_rGain, _gGain, _bGain);
    final contrast = _contrastMatrix(_ciContrast);
    final bright = _brightnessMatrix(_ciBrightness * 255.0);
    final sat = _saturationMatrix(_ciSaturation);
    final m = _mul(sat, _mul(bright, _mul(contrast, gains)));
    // First four rows, dropping the homogeneous bottom row → 20 values.
    return [
      for (var r = 0; r < 4; r++)
        for (var c = 0; c < 5; c++) m[r][c],
    ];
  }

  @override
  List<Object?> get props => [
    brightness,
    contrast,
    saturation,
    warmth,
    tint,
    vibrance,
    exposure,
    sharpness,
  ];
}

// --- 5×5 matrix helpers (homogeneous colour transforms) ----------------------

List<List<double>> _identityM() => [
  [1, 0, 0, 0, 0],
  [0, 1, 0, 0, 0],
  [0, 0, 1, 0, 0],
  [0, 0, 0, 1, 0],
  [0, 0, 0, 0, 1],
];

List<List<double>> _diag(double r, double g, double b) => [
  [r, 0, 0, 0, 0],
  [0, g, 0, 0, 0],
  [0, 0, b, 0, 0],
  [0, 0, 0, 1, 0],
  [0, 0, 0, 0, 1],
];

List<List<double>> _brightnessMatrix(double add) => [
  [1, 0, 0, 0, add],
  [0, 1, 0, 0, add],
  [0, 0, 1, 0, add],
  [0, 0, 0, 1, 0],
  [0, 0, 0, 0, 1],
];

List<List<double>> _contrastMatrix(double c) {
  final offset = 127.5 * (1 - c);
  return [
    [c, 0, 0, 0, offset],
    [0, c, 0, 0, offset],
    [0, 0, c, 0, offset],
    [0, 0, 0, 1, 0],
    [0, 0, 0, 0, 1],
  ];
}

List<List<double>> _saturationMatrix(double s) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  return [
    [lr + s * (1 - lr), lg - s * lg, lb - s * lb, 0, 0],
    [lr - s * lr, lg + s * (1 - lg), lb - s * lb, 0, 0],
    [lr - s * lr, lg - s * lg, lb + s * (1 - lb), 0, 0],
    [0, 0, 0, 1, 0],
    [0, 0, 0, 0, 1],
  ];
}

List<List<double>> _mul(List<List<double>> a, List<List<double>> b) {
  final out = _identityM();
  for (var i = 0; i < 5; i++) {
    for (var j = 0; j < 5; j++) {
      var sum = 0.0;
      for (var k = 0; k < 5; k++) {
        sum += a[i][k] * b[k][j];
      }
      out[i][j] = sum;
    }
  }
  return out;
}

// --- One-tap preset looks ----------------------------------------------------

/// A named starting look. Users pick one, then fine-tune the sliders.
class ColorPreset {
  const ColorPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.adjust,
  });

  final String id;
  final String label;
  final IconData icon;
  final ColorAdjust adjust;
}

const colorPresets = <ColorPreset>[
  ColorPreset(
    id: 'original',
    label: 'Original',
    icon: Icons.block_rounded,
    adjust: ColorAdjust.identity,
  ),
  ColorPreset(
    id: 'warm',
    label: 'Warm',
    icon: Icons.wb_sunny_rounded,
    adjust: ColorAdjust(warmth: 0.4, saturation: 0.1, contrast: 0.05),
  ),
  ColorPreset(
    id: 'cool',
    label: 'Cool',
    icon: Icons.ac_unit_rounded,
    adjust: ColorAdjust(warmth: -0.4, saturation: 0.05),
  ),
  ColorPreset(
    id: 'vivid',
    label: 'Vivid',
    icon: Icons.auto_awesome_rounded,
    adjust: ColorAdjust(saturation: 0.35, contrast: 0.2, vibrance: 0.3),
  ),
  ColorPreset(
    id: 'cinematic',
    label: 'Cinematic',
    icon: Icons.movie_creation_rounded,
    adjust: ColorAdjust(
      contrast: 0.25,
      saturation: -0.1,
      warmth: -0.15,
      tint: -0.1,
      exposure: -0.05,
    ),
  ),
  ColorPreset(
    id: 'bright',
    label: 'Bright',
    icon: Icons.brightness_high_rounded,
    adjust: ColorAdjust(exposure: 0.3, brightness: 0.12),
  ),
  ColorPreset(
    id: 'vintage',
    label: 'Vintage',
    icon: Icons.filter_vintage_rounded,
    adjust: ColorAdjust(
      saturation: -0.25,
      warmth: 0.3,
      contrast: -0.1,
      brightness: 0.05,
    ),
  ),
  ColorPreset(
    id: 'bw',
    label: 'B&W',
    icon: Icons.gradient_rounded,
    adjust: ColorAdjust(saturation: -1.0, contrast: 0.15),
  ),
];
