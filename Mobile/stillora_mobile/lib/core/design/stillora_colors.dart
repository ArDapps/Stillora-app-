import 'package:flutter/material.dart';

/// Single source of truth for Stillora's colour language: a magenta → violet →
/// cyan brand accent laid over a violet-tinted surface ladder. Every surface in
/// the app should reference these tokens — no raw `Color(0x..)` literals in
/// screens.
///
/// The app ships two palettes — [StilloraPalette.dark] (the original deep
/// violet-black world) and [StilloraPalette.light] (the same brand on a
/// violet-tinted paper ladder). Screens never pick one: they read
/// [StilloraColors], which forwards to whichever palette is currently active.
/// `StilloraPaletteScope` (see `app/theme.dart`) keeps that active palette in
/// sync with the `MaterialApp` brightness.
///
/// The surface ladder is intentionally tinted toward violet (not neutral grey)
/// in both palettes, so panels feel part of the same glassy world as the brand
/// glow.
@immutable
class StilloraPalette {
  const StilloraPalette({
    required this.brightness,
    required this.accent,
    required this.accentText,
    required this.brandMagenta,
    required this.brandViolet,
    required this.brandCyan,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixed,
    required this.onPrimaryFixedVariant,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.secondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixed,
    required this.onSecondaryFixedVariant,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.tertiaryFixed,
    required this.tertiaryFixedDim,
    required this.onTertiaryFixed,
    required this.onTertiaryFixedVariant,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceVariant,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.panel,
    required this.panelBorder,
    required this.background,
    required this.onBackground,
    required this.outline,
    required this.outlineVariant,
    required this.surfaceTint,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inversePrimary,
    required this.onAccent,
    required this.glassStroke,
    required this.primaryGlow,
    required this.overlay,
    required this.scrim,
    required this.backgroundGradient,
    required this.shellGradient,
  });

  /// Which `MaterialApp` brightness this palette belongs to.
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  // Brand accent — the interactive violet + cyan that defines Stillora.
  final Color accent;
  final Color accentText;
  final Color brandMagenta;
  final Color brandViolet;
  final Color brandCyan;

  // Material colour-scheme roles.
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color primaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixed;
  final Color onPrimaryFixedVariant;

  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color secondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixed;
  final Color onSecondaryFixedVariant;

  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color tertiaryFixed;
  final Color tertiaryFixedDim;
  final Color onTertiaryFixed;
  final Color onTertiaryFixedVariant;

  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;

  // Surfaces — violet-tinted ladder (lowest = furthest from the reader).
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceVariant;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

  /// Flat panel used by the render/step-card flows (Create, HTML, Loop).
  final Color panel;
  final Color panelBorder;

  final Color background;
  final Color onBackground;

  final Color outline;
  final Color outlineVariant;

  final Color surfaceTint;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color inversePrimary;

  /// Foreground for anything painted *on* the brand [accent] fill — a selected
  /// pill chip, an accent-filled button. White in both palettes: the accent is
  /// a saturated violet in each, so a palette-tinted foreground would sink into
  /// it (the light accent and the old tinted value were the same #6d28d9, which
  /// made selected chip labels invisible).
  final Color onAccent;

  // Glass / glow / overlay helpers.
  /// Hairline stroke for glass cards and dividers. Light-on-dark in the dark
  /// palette, dark-on-light in the light one.
  final Color glassStroke;

  /// Soft violet halo behind glowing controls.
  final Color primaryGlow;

  /// Dim scrim for pause states / image overlays. Stays dark in both palettes —
  /// it always sits on top of user media, never on a themed surface.
  final Color overlay;

  /// Heavier scrim for full-bleed media chrome. Dark in both palettes, same
  /// reason as [overlay].
  final Color scrim;

  /// App-wide vertical backdrop gradient, used behind every full-screen flow so
  /// the app reads as one continuous surface.
  final LinearGradient backgroundGradient;

  /// Diagonal backdrop behind the desktop sidebar + workspace chrome.
  final LinearGradient shellGradient;

