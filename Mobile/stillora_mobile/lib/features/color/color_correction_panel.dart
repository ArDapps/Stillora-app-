import 'package:flutter/material.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import 'color_adjust.dart';

/// Shared colour-correction editor: one-tap preset looks plus fine sliders for
/// brightness, contrast, saturation, warmth, tint, vibrance, exposure and
/// sharpness. Emits a new [ColorAdjust] on every change so the caller can drive
/// a live [ColorGradedPreview] and pass the grade to the export.
///
/// Reused by the Create, Speed, Watermark and Remove-Silence sections.
class ColorCorrectionPanel extends StatelessWidget {
  const ColorCorrectionPanel({
    super.key,
    required this.value,
    required this.onChanged,
    this.initiallyExpanded = false,
  });

  final ColorAdjust value;
  final ValueChanged<ColorAdjust> onChanged;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = !value.isIdentity;
    return StilloraGlassCard(
      child: Theme(
        // Drop the ExpansionTile divider lines for a cleaner card.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: StilloraSpacing.xs),
          leading: Icon(
            Icons.tune_rounded,
            color: active ? StilloraColors.brandViolet : StilloraColors.primary,
          ),
          title: Text(
            'Color Correction',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            active ? 'Custom grade applied' : 'Grade the final video',
            style: theme.textTheme.bodySmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
          children: [
            _PresetRow(value: value, onChanged: onChanged),
            const SizedBox(height: StilloraSpacing.sm),
            _ColorSlider(
              label: 'Brightness',
              icon: Icons.brightness_6_rounded,
              value: value.brightness,
              onChanged: (v) => onChanged(value.copyWith(brightness: v)),
            ),
            _ColorSlider(
              label: 'Contrast',
              icon: Icons.contrast_rounded,
              value: value.contrast,
              onChanged: (v) => onChanged(value.copyWith(contrast: v)),
            ),
            _ColorSlider(
              label: 'Saturation',
              icon: Icons.opacity_rounded,
              value: value.saturation,
              onChanged: (v) => onChanged(value.copyWith(saturation: v)),
            ),
            _ColorSlider(
              label: 'Warmth',
              icon: Icons.thermostat_rounded,
              value: value.warmth,
              onChanged: (v) => onChanged(value.copyWith(warmth: v)),
            ),
            _ColorSlider(
              label: 'Tint',
              icon: Icons.colorize_rounded,
              value: value.tint,
              onChanged: (v) => onChanged(value.copyWith(tint: v)),
            ),
            _ColorSlider(
              label: 'Vibrance',
              icon: Icons.auto_awesome_rounded,
              value: value.vibrance,
              onChanged: (v) => onChanged(value.copyWith(vibrance: v)),
            ),
            _ColorSlider(
              label: 'Exposure',
              icon: Icons.exposure_rounded,
              value: value.exposure,
              onChanged: (v) => onChanged(value.copyWith(exposure: v)),
            ),
            _ColorSlider(
              label: 'Sharpness',
              icon: Icons.details_rounded,
              value: value.sharpness,
              min: 0,
              onChanged: (v) => onChanged(value.copyWith(sharpness: v)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: active
                    ? () => onChanged(ColorAdjust.identity)
                    : null,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.value, required this.onChanged});

  final ColorAdjust value;
  final ValueChanged<ColorAdjust> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final preset in colorPresets) ...[
            _PresetChip(
              label: preset.label,
              icon: preset.icon,
              selected: value == preset.adjust,
              onTap: () => onChanged(preset.adjust),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : StilloraColors.onSurfaceVariant;
    return Material(
      color: selected
          ? StilloraColors.brandViolet.withValues(alpha: 0.9)
          : StilloraColors.surfaceContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.min = -1,
  });

  final String label;
  final IconData icon;
  final double value;
  final double min;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    // Show a signed percentage so the neutral centre reads as 0%.
    final pct = (value * 100).round();
    final display = min < 0 ? (pct > 0 ? '+$pct%' : '$pct%') : '$pct%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: StilloraColors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              Text(
                display,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: value == 0
                      ? StilloraColors.onSurfaceVariant
                      : StilloraColors.brandViolet,
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
              value: value.clamp(min, 1),
              min: min,
              max: 1,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
