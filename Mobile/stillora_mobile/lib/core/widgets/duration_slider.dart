import 'package:flutter/material.dart';

import '../design/stillora_colors.dart';
import '../format/duration_label.dart';

/// A clean labelled slider for picking a duration, matching the colour-correction
/// slider style. The max grows in 5-minute steps so any length stays reachable
/// (a preset chip or typed value above the current max lifts the ceiling).
///
/// Replaces the old number-field + ± stepper combo across the sections.
class DurationSlider extends StatelessWidget {
  const DurationSlider({
    super.key,
    required this.seconds,
    required this.onChanged,
    this.min = 1,
    this.maxSeconds,
    this.label = 'Duration',
    this.icon = Icons.timer_outlined,
  });

  final int seconds;
  final ValueChanged<int> onChanged;
  final int min;

  /// Fixed upper bound. When null the ceiling grows dynamically in 5-minute
  /// steps so any length stays reachable.
  final int? maxSeconds;

  final String label;
  final IconData icon;

  static const _step = 300; // 5 min — the granularity the ceiling grows by.

  double _sliderMax(int value) {
    if (maxSeconds != null) return maxSeconds!.toDouble();
    final v = value < min ? min : value;
    if (v <= _step) return _step.toDouble();
    return (((v + _step - 1) ~/ _step) * _step).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = _sliderMax(seconds);
    final value = seconds.toDouble().clamp(min.toDouble(), maxValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: StilloraColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            Text(
              formatDurationShort(seconds),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: StilloraColors.brandViolet,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value,
            min: min.toDouble(),
            max: maxValue,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
