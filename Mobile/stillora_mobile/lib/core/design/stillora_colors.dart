import 'package:flutter/material.dart';

/// Single source of truth for Stillora's colour language: a deep violet-black
/// dark theme with a magenta → violet → cyan brand accent. Every surface in the
/// app should reference these tokens — no raw `Color(0x..)` literals in screens.
///
/// The surface ladder is intentionally tinted toward violet (not neutral grey)
/// so panels feel part of the same glassy world as the brand glow.
class StilloraColors {
  const StilloraColors._();

  // ---------------------------------------------------------------------------
  // Brand accent — the interactive violet + cyan that defines Stillora.
  // ---------------------------------------------------------------------------
  /// Primary interactive accent (buttons, selection, focus). Violet.
  static const accent = Color(0xff8b5cf6);
  /// Readable accent tint for text/icons on dark surfaces.
  static const accentText = Color(0xffd8c9ff);
  /// Magenta and cyan brand-gradient stops, exposed for ambient glows.
  static const brandMagenta = Color(0xffd946ef);
  static const brandViolet = Color(0xff8b5cf6);
  static const brandCyan = Color(0xff22d3ee);

  // ---------------------------------------------------------------------------
  // Material colour-scheme roles.
  // ---------------------------------------------------------------------------
  static const primary = Color(0xffeaddff);
  static const onPrimary = Color(0xff2a1747);
  static const primaryContainer = Color(0xff8b5cf6);
  static const onPrimaryContainer = Color(0xffece6ff);
  static const primaryFixed = Color(0xffeaddff);
  static const primaryFixedDim = Color(0xffd2bbff);
  static const onPrimaryFixed = Color(0xff200a45);
  static const onPrimaryFixedVariant = Color(0xff4f3c76);

  static const secondary = Color(0xff67e8f9);
  static const onSecondary = Color(0xff00363d);
  static const secondaryContainer = Color(0xff0e7490);
  static const onSecondaryContainer = Color(0xffa5f3fc);
  static const secondaryFixed = Color(0xffcffafe);
  static const secondaryFixedDim = Color(0xff67e8f9);
  static const onSecondaryFixed = Color(0xff00272d);
  static const onSecondaryFixedVariant = Color(0xff00505b);

  static const tertiary = Color(0xffe2dfff);
  static const onTertiary = Color(0xff2c2a5e);
  static const tertiaryContainer = Color(0xffc3c0ff);
  static const onTertiaryContainer = Color(0xff4e4c83);
  static const tertiaryFixed = Color(0xffe3dfff);
  static const tertiaryFixedDim = Color(0xffc3c0ff);
  static const onTertiaryFixed = Color(0xff161349);
  static const onTertiaryFixedVariant = Color(0xff434176);

  static const error = Color(0xffffb4ab);
  static const onError = Color(0xff690005);
  static const errorContainer = Color(0xff93000a);
  static const onErrorContainer = Color(0xffffdad6);

  // ---------------------------------------------------------------------------
  // Surfaces — violet-tinted dark ladder (lowest = deepest).
  // ---------------------------------------------------------------------------
  static const surface = Color(0xff07060f);
  static const onSurface = Color(0xffe9e6f2);
  static const onSurfaceVariant = Color(0xffb6b0c8);
  static const surfaceDim = Color(0xff070611);
  static const surfaceBright = Color(0xff241f38);
  static const surfaceVariant = Color(0xff2a2640);

  static const surfaceContainerLowest = Color(0xff050410);
  static const surfaceContainerLow = Color(0xff0f0d1a);
  static const surfaceContainer = Color(0xff14111f);
  static const surfaceContainerHigh = Color(0xff1b1730);
  static const surfaceContainerHighest = Color(0xff231e3c);

  /// Flat dark panel used by the render/step-card flows (Create, HTML, Loop).
  static const panel = Color(0xff101019);
  static const panelBorder = Color(0x14ffffff);

  static const background = Color(0xff0a0813);
  static const onBackground = Color(0xffe9e6f2);

  static const outline = Color(0xff7c7596);
  static const outlineVariant = Color(0xff39354c);

  static const surfaceTint = Color(0xff8b5cf6);
  static const inverseSurface = Color(0xffe9e6f2);
  static const inverseOnSurface = Color(0xff2a2640);
  static const inversePrimary = Color(0xff6b4fa6);

  // ---------------------------------------------------------------------------
  // Glass / glow / overlay helpers.
  // ---------------------------------------------------------------------------
  /// Hairline stroke for glass cards and dividers.
  static const glassStroke = Color(0x2effffff);
  /// Soft violet halo behind glowing controls.
  static const primaryGlow = Color(0x4d8b5cf6);
  /// Dim scrim for pause states / image overlays.
  static const overlay = Color(0x8c05040d);
  /// Heavier scrim for full-bleed media chrome.
  static const scrim = Color(0xb3030208);
}

/// App-wide vertical backdrop gradient (deep violet-black). Used behind every
/// full-screen flow so the app reads as one continuous surface.
const stilloraBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xff0c0718), Color(0xff060611), Color(0xff030309)],
  stops: [0.0, 0.55, 1.0],
);
