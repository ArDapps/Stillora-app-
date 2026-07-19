import 'package:flutter/material.dart';

import '../../../core/design/render_components.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../editor/editor_export_estimate.dart';
import '../../editor/video_preset.dart';
import '../html_to_video_options.dart';
import 'format_grid.dart';

/// Step 2: the output canvas size and quality tier, with a live estimate of
/// the resulting pixel dimensions and file size.
class OutputSizeCard extends StatelessWidget {
  const OutputSizeCard({
    super.key,
    required this.size,
    required this.quality,
    required this.durationSeconds,
    required this.fps,
    required this.hasAudio,
    required this.onSizeChanged,
    required this.onQualityChanged,
  });

  final SizeOption size;
  final ExportQuality quality;
  final int durationSeconds;
  final int fps;
  final bool hasAudio;
  final ValueChanged<SizeOption> onSizeChanged;
  final ValueChanged<ExportQuality> onQualityChanged;

  @override
  Widget build(BuildContext context) {
    final output = scaleDimensionsToQuality(size.width, size.height, quality);
    final bytes = estimateExportBytes(
      width: output.width,
      height: output.height,
      durationSeconds: durationSeconds,
      hasVideo: true,
      hasAudio: hasAudio,
      fps: fps,
    );
    return RenderStepCard(
      number: '2',
      title: 'Output size',
      trailing: RenderTagPill('${output.width}×${output.height}'),
      footer: 'Reels · TikTok · Stories · YouTube',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormatGrid(
            options: sizeOptions,
            selected: size,
            onSelected: onSizeChanged,
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text('Quality', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: StilloraSpacing.xs),
          RenderPillSegmented(
            options: [for (final q in ExportQuality.values) q.label],
            selectedIndex: ExportQuality.values.indexOf(quality),
            onSelected: (i) => onQualityChanged(ExportQuality.values[i]),
          ),
          const SizedBox(height: 4),
          Text(
            '${output.width} × ${output.height}  ·  ≈ ${formatFileSize(bytes)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
