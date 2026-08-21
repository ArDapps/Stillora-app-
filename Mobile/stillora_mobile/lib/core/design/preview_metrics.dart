import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How tall a live preview may get in the stacked (phone/tablet) layout.
///
/// In the split desktop layout the preview pane has a bounded height, so the
/// frame simply fits itself into it. Stacked, the preview sits inside a
/// scrolling column with no height limit: a 9:16 clip sized from the full
/// column width comes out ~1.8x as tall as it is wide, which on a phone fills
/// the screen and pushes every control below the fold — and on an iPad the
/// wider column makes it worse, not better.
///
/// So the preview gets a share of the viewport instead of a share of the
/// width: a glance-sized frame with the controls still visible underneath.
double mobilePreviewMaxHeight(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  // Tablets get a slightly taller ceiling — they have the vertical room, and
  // the preview would otherwise look lost in the middle of a wide column.
  final ceiling = size.shortestSide >= 600 ? 300.0 : 240.0;
  return math.min(size.height * 0.30, ceiling).clamp(140.0, ceiling);
}

/// The same budget plus [chrome] logical pixels for a panel's own header,
/// caption and footer rows — for previews that are given one fixed box height
/// covering both the frame and its surrounding chrome.
double mobilePreviewBoxHeight(BuildContext context, {double chrome = 0}) =>
    mobilePreviewMaxHeight(context) + chrome;
