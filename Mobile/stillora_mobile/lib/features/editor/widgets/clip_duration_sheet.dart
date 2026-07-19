import 'package:flutter/material.dart';

import '../../../core/format/duration_label.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/design/stillora_surface.dart';
import '../../../core/widgets/duration_slider.dart';
import '../editor_state.dart';
import 'duration_chip.dart';
import 'editor_shared.dart';

/// Bottom sheet that edits a single clip's duration. Every change is applied
/// live so the timeline and preview update behind the sheet.
class ClipDurationSheet extends StatefulWidget {
  const ClipDurationSheet({
    super.key,
    required this.clipNumber,
    required this.isVideo,
    required this.initialSeconds,
    required this.initialVolume,
    required this.onChanged,
    required this.onVolumeChanged,
  });

  final int clipNumber;
  final bool isVideo;
  final int initialSeconds;
  final double initialVolume;
  final ValueChanged<int> onChanged;
  final ValueChanged<double> onVolumeChanged;

  @override
  State<ClipDurationSheet> createState() => _ClipDurationSheetState();
}

class _ClipDurationSheetState extends State<ClipDurationSheet> {
  late int _seconds = widget.initialSeconds;
  late double _volume = widget.initialVolume;

  static const _quickPicks = [1, 3, 5, 10, 30, 60, 300, 600, 1800];

  void _setVolume(double volume) {
    final clamped = normalizeClipVolume(volume);
    setState(() => _volume = clamped);
    widget.onVolumeChanged(clamped);
  }

  void _set(int seconds) {
    final clamped = normalizeDurationSeconds(seconds);
    setState(() => _seconds = clamped);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        StilloraSpacing.md,
        0,
        StilloraSpacing.md,
        StilloraSpacing.md + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.isVideo ? 'Video' : 'Photo'} ${widget.clipNumber} duration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: StilloraSpacing.xs),
          Text(
            'Set how long this clip plays in the final video.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Wrap(
            spacing: StilloraSpacing.xs,
            runSpacing: StilloraSpacing.xs,
            children: [
              for (final pick in _quickPicks)
                DurationChip(
                  label: formatDurationClock(pick),
                  selected: _seconds == pick,
                  onSelected: () => _set(pick),
                ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          DurationSlider(
            seconds: _seconds,
            min: minDurationSeconds,
            label: 'Length',
            onChanged: _set,
          ),
          if (widget.isVideo) ...[
            const SizedBox(height: StilloraSpacing.md),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: _volume <= 0 ? 'Unmute' : 'Mute',
                  onPressed: () => _setVolume(_volume <= 0 ? 1.0 : 0.0),
                  icon: Icon(
                    _volume <= 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                  ),
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: Text(
                    _volume <= 0
                        ? 'Muted'
                        : 'Volume ${(_volume * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            Slider(
              value: _volume,
              min: 0,
              max: 1,
              divisions: 20,
              label: _volume <= 0 ? 'Muted' : '${(_volume * 100).round()}%',
              onChanged: _setVolume,
            ),
            Text(
              'Controls this video clip’s own sound in the export.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: StilloraSpacing.sm),
          StilloraPrimaryButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.check_rounded,
            label: 'Done',
          ),
        ],
      ),
    );
  }
}
