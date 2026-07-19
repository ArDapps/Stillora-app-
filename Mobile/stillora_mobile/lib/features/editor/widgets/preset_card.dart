import 'package:flutter/material.dart';

import '../../../core/format/duration_label.dart';
import '../../../core/design/render_components.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/widgets/duration_slider.dart';
import '../editor_state.dart';
import '../video_preset.dart';
import 'duration_chip.dart';
import 'editor_shared.dart';

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
      title: 'Presets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RenderTileGrid(
            tiles: [
              for (final preset in videoPresets)
                RenderSelectTile(
                  title: preset.label,
                  subtitle: preset.ratioLabel,
                  selected: editor.preset == preset,
                  onTap: () => controller.setPreset(preset),
                ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text('Resize', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: StilloraSpacing.xs),
          RenderPillSegmented(
            options: const ['Fit', 'Fill'],
            selectedIndex: editor.resizeMode == ResizeMode.fit ? 0 : 1,
            onSelected: (i) => controller.setResizeMode(
              i == 0 ? ResizeMode.fit : ResizeMode.fill,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text('Quality', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: StilloraSpacing.xs),
          RenderPillSegmented(
            options: [for (final q in ExportQuality.values) q.label],
            selectedIndex: ExportQuality.values.indexOf(editor.exportQuality),
            onSelected: (i) =>
                controller.setExportQuality(ExportQuality.values[i]),
          ),
          const SizedBox(height: 4),
          Text(
            '${editor.outputResolution.width} × ${editor.outputResolution.height}'
            '  ·  ≈ ${formatFileSize(editor.estimatedExportBytes)}'
            '  ·  ${editor.exportQuality.note}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text(
            editor.media.length > 1 ? 'Total duration' : 'Duration',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (editor.media.length > 1) ...[
            const SizedBox(height: 2),
            Text(
              'Splits evenly across all clips. Tap a clip above to set its own time.',
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
                label: '1 min',
                selected: editor.totalDurationSeconds == 60,
                onSelected: () => controller.setDuration(60),
                compact: compact,
              ),
              DurationChip(
                label: '5 min',
                selected: editor.totalDurationSeconds == 300,
                onSelected: () => controller.setDuration(300),
                compact: compact,
              ),
              DurationChip(
                label: '10 min',
                selected: editor.totalDurationSeconds == 600,
                onSelected: () => controller.setDuration(600),
                compact: compact,
              ),
              DurationChip(
                label: '30 min',
                selected: editor.totalDurationSeconds == 1800,
                onSelected: () => controller.setDuration(1800),
                compact: compact,
              ),
              if (editor.audioDurationSeconds != null)
                DurationChip(
                  label:
                      'Use audio ${formatDurationClock(editor.audioDurationSeconds!)}',
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