  // ---------------------------------------------------------------------------
  // Dark — the original deep violet-black world.
  // ---------------------------------------------------------------------------
  static const dark = StilloraPalette(
    brightness: Brightness.dark,

    accent: Color(0xff8b5cf6),
    accentText: Color(0xffd8c9ff),
    brandMagenta: Color(0xffd946ef),
    brandViolet: Color(0xff8b5cf6),
    brandCyan: Color(0xff22d3ee),

    primary: Color(0xffeaddff),
    onPrimary: Color(0xff2a1747),
    primaryContainer: Color(0xff8b5cf6),
    onPrimaryContainer: Color(0xffece6ff),
    primaryFixed: Color(0xffeaddff),
    primaryFixedDim: Color(0xffd2bbff),
    onPrimaryFixed: Color(0xff200a45),
    onPrimaryFixedVariant: Color(0xff4f3c76),

    secondary: Color(0xff67e8f9),
    onSecondary: Color(0xff00363d),
    secondaryContainer: Color(0xff0e7490),
    onSecondaryContainer: Color(0xffa5f3fc),
    secondaryFixed: Color(0xffcffafe),
    secondaryFixedDim: Color(0xff67e8f9),
    onSecondaryFixed: Color(0xff00272d),
    onSecondaryFixedVariant: Color(0xff00505b),

    tertiary: Color(0xffe2dfff),
    onTertiary: Color(0xff2c2a5e),
    tertiaryContainer: Color(0xffc3c0ff),
    onTertiaryContainer: Color(0xff4e4c83),
    tertiaryFixed: Color(0xffe3dfff),
    tertiaryFixedDim: Color(0xffc3c0ff),
    onTertiaryFixed: Color(0xff161349),
    onTertiaryFixedVariant: Color(0xff434176),

    error: Color(0xffffb4ab),
    onError: Color(0xff690005),
    errorContainer: Color(0xff93000a),
    onErrorContainer: Color(0xffffdad6),

    surface: Color(0xff07060f),
    onSurface: Color(0xffe9e6f2),
    onSurfaceVariant: Color(0xffb6b0c8),
    surfaceDim: Color(0xff070611),
    surfaceBright: Color(0xff241f38),
    surfaceVariant: Color(0xff2a2640),

    surfaceContainerLowest: Color(0xff050410),
    surfaceContainerLow: Color(0xff0f0d1a),
    surfaceContainer: Color(0xff14111f),
    surfaceContainerHigh: Color(0xff1b1730),
    surfaceContainerHighest: Color(0xff231e3c),

    panel: Color(0xff101019),
    panelBorder: Color(0x14ffffff),

    background: Color(0xff0a0813),
    onBackground: Color(0xffe9e6f2),

    outline: Color(0xff7c7596),
    outlineVariant: Color(0xff39354c),

    surfaceTint: Color(0xff8b5cf6),
    inverseSurface: Color(0xffe9e6f2),
    inverseOnSurface: Color(0xff2a2640),
    inversePrimary: Color(0xff6b4fa6),

    onAccent: Color(0xffffffff),
    glassStroke: Color(0x2effffff),
    primaryGlow: Color(0x4d8b5cf6),
    overlay: Color(0x8c05040d),
    scrim: Color(0xb3030208),

    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xff0c0718), Color(0xff060611), Color(0xff030309)],
      stops: [0.0, 0.55, 1.0],
    ),
    shellGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xff0d0820), Color(0xff070611), Color(0xff030309)],
    ),
  );

  // ---------------------------------------------------------------------------
  // Light — the same brand on a violet-tinted paper ladder. The ladder runs the
  // other way (lowest = brightest/whitest) so "raised" panels stay lighter than
  // the page behind them, mirroring how the dark ladder works.
  // ---------------------------------------------------------------------------
  static const light = StilloraPalette(
    brightness: Brightness.light,

    // Deeper violet than the dark palette's accent: #8b5cf6 on white only
    // reaches ~3.6:1, while #6d28d9 clears 4.5:1 for icons and small text.
    accent: Color(0xff6d28d9),
    accentText: Color(0xff5b21b6),
    brandMagenta: Color(0xffd946ef),
    brandViolet: Color(0xff8b5cf6),
    brandCyan: Color(0xff22d3ee),

    // Filled buttons flip: a solid violet fill with white text.
    primary: Color(0xff6d28d9),
    onPrimary: Color(0xffffffff),
    primaryContainer: Color(0xffe9ddff),
    onPrimaryContainer: Color(0xff2a1060),
    primaryFixed: Color(0xffeaddff),
    primaryFixedDim: Color(0xffd2bbff),
    onPrimaryFixed: Color(0xff200a45),
    onPrimaryFixedVariant: Color(0xff4f3c76),

    // Cyan has to darken hard to stay legible on paper.
    secondary: Color(0xff0e7490),
    onSecondary: Color(0xffffffff),
    secondaryContainer: Color(0xffcffafe),
    onSecondaryContainer: Color(0xff00363d),
    secondaryFixed: Color(0xffcffafe),
    secondaryFixedDim: Color(0xff67e8f9),
    onSecondaryFixed: Color(0xff00272d),
    onSecondaryFixedVariant: Color(0xff00505b),

    tertiary: Color(0xff4e4c83),
    onTertiary: Color(0xffffffff),
    tertiaryContainer: Color(0xffe2dfff),
    onTertiaryContainer: Color(0xff171441),
    tertiaryFixed: Color(0xffe3dfff),
    tertiaryFixedDim: Color(0xffc3c0ff),
    onTertiaryFixed: Color(0xff161349),
    onTertiaryFixedVariant: Color(0xff434176),

    error: Color(0xffb3261e),
    onError: Color(0xffffffff),
    errorContainer: Color(0xfff9dedc),
    onErrorContainer: Color(0xff410e0b),

    surface: Color(0xfffaf8ff),
    onSurface: Color(0xff17122b),
    onSurfaceVariant: Color(0xff544d6b),
    surfaceDim: Color(0xfff1ecfb),
    surfaceBright: Color(0xffffffff),
    surfaceVariant: Color(0xffe7e0f4),

    surfaceContainerLowest: Color(0xffffffff),
    surfaceContainerLow: Color(0xfff8f5ff),
    surfaceContainer: Color(0xfff3effc),
    surfaceContainerHigh: Color(0xffece5f8),
    surfaceContainerHighest: Color(0xffe4dbf3),

    panel: Color(0xfff6f3fd),
    panelBorder: Color(0x1417122b),

    background: Color(0xfff8f5ff),
    onBackground: Color(0xff17122b),

    outline: Color(0xff746c8d),
    outlineVariant: Color(0xffd8d1e8),

    surfaceTint: Color(0xff8b5cf6),
    inverseSurface: Color(0xff2f2a44),
    inverseOnSurface: Color(0xfff4f0fb),
    inversePrimary: Color(0xffd2bbff),

    onAccent: Color(0xffffffff),
    // Dark hairline instead of a white one — a white stroke is invisible here.
    glassStroke: Color(0x2117122b),
    primaryGlow: Color(0x3d8b5cf6),
    // Media scrims stay dark: they always sit on user photos/video, never on a
    // themed surface, and their captions are white in both palettes.
    overlay: Color(0x8c05040d),
    scrim: Color(0xb3030208),

    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xfffdfbff), Color(0xfff5f1fe), Color(0xffece6f9)],
      stops: [0.0, 0.55, 1.0],
    ),
    shellGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xfffdfaff), Color(0xfff4f0fd), Color(0xffe9e3f7)],
    ),
  );

  static StilloraPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Ambient accessor for the active palette. Screens read `StilloraColors.x`
