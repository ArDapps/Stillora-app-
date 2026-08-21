import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/design/render_components.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../html_to_video_options.dart';
import '../../../core/i18n/app_strings.dart';

/// The right-hand preview panel: format chip, framed canvas, and spec footer.
class PreviewPane extends StatelessWidget {
  const PreviewPane({
    super.key,
    required this.size,
    required this.fps,
    required this.player,
    required this.hasResult,
    required this.converting,
  });

  final SizeOption size;
  final int fps;
  final VideoPlayerController? player;
  final bool hasResult;
  final bool converting;

  @override
  Widget build(BuildContext context) {
    final showVideo = hasResult && player != null;
    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.md),
      decoration: BoxDecoration(
        color: StilloraColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StilloraColors.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: StilloraColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(StilloraRadius.full),
                  border: Border.all(
                    color: StilloraColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  size.chipOf(context.strings),
                  style: TextStyle(
                    color: StilloraColors.accentText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              // Phone widths leave little room next to the format chip, so the
              // dimensions give way rather than overflowing the row.
              Flexible(
                child: Text(
                  '${size.width} × ${size.height}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: StilloraColors.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.md),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: size.aspect,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(StilloraRadius.full),
                  child: showVideo
                      ? VideoPlayer(player!)
                      : PreviewPlaceholder(converting: converting),
                ),
              ),
            ),
          ),
          const SizedBox(height: StilloraSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: StilloraColors.surfaceDim,
              borderRadius: BorderRadius.circular(StilloraRadius.xl),
              border: Border.all(color: StilloraColors.panelBorder),
            ),
            child: Row(
              children: [
                Text(
                  'stillora.mp4',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: StilloraColors.onSurface,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '${size.height >= 1080 ? '1080p' : '720p'} · H.264 · $fps fps',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: StilloraColors.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PreviewPlaceholder extends StatelessWidget {
  const PreviewPlaceholder({super.key, required this.converting});
  final bool converting;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RenderHatchPainter(),
      child: ColoredBox(
        color: const Color(0xff15151f),
        child: Center(
          child: converting
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: StilloraSpacing.sm),
                    Text(
                      context.strings.htmlRendering,
                      style: TextStyle(color: StilloraColors.onSurfaceVariant),
                    ),
                  ],
                )
              : Text(
                  'your video renders here',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}
