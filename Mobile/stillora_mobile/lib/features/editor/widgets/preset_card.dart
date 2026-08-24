import 'package:flutter/material.dart';

import '../../../core/format/duration_label.dart';
import '../../../core/design/render_components.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/pro/pro_quality_picker.dart';
import '../../../core/widgets/duration_slider.dart';
import '../editor_state.dart';
import '../video_preset.dart';
import 'duration_chip.dart';
import 'editor_shared.dart';
import 'output_size_controls.dart';
import '../../../core/i18n/app_strings.dart';

class PresetCard extends StatelessWidget {
  const PresetCard({
    super.key,
    required this.editor,
    required this.controller,
    this.compact = false,
  });

  final EditorState editor;
  final EditorController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RenderStepCard(
      number: '3',
      title: context.strings.edPresets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RenderTileGrid(
            tiles: [
              for (final preset in videoPresets)
                RenderSelectTile(
                  title: preset.labelOf(context.strings),
                  subtitle: preset.ratioLabel,
                  selected: editor.preset == preset,
                  onTap: () => controller.setPreset(preset),
                ),
            ],
          ),
          OutputSizeControls(
            editor: editor,
            onCustomSize: controller.setCustomSize,
            onReferenceSelected: controller.setOriginalReferenceIndex,
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text(
            context.strings.edResize,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: StilloraSpacing.xs),
          RenderPillSegmented(
            options: [context.strings.loopFit, context.strings.loopFill],
            selectedIndex: editor.resizeMode == ResizeMode.fit ? 0 : 1,
            onSelected: (i) => controller.setResizeMode(
              i == 0 ? ResizeMode.fit : ResizeMode.fill,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text(
            context.strings.toolQuality,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: StilloraSpacing.xs),
          ProQualityPicker(
            selected: editor.exportQuality,
            onSelected: controller.setExportQuality,
          ),
          const SizedBox(height: 4),
          Text(
            '${editor.outputResolution.width} × ${editor.outputResolution.height}'
            '  ·  ≈ ${formatFileSize(editor.estimatedExportBytes)}'
            '  ·  ${editor.exportQuality.note(context.strings)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text(
            editor.media.length > 1
                ? context.strings.edTotalDuration
                : context.strings.edDuration,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (editor.media.length > 1) ...[
            const SizedBox(height: 2),
            Text(
              context.strings.edSplitsEvenly,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: StilloraSpacing.xs),
          Wrap(
            spacing: StilloraSpacing.xs,
            runSpacing: StilloraSpacing.xs,
            children: [
              DurationChip(
                label: '10s',
                selected: editor.totalDurationSeconds == 10,
                onSelected: () => controller.setDuration(10),
                compact: compact,
              ),
              DurationChip(
                label: '30s',
                selected: editor.totalDurationSeconds == 30,
                onSelected: () => controller.setDuration(30),
                compact: compact,
              ),
              DurationChip(
                label: context.strings.durMinutes(1),
                selected: editor.totalDurationSeconds == 60,
                onSelected: () => controller.setDuration(60),
                compact: compact,
              ),
              DurationChip(
                label: context.strings.durMinutes(5),
                selected: editor.totalDurationSeconds == 300,
                onSelected: () => controller.setDuration(300),
                compact: compact,
              ),
              DurationChip(
                label: context.strings.durMinutes(10),
                selected: editor.totalDurationSeconds == 600,
                onSelected: () => controller.setDuration(600),
                compact: compact,
              ),
              DurationChip(
                label: context.strings.durMinutes(30),
                selected: editor.totalDurationSeconds == 1800,
                onSelected: () => controller.setDuration(1800),
                compact: compact,
              ),
              if (editor.audioDurationSeconds != null)
                DurationChip(
                  label:
                      '${context.strings.edUseAudioLength} '
                      '${formatDurationClock(editor.audioDurationSeconds!)}',
                  selected:
                      editor.totalDurationSeconds ==
                      editor.audioDurationSeconds,
                  onSelected: () =>
                      controller.setDuration(editor.audioDurationSeconds!),
                  compact: compact,
                ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          DurationSlider(
            seconds: editor.totalDurationSeconds,
            min: minDurationSeconds,
            onChanged: controller.setDuration,
          ),
        ],
      ),
    );
  }
}
