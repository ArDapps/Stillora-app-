import 'package:flutter/material.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/video_thumbnail.dart';
import 'color_adjust.dart';
import 'color_correction_panel.dart';
import 'color_graded_preview.dart';

/// Drop-in colour-correction block for a section screen: a live graded frame
/// preview of [videoPath] plus the slider/preset panel. The preview updates
/// instantly as the sliders move, so the user sees how the exported video will
/// look before exporting.
///
/// Renders nothing unless colour grading is supported on this platform
/// (desktop, phase 1) and a source video is set — so it stays invisible on
/// mobile until the native engines implement `colorGrade`.
class ColorGradeSection extends StatelessWidget {
  const ColorGradeSection({
    super.key,
    required this.videoPath,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.showPreview = true,
  });

  final String? videoPath;
  final ColorAdjust value;
  final ValueChanged<ColorAdjust> onChanged;
  final bool enabled;

  /// Set false when the host screen already shows the graded frame elsewhere
  /// (the desktop right-hand preview pane), leaving only the sliders here.
  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    final path = videoPath;
    if (!colorGradingSupported || path == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPreview) ...[
          Center(
            child: ColorGradedPreview(
              adjust: value,
              // A poster frame is enough to preview the grade and is cheap; the
              // ColorFiltered wrapper repaints live as the sliders change.
              child: VideoThumbnail(
                key: ValueKey(path),
                path: path,
                width: 340,
                height: 210,
                radius: 16,
                showPlayIcon: false,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 14,
                color: StilloraColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Live preview — how the exported video will look',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        AbsorbPointer(
          absorbing: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: ColorCorrectionPanel(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}
