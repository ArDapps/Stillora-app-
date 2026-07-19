import 'package:flutter/material.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/widgets/video_thumbnail.dart';
import '../color/color_adjust.dart';
import '../color/color_graded_preview.dart';

/// A single label/value line under the preview frame (e.g. "Output · 1080×1920").
typedef PreviewStat = ({String label, String value});

/// The stock live-preview body for the tool sections (Speed, Remove Silence,
/// Compress, …): the source video's poster frame, graded exactly the way the
/// export will grade it, sized to fill the preview pane, with the current
/// settings summarised underneath.
///
/// Shows a hatched empty state until a video is picked, so the right-hand pane
/// still reads as the preview surface before any file is loaded.
class SectionVideoPreview extends StatelessWidget {
  const SectionVideoPreview({
    super.key,
    required this.videoPath,
    required this.sourceWidth,
    required this.sourceHeight,
    this.color = ColorAdjust.identity,
    this.badge,
    this.stats = const [],
    this.emptyLabel = 'Upload a video to preview it here',
    this.emptyIcon = Icons.movie_creation_outlined,
  });

  final String? videoPath;
  final int sourceWidth;
  final int sourceHeight;

  /// Live colour grade — the preview repaints as the sliders move.
  final ColorAdjust color;

  /// Optional pill drawn over the top-left of the frame (e.g. "2x").
  final String? badge;

  final List<PreviewStat> stats;
  final String emptyLabel;
  final IconData emptyIcon;

  double get _aspectRatio =>
      sourceWidth > 0 && sourceHeight > 0 ? sourceWidth / sourceHeight : 16 / 9;

  @override
  Widget build(BuildContext context) {
    // Fit the frame inside the pane on both axes so a portrait clip never
    // pushes the stats out of view. In a scrolling column (unbounded height)
    // the frame is simply sized from the width instead.
    final frame = LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : maxW / _aspectRatio;
        var w = maxW;
        var h = w / _aspectRatio;
        if (h > maxH) {
          h = maxH;
          w = h * _aspectRatio;
        }
        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: _Frame(
              videoPath: videoPath,
              color: color,
              badge: badge,
              emptyLabel: emptyLabel,
              emptyIcon: emptyIcon,
              width: w,
              height: h,
            ),
          ),
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (constraints.hasBoundedHeight) Flexible(child: frame) else frame,
          if (stats.isNotEmpty) ...[
            const SizedBox(height: StilloraSpacing.snug),
            for (final stat in stats)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      stat.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        stat.value,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// A framed preview stage that scales an interactive [child] (a live composite
/// with draggable overlays, say) to fill the preview pane at [aspectRatio],
/// falling back to an empty state until a base clip is loaded.
class PreviewStage extends StatelessWidget {
  const PreviewStage({
    super.key,
    required this.aspectRatio,
    this.child,
    this.emptyLabel = 'Load a video to preview it here',
    this.emptyIcon = Icons.movie_creation_outlined,
  });

  final double aspectRatio;
  final Widget? child;
  final String emptyLabel;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    final content = child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = aspectRatio > 0 ? aspectRatio : 16 / 9;
        final maxW = constraints.maxWidth;
        final maxH = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : maxW / ratio;
        var w = maxW;
        var h = w / ratio;
        if (h > maxH) {
          h = maxH;
          w = h * ratio;
        }
        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: StilloraColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(StilloraRadius.card),
                border: Border.all(
                  color: content == null
                      ? StilloraColors.glassStroke
                      : StilloraColors.primary.withValues(alpha: 0.5),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(StilloraRadius.card),
                child:
                    content ??
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(StilloraSpacing.sm),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              emptyIcon,
                              size: 34,
                              color: StilloraColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: StilloraSpacing.xs),
                            Text(
                              emptyLabel,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: StilloraColors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.videoPath,
    required this.color,
    required this.badge,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.width,
    required this.height,
  });

  final String? videoPath;
  final ColorAdjust color;
  final String? badge;
  final String emptyLabel;
  final IconData emptyIcon;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final path = videoPath;
    final decoration = BoxDecoration(
      color: StilloraColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(StilloraRadius.card),
      border: Border.all(
        color: path == null
            ? StilloraColors.glassStroke
            : StilloraColors.primary.withValues(alpha: 0.5),
      ),
    );

    if (path == null) {
      return DecoratedBox(
        decoration: decoration,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(StilloraSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  emptyIcon,
                  size: 34,
                  color: StilloraColors.onSurfaceVariant,
                ),
                const SizedBox(height: StilloraSpacing.xs),
                Text(
                  emptyLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(StilloraRadius.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorGradedPreview(
              adjust: color,
              // A poster frame is enough to judge the grade and is cheap; the
              // ColorFiltered wrapper repaints live as the sliders change.
              child: VideoThumbnail(
                key: ValueKey(path),
                path: path,
                width: width,
                height: height,
                radius: StilloraRadius.card,
                showPlayIcon: false,
              ),
            ),
            if (badge != null)
              Positioned(
                left: StilloraSpacing.xs,
                top: StilloraSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(StilloraRadius.pill),
                  ),
                  child: Text(
                    badge!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
