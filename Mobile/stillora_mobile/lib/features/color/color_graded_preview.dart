import 'package:flutter/material.dart';

import 'color_adjust.dart';

/// Wraps [child] in the live colour grade so users see what will be rendered
/// before they export. The grade is applied with the same derived maths the
/// export engines bake in ([ColorAdjust.colorFilterMatrix]), so the preview
/// tracks the final file closely (sharpening aside — see [ColorAdjust]).
///
/// Put a still frame, an image, or a running [VideoPlayer] inside it; the grade
/// updates instantly as the sliders move.
class ColorGradedPreview extends StatelessWidget {
  const ColorGradedPreview({
    super.key,
    required this.adjust,
    required this.child,
  });

  final ColorAdjust adjust;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (adjust.isIdentity) return child;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(adjust.colorFilterMatrix()),
      child: child,
    );
  }
}
