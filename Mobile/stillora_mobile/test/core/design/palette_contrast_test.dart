import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/core/design/stillora_colors.dart';

/// WCAG relative luminance / contrast, so these assertions talk about what a
/// user can actually read rather than about hex equality. All the colours
/// checked here are fully opaque, so no compositing is needed.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Regression guard. The light palette once defined its "selected foreground"
  // as the very same #6d28d9 it used for `accent`, so every selected pill chip
  // — the 720p / 1080p / 2K / 4K export-quality picker most visibly — painted
  // violet text on a violet fill and the label simply disappeared.
  group('onAccent is readable on the accent fill', () {
    for (final (name, palette) in <(String, StilloraPalette)>[
      ('dark', StilloraPalette.dark),
      ('light', StilloraPalette.light),
    ]) {
      test('$name palette clears WCAG AA for bold text', () {
        expect(
          _contrast(palette.onAccent, palette.accent),
          greaterThanOrEqualTo(3.0),
          reason:
              '$name onAccent (${palette.onAccent}) is unreadable on accent '
              '(${palette.accent})',
        );
      });
    }
  });

  group('nav group headings stay legible on the surface behind them', () {
    // SidebarLabel (desktop) and the phone drawer's group heading both paint
    // accentText on surfaceDim.
    for (final (name, palette) in <(String, StilloraPalette)>[
      ('dark', StilloraPalette.dark),
      ('light', StilloraPalette.light),
    ]) {
      test('$name palette heading contrast', () {
        expect(
          _contrast(palette.accentText, palette.surfaceDim),
          greaterThanOrEqualTo(4.5),
          reason:
              '$name accentText (${palette.accentText}) is too faint on '
              'surfaceDim (${palette.surfaceDim})',
        );
      });
    }
  });
}
