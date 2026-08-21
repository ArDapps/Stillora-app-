import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/design/stillora_surface.dart';
import '../text_layer.dart';
import '../text_overlay_controller.dart';
import '../text_overlay_state.dart';

/// "Add Text" plus one-tap style presets (Title / Subtitle / Caption / CTA).
class AddTextRow extends StatelessWidget {
  const AddTextRow({super.key, required this.controller});

  final TextOverlayController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => controller.addText(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add text'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in TextPreset.values)
              ActionChip(
                avatar: const Icon(Icons.title_rounded, size: 16),
                label: Text(preset.label),
                onPressed: () => controller.addText(preset),
              ),
          ],
        ),
      ],
    );
  }
}

/// A compact timeline: one bar per layer spanning the clip, with its visible
/// window highlighted so you can see when each text appears.
class TimelineStrip extends StatelessWidget {
  const TimelineStrip({super.key, required this.st, required this.onSelect});

  final TextOverlayState st;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final total = st.baseDurationSeconds <= 0
        ? 1.0
        : st.baseDurationSeconds.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Timeline', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < st.layers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    child: Text(
                      st.layers[i].text.isEmpty ? 'Text' : st.layers[i].text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: i == st.selected
                            ? StilloraColors.primary
                            : StilloraColors.onSurfaceVariant,
                        fontWeight: i == st.selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        final start = (st.layers[i].start / total).clamp(
                          0.0,
                          1.0,
                        );
                        final end =
                            (st.layers[i].end <= 0
                                    ? 1.0
                                    : st.layers[i].end / total)
                                .clamp(0.0, 1.0);
                        return SizedBox(
                          height: 14,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: StilloraColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              Positioned(
                                left: start * w,
                                width: ((end - start) * w).clamp(2.0, w),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        StilloraColors.brandMagenta,
                                        StilloraColors.brandViolet,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class LayerList extends StatelessWidget {
  const LayerList({super.key, required this.st, required this.controller});

  final TextOverlayState st;
  final TextOverlayController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Layers', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < st.layers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: StilloraSpacing.xs),
            child: StilloraGlassCard(
              onTap: () => controller.select(i),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.text_fields_rounded,
                    size: 20,
                    color: i == st.selected
                        ? StilloraColors.primary
                        : StilloraColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      st.layers[i].text.isEmpty
                          ? 'Empty text'
                          : st.layers[i].text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: i == 0
                        ? null
                        : () => controller.reorder(i, i - 1),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    tooltip: 'Move up',
                    visualDensity: VisualDensity.compact,
                    color: StilloraColors.onSurfaceVariant,
                  ),
                  IconButton(
                    onPressed: i == st.layers.length - 1
                        ? null
                        : () => controller.reorder(i, i + 2),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    tooltip: 'Move down',
                    visualDensity: VisualDensity.compact,
                    color: StilloraColors.onSurfaceVariant,
                  ),
                  IconButton(
                    onPressed: () => controller.duplicateLayer(i),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Duplicate',
                    visualDensity: VisualDensity.compact,
                    color: StilloraColors.onSurfaceVariant,
                  ),
                  IconButton(
                    onPressed: () => controller.removeLayer(i),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
