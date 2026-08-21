import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/design/stillora_surface.dart';
import '../../../core/format/duration_label.dart';
import '../watermark_state.dart';

class WatermarkOverlayList extends StatelessWidget {
  const WatermarkOverlayList({required this.wm, required this.controller});

  final WatermarkState wm;
  final WatermarkController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overlays', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < wm.overlays.length; i++)
          WatermarkOverlayRow(
            key: ValueKey(wm.overlays[i].path),
            index: i,
            overlay: wm.overlays[i],
            baseDuration: wm.baseDurationSeconds,
            selected: i == wm.selectedOverlay,
            onSelect: () => controller.selectOverlay(i),
            onRemove: () => controller.removeOverlay(i),
            onWindow: (start, end) =>
                controller.setOverlayWindow(i, start, end),
          ),
      ],
    );
  }
}

class WatermarkOverlayRow extends StatelessWidget {
  const WatermarkOverlayRow({
    super.key,
    required this.index,
    required this.overlay,
    required this.baseDuration,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
    required this.onWindow,
  });

  final int index;
  final WatermarkOverlay overlay;
  final int baseDuration;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final void Function(double start, double end) onWindow;

  @override
  Widget build(BuildContext context) {
    final max = baseDuration <= 0 ? 1.0 : baseDuration.toDouble();
    final start = overlay.start.clamp(0.0, max);
    final end = overlay.end.clamp(start, max);
    return Padding(
      padding: const EdgeInsets.only(bottom: StilloraSpacing.xs),
      child: StilloraGlassCard(
        onTap: onSelect,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  overlay.isVideo
                      ? Icons.movie_creation_rounded
                      : Icons.image_rounded,
                  size: 20,
                  color: selected
                      ? StilloraColors.primary
                      : StilloraColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    overlay.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  color: StilloraColors.onSurfaceVariant,
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: StilloraColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Shows ${formatDurationLabel(start.round())} – ${formatDurationLabel(end.round())}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            RangeSlider(
              min: 0,
              max: max,
              divisions: baseDuration > 0 ? baseDuration : null,
              values: RangeValues(start, end),
              labels: RangeLabels(
                formatDurationLabel(start.round()),
                formatDurationLabel(end.round()),
              ),
              onChanged: (v) => onWindow(v.start, v.end),
            ),
          ],
        ),
      ),
    );
  }
}
