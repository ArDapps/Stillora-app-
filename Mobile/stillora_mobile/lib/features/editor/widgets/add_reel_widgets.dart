import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_surface.dart';
import '../../../core/format/duration_label.dart';
import '../editor_state.dart' show formatFileSize;
import '../reel_state.dart';
import '../video_preset.dart';

class ReelModeSection extends StatelessWidget {
  const ReelModeSection({
    super.key,
    required this.reel,
    required this.controller,
  });

  final ReelState reel;
  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3D video reel', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final mockup in ReelMockup.values) ...[
                  ReelChip(
                    label: mockup.label,
                    selected: reel.mockup == mockup,
                    onTap: () => controller.setMockup(mockup),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReelDurationBanner extends StatelessWidget {
  const ReelDurationBanner({super.key, required this.reel});

  final ReelState reel;

  @override
  Widget build(BuildContext context) {
    final seconds = reel.outputDurationSeconds;
    return StilloraGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: StilloraColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              seconds > 0
                  ? 'Output ${formatDurationLabel(seconds)} - ${reel.hasAudio ? 'matches audio' : 'matches app video'}'
                  : 'Measuring length...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class ReelAudioRow extends StatelessWidget {
  const ReelAudioRow({
    super.key,
    required this.reel,
    required this.onPick,
    required this.onRemove,
  });

  final ReelState reel;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      onTap: reel.hasAudio ? null : onPick,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.music_note_rounded,
            color: StilloraColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reel.hasAudio
                  ? 'Audio added - sets reel length'
                  : 'Add audio (optional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (reel.hasAudio)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              tooltip: 'Remove audio',
            )
          else
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class ReelFormatExportSection extends StatelessWidget {
  const ReelFormatExportSection({
    super.key,
    required this.reel,
    required this.controller,
    required this.onExport,
  });

  final ReelState reel;
  final ReelController controller;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final res = reel.outputResolution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Format & export', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in videoPresets) ...[
                ReelChip(
                  label: '${preset.label} - ${preset.ratioLabel}',
                  selected: preset.id == reel.preset.id,
                  onTap: () => controller.setPreset(preset),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ExportQuality>(
            showSelectedIcon: false,
            segments: [
              for (final quality in ExportQuality.values)
                ButtonSegment(value: quality, label: Text(quality.label)),
            ],
            selected: {reel.exportQuality},
            onSelectionChanged: (value) =>
                controller.setExportQuality(value.first),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${res.width} x ${res.height} - about ${formatFileSize(reel.estimatedExportBytes)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        StilloraPrimaryButton(
          onPressed: onExport,
          icon: Icons.movie_filter_rounded,
          label: 'Export MP4',
        ),
      ],
    );
  }
}

class ReelPickCard extends StatelessWidget {
  const ReelPickCard({super.key, required this.onPick, required this.mockup});

  final VoidCallback onPick;
  final ReelMockup mockup;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      onTap: onPick,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        children: [
          Icon(
            Icons.video_call_rounded,
            color: StilloraColors.primary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            mockup == ReelMockup.none
                ? 'Add video or image'
                : 'Upload app video',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            mockup == ReelMockup.none
                ? 'Create a simple reel from your media.'
                : 'Your screen recording is placed inside the selected 3D device.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ReelChip extends StatelessWidget {
  const ReelChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? StilloraColors.primary.withValues(alpha: 0.9)
          : StilloraColors.surfaceContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? StilloraColors.onPrimary
                  : StilloraColors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