/// exactly as before; the values now follow the app's light/dark mode.
///
/// The active palette is swapped by `StilloraPaletteScope`, which also forces a
/// rebuild of the widget tree so every screen re-reads these getters. Because
/// these are getters (not `const`), they cannot be used inside `const`
/// expressions — use a non-const constructor at those few call sites.
class StilloraColors {
  const StilloraColors._();

  static StilloraPalette _active = StilloraPalette.dark;

  /// The palette currently painting the app.
  static StilloraPalette get active => _active;

  /// Swaps the active palette. Returns true when the value actually changed, so
  /// the caller can skip a needless tree rebuild.
  static bool activate(StilloraPalette palette) {
    if (identical(_active, palette)) return false;
    _active = palette;
    return true;
  }

  static Color get accent => _active.accent;
  static Color get accentText => _active.accentText;
  static Color get brandMagenta => _active.brandMagenta;
  static Color get brandViolet => _active.brandViolet;
  static Color get brandCyan => _active.brandCyan;

  static Color get primary => _active.primary;
  static Color get onPrimary => _active.onPrimary;
  static Color get primaryContainer => _active.primaryContainer;
  static Color get onPrimaryContainer => _active.onPrimaryContainer;
  static Color get primaryFixed => _active.primaryFixed;
  static Color get primaryFixedDim => _active.primaryFixedDim;
  static Color get onPrimaryFixed => _active.onPrimaryFixed;
  static Color get onPrimaryFixedVariant => _active.onPrimaryFixedVariant;

