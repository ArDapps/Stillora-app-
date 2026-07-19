import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_surface.dart';
import '../../../core/format/duration_label.dart';
import '../text_layer.dart';
import '../text_overlay_controller.dart';
import 'color_picker_dialog.dart';

/// Full property editor for the selected layer: content, font, size, colours,
/// stroke, shadow, alignment, opacity, timing and fade.
class PropertyEditor extends StatelessWidget {
  const PropertyEditor({
    super.key,
    required this.index,
    required this.layer,
    required this.baseDuration,
    required this.controller,
  });

  final int index;
  final TextLayer layer;
  final int baseDuration;
  final TextOverlayController controller;

  void _u(TextLayer Function(TextLayer) f) => controller.updateLayer(index, f);

  @override
  Widget build(BuildContext context) {
    final maxEnd = baseDuration <= 0 ? 1.0 : baseDuration.toDouble();
    final start = layer.start.clamp(0.0, maxEnd);
    final end = (layer.end <= 0 ? maxEnd : layer.end).clamp(start, maxEnd);
    final span = end - start;
    return StilloraGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit text', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('text_${layer.id}'),
            initialValue: layer.text,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Text',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => _u((l) => l.copyWith(text: v)),
          ),
          const SizedBox(height: 14),

          // Font family.
          _FieldLabel('Font'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final font in kTextFontFamilies)
                ChoiceChip(
                  label: Text(font.$1),
                  selected: layer.fontFamily == font.$2,
                  onSelected: (_) => _u((l) => l.copyWith(fontFamily: font.$2)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Weight.
          _FieldLabel('Weight'),
          Wrap(
            spacing: 8,
            children: [
              for (final w in const [
                FontWeight.w400,
                FontWeight.w600,
                FontWeight.w700,
                FontWeight.w900,
              ])
                ChoiceChip(
                  label: Text(_weightLabel(w)),
                  selected: layer.fontWeight == w,
                  onSelected: (_) => _u((l) => l.copyWith(fontWeight: w)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Alignment.
          _FieldLabel('Alignment'),
          Wrap(
            spacing: 8,
            children: [
              _alignChip(Icons.format_align_left_rounded, TextAlign.left),
              _alignChip(Icons.format_align_center_rounded, TextAlign.center),
              _alignChip(Icons.format_align_right_rounded, TextAlign.right),
            ],
          ),
          const SizedBox(height: 12),

          _SliderRow(
            label: 'Size',
            value: layer.fontScale,
            min: minFontScale,
            max: maxFontScale,
            display: '${(layer.fontScale * 100).round()}%',
            onChanged: (v) => _u((l) => l.copyWith(fontScale: v)),
          ),
          _SliderRow(
            label: 'Opacity',
            value: layer.opacity,
            min: 0,
            max: 1,
            display: '${(layer.opacity * 100).round()}%',
            onChanged: (v) => _u((l) => l.copyWith(opacity: v)),
          ),

          const SizedBox(height: 8),
          _FieldLabel('Text colour'),
          _SwatchRow(
            selected: layer.color,
            includeNone: false,
            onPick: (c) => _u((l) => l.copyWith(color: c!)),
          ),
          const SizedBox(height: 12),
          _FieldLabel('Background'),
          _SwatchRow(
            selected: layer.backgroundColor,
            includeNone: true,
            onPick: (c) => _u((l) => l.copyWith(backgroundColor: c)),
          ),
          const SizedBox(height: 12),

          // Stroke.
          _SliderRow(
            label: 'Outline',
            value: layer.strokeWidth,
            min: 0,
            max: 0.3,
            display: layer.strokeWidth == 0
                ? 'Off'
                : '${(layer.strokeWidth * 100).round()}%',
            onChanged: (v) => _u((l) => l.copyWith(strokeWidth: v)),
          ),
          if (layer.strokeWidth > 0) ...[
            _FieldLabel('Outline colour'),
            _SwatchRow(
              selected: layer.strokeColor,
              includeNone: false,
              onPick: (c) => _u((l) => l.copyWith(strokeColor: c!)),
            ),
            const SizedBox(height: 8),
          ],

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Drop shadow'),
            value: layer.shadow,
            onChanged: (v) => _u((l) => l.copyWith(shadow: v)),
          ),

          const Divider(height: 24),

          // Timing.
          _FieldLabel(
            'Shows ${formatDurationLabel(start.round())} – ${formatDurationLabel(end.round())}',
          ),
          RangeSlider(
            min: 0,
            max: maxEnd,
            divisions: baseDuration > 0 ? baseDuration : null,
            values: RangeValues(start, end),
            labels: RangeLabels(
              formatDurationLabel(start.round()),
              formatDurationLabel(end.round()),
            ),
            onChanged: (v) => controller.setWindow(index, v.start, v.end),
          ),
          _SliderRow(
            label: 'Fade in',
            value: layer.fadeIn.clamp(0.0, span <= 0 ? 1.0 : span),
            min: 0,
            max: span <= 0 ? 1.0 : span,
            display: '${layer.fadeIn.toStringAsFixed(1)}s',
            onChanged: (v) => _u((l) => l.copyWith(fadeIn: v)),
          ),
          _SliderRow(
            label: 'Fade out',
            value: layer.fadeOut.clamp(0.0, span <= 0 ? 1.0 : span),
            min: 0,
            max: span <= 0 ? 1.0 : span,
            display: '${layer.fadeOut.toStringAsFixed(1)}s',
            onChanged: (v) => _u((l) => l.copyWith(fadeOut: v)),
          ),
        ],
      ),
    );
  }

  Widget _alignChip(IconData icon, TextAlign a) => ChoiceChip(
    label: Icon(icon, size: 18),
    selected: layer.align == a,
    onSelected: (_) => _u((l) => l.copyWith(align: a)),
  );
}

String _weightLabel(FontWeight w) => switch (w) {
  FontWeight.w400 => 'Regular',
  FontWeight.w600 => 'Medium',
  FontWeight.w700 => 'Bold',
  FontWeight.w900 => 'Black',
  _ => 'Bold',
};

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: StilloraColors.onSurfaceVariant),
    ),
  );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            display,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// Preset colour swatches (plus an optional "none" for background/stroke).
