import 'package:flutter/material.dart';

import '../../features/editor/video_preset.dart';
import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';
import '../design/stillora_surface.dart';
import '../format/duration_label.dart';

/// Shared chrome for the "load a base video, stack things on it, export" model
/// sections (Text, Watermark, …). Each section supplies its own copy; the
/// layout, spacing and behaviour stay identical across them.

/// Summary of the loaded base video, with a button to swap it out. Shows
/// "Reading video…" until the source has actually been measured.
class SectionBaseInfoRow extends StatelessWidget {
  const SectionBaseInfoRow({
    super.key,
    required this.resolution,
    required this.durationSeconds,
    required this.measured,
    required this.onReplace,
  });

  final ({int width, int height}) resolution;
  final int durationSeconds;
  final bool measured;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.movie_creation_rounded,
            size: 20,
            color: StilloraColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              measured
                  ? 'Base video · ${resolution.width}×${resolution.height} · '
                        '${formatDurationLabel(durationSeconds)}'
                  : 'Reading video…',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onReplace, child: const Text('Replace')),
        ],
      ),
    );
  }
}

/// Export header, primary action, and the per-section note about which
/// platforms can currently render the burn-in.
class SectionExportPanel extends StatelessWidget {
  const SectionExportPanel({
    super.key,
    required this.resolution,
    required this.durationSeconds,
    required this.canExport,
    required this.onExport,
    required this.platformNote,
  });

  final ({int width, int height}) resolution;
  final int durationSeconds;
  final bool canExport;
  final VoidCallback onExport;
  final String platformNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Export', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Text(
          'Output ${resolution.width} × ${resolution.height} · '
          '${formatDurationLabel(durationSeconds)} · keeps original audio',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        StilloraPrimaryButton(
          onPressed: canExport ? onExport : null,
          icon: Icons.movie_filter_rounded,
          label: 'Export MP4',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: StilloraColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                platformNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Empty-state card prompting the user to pick the base video for the section.
class SectionPickBaseCard extends StatelessWidget {
  const SectionPickBaseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPick,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      onTap: onPick,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        children: [
          const Icon(
            Icons.video_call_rounded,
            color: StilloraColors.primary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
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

/// Output-resolution picker: Original (keep the source size) or a tier that
/// scales the short edge to 720p/1080p/2K/4K, aspect preserved. `null` = Original.
class SectionResolutionSelector extends StatelessWidget {
  const SectionResolutionSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ExportQuality? selected;
  final ValueChanged<ExportQuality?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resolution', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Original'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
            for (final q in ExportQuality.values)
              ChoiceChip(
                label: Text(q.label),
                selected: selected == q,
                onSelected: (_) => onSelected(q),
              ),
          ],
        ),
      ],
    );
  }
}

/// Modal shown while a section export runs, with a Cancel button that aborts
/// the in-flight export (and its colour-grade pass).
class SectionExportingDialog extends StatefulWidget {
  const SectionExportingDialog({super.key, required this.onCancel});

  final Future<void> Function() onCancel;

  @override
  State<SectionExportingDialog> createState() => _SectionExportingDialogState();
}

class _SectionExportingDialogState extends State<SectionExportingDialog> {
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: StilloraColors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: StilloraSpacing.sm),
            Text(
              _cancelling ? 'Cancelling…' : 'Exporting…',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: StilloraSpacing.sm),
            OutlinedButton.icon(
              onPressed: _cancelling
                  ? null
                  : () async {
                      setState(() => _cancelling = true);
                      await widget.onCancel();
                    },
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel export'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muted single-line hint shown when a section's layer/overlay list is empty.
class SectionEmptyHint extends StatelessWidget {
  const SectionEmptyHint(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: StilloraColors.onSurfaceVariant),
    );
  }
}
