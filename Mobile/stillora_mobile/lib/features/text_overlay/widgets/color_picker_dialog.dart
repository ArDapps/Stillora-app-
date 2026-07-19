import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';

/// A dependency-free colour picker: RGB sliders plus a hex field, with a live
/// preview. Returns the chosen [Color] (opaque) via `Navigator.pop`.
class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key, required this.initial});

  final Color initial;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late int _r = (widget.initial.r * 255).round();
  late int _g = (widget.initial.g * 255).round();
  late int _b = (widget.initial.b * 255).round();
  late final TextEditingController _hex = TextEditingController(
    text: _toHex(_r, _g, _b),
  );

  Color get _color => Color.fromARGB(255, _r, _g, _b);

  static String _toHex(int r, int g, int b) =>
      '#${r.toRadixString(16).padLeft(2, '0')}'
              '${g.toRadixString(16).padLeft(2, '0')}'
              '${b.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  void _syncHexFromRgb() {
    _hex.value = TextEditingValue(text: _toHex(_r, _g, _b));
  }

  void _applyHex(String raw) {
    var s = raw.trim().replaceAll('#', '');
    if (s.length == 3) {
      s = s.split('').map((c) => '$c$c').join();
    }
    if (s.length != 6) return;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return;
    setState(() {
      _r = (v >> 16) & 0xff;
      _g = (v >> 8) & 0xff;
      _b = v & 0xff;
    });
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: StilloraColors.surfaceContainer,
      title: const Text('Pick a colour'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: StilloraColors.glassStroke),
              ),
            ),
            const SizedBox(height: 14),
            _channel('R', _r, Colors.red, (v) {
              setState(() => _r = v);
              _syncHexFromRgb();
            }),
            _channel('G', _g, Colors.green, (v) {
              setState(() => _g = v);
              _syncHexFromRgb();
            }),
            _channel('B', _b, Colors.blue, (v) {
              setState(() => _b = v);
              _syncHexFromRgb();
            }),
            const SizedBox(height: 8),
            TextField(
              controller: _hex,
              decoration: const InputDecoration(
                labelText: 'Hex',
                prefixText: '',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: _applyHex,
              onChanged: (v) {
                final s = v.trim().replaceAll('#', '');
                if (s.length == 6 || s.length == 3) _applyHex(v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('Use colour'),
        ),
      ],
    );
  }

  Widget _channel(
    String label,
    int value,
    Color tint,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: tint,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(width: 34, child: Text('$value', textAlign: TextAlign.end)),
      ],
    );
  }
}