class _SwatchRow extends StatelessWidget {
  const _SwatchRow({
    required this.selected,
    required this.includeNone,
    required this.onPick,
  });

  final Color? selected;
  final bool includeNone;
  final ValueChanged<Color?> onPick;

  static const _palette = <Color>[
    Colors.white,
    Colors.black,
    Color(0xffd946ef),
    Color(0xff8b5cf6),
    Color(0xff22d3ee),
    Color(0xffef4444),
    Color(0xfff59e0b),
    Color(0xff22c55e),
    Color(0xff3b82f6),
    Color(0xfff9a8d4),
  ];

  @override
  Widget build(BuildContext context) {
    final isPreset =
        selected != null &&
        _palette.any((c) => c.toARGB32() == selected!.toARGB32());
    // When the chosen colour isn't one of the presets, it came from the custom
    // picker — show it as an extra selected swatch so it isn't lost.
    final customChosen = selected != null && !isPreset;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (includeNone)
          _swatch(
            color: null,
            selected: selected == null,
            onTap: () => onPick(null),
          ),
        for (final c in _palette)
          _swatch(
            color: c,
            selected: selected != null && selected!.toARGB32() == c.toARGB32(),
            onTap: () => onPick(c),
          ),
        if (customChosen)
          _swatch(color: selected, selected: true, onTap: () {}),
        // "＋" opens a full picker with RGB sliders and a hex field.
        GestureDetector(
          onTap: () async {
            final picked = await showDialog<Color>(
              context: context,
              builder: (_) =>
                  ColorPickerDialog(initial: selected ?? Colors.white),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const SweepGradient(
                colors: [
                  Color(0xffef4444),
                  Color(0xfff59e0b),
                  Color(0xff22c55e),
                  Color(0xff22d3ee),
                  Color(0xff3b82f6),
                  Color(0xffd946ef),
                  Color(0xffef4444),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: StilloraColors.glassStroke, width: 1.5),
            ),
            child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _swatch({
    required Color? color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? StilloraColors.primary
                : StilloraColors.glassStroke,
            width: selected ? 3 : 1.5,
          ),
        ),
        child: color == null
            ? const Icon(Icons.block_rounded, size: 16, color: Colors.white54)
            : null,
      ),
    );
  }
}