  static Color get secondary => _active.secondary;
  static Color get onSecondary => _active.onSecondary;
  static Color get secondaryContainer => _active.secondaryContainer;
  static Color get onSecondaryContainer => _active.onSecondaryContainer;
  static Color get secondaryFixed => _active.secondaryFixed;
  static Color get secondaryFixedDim => _active.secondaryFixedDim;
  static Color get onSecondaryFixed => _active.onSecondaryFixed;
  static Color get onSecondaryFixedVariant => _active.onSecondaryFixedVariant;

  static Color get tertiary => _active.tertiary;
  static Color get onTertiary => _active.onTertiary;
  static Color get tertiaryContainer => _active.tertiaryContainer;
  static Color get onTertiaryContainer => _active.onTertiaryContainer;
  static Color get tertiaryFixed => _active.tertiaryFixed;
  static Color get tertiaryFixedDim => _active.tertiaryFixedDim;
  static Color get onTertiaryFixed => _active.onTertiaryFixed;
  static Color get onTertiaryFixedVariant => _active.onTertiaryFixedVariant;

  static Color get error => _active.error;
  static Color get onError => _active.onError;
  static Color get errorContainer => _active.errorContainer;
  static Color get onErrorContainer => _active.onErrorContainer;

  static Color get surface => _active.surface;
  static Color get onSurface => _active.onSurface;
  static Color get onSurfaceVariant => _active.onSurfaceVariant;
  static Color get surfaceDim => _active.surfaceDim;
  static Color get surfaceBright => _active.surfaceBright;
  static Color get surfaceVariant => _active.surfaceVariant;

  static Color get surfaceContainerLowest => _active.surfaceContainerLowest;
  static Color get surfaceContainerLow => _active.surfaceContainerLow;
  static Color get surfaceContainer => _active.surfaceContainer;
  static Color get surfaceContainerHigh => _active.surfaceContainerHigh;
  static Color get surfaceContainerHighest => _active.surfaceContainerHighest;

  static Color get panel => _active.panel;
  static Color get panelBorder => _active.panelBorder;

  static Color get background => _active.background;
  static Color get onBackground => _active.onBackground;

  static Color get outline => _active.outline;
  static Color get outlineVariant => _active.outlineVariant;

  static Color get surfaceTint => _active.surfaceTint;
  static Color get inverseSurface => _active.inverseSurface;
  static Color get inverseOnSurface => _active.inverseOnSurface;
  static Color get inversePrimary => _active.inversePrimary;

  static Color get onAccent => _active.onAccent;
  static Color get glassStroke => _active.glassStroke;
  static Color get primaryGlow => _active.primaryGlow;
  static Color get overlay => _active.overlay;
  static Color get scrim => _active.scrim;

  static LinearGradient get shellGradient => _active.shellGradient;
}

/// App-wide vertical backdrop gradient for the active palette.
LinearGradient get stilloraBackgroundGradient =>
    StilloraColors.active.backgroundGradient;
