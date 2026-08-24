import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../editor_state.dart';

/// Extra output-size controls shown under the preset grid, on both the mobile
/// preset screen and the desktop preset card:
///
///  • **Custom Size** selected → width/height fields (the export uses them
///    exactly).
///  • **Original Size** with more than one clip → a chip per clip so the user
///    picks which file's native dimensions become the canvas.
///
/// Renders nothing for the fixed-ratio presets, so it never adds clutter.
class OutputSizeControls extends StatelessWidget {
  const OutputSizeControls({
    super.key,
    required this.editor,
    required this.onCustomSize,
    required this.onReferenceSelected,
  });

  final EditorState editor;

  /// Called with an exact width/height when the user edits the custom fields.
  final void Function(int width, int height) onCustomSize;

  /// Called with the clip index whose native size should feed "Original Size".
  final void Function(int index) onReferenceSelected;

  @override
  Widget build(BuildContext context) {
    if (editor.preset.usesCustomSize) {
      return _CustomSizeFields(editor: editor, onCustomSize: onCustomSize);
    }
    if (editor.preset.usesOriginalSize && editor.media.length > 1) {
      return _OriginalReferencePicker(
        editor: editor,
        onReferenceSelected: onReferenceSelected,
      );
    }
    return const SizedBox.shrink();
  }
}

class _CustomSizeFields extends StatefulWidget {
  const _CustomSizeFields({required this.editor, required this.onCustomSize});

  final EditorState editor;
  final void Function(int width, int height) onCustomSize;

  @override
  State<_CustomSizeFields> createState() => _CustomSizeFieldsState();
}

class _CustomSizeFieldsState extends State<_CustomSizeFields> {
  late final TextEditingController _w;
  late final TextEditingController _h;

  @override
  void initState() {
    super.initState();
    // Seed from any saved custom size, else the reference clip's native size,
    // else a sensible 1080×1920 so the fields are never blank.
    final ref = widget.editor.originalReferenceMedia;
    final seedW =
        widget.editor.customWidth ??
        (ref?.hasDimensions == true ? ref!.width : 1080);
    final seedH =
        widget.editor.customHeight ??
        (ref?.hasDimensions == true ? ref!.height : 1920);
    _w = TextEditingController(text: '$seedW');
    _h = TextEditingController(text: '$seedH');
    // Make sure state has a concrete size the moment Custom is chosen.
    if (!widget.editor.hasCustomSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
    }
  }

  @override
  void dispose() {
    _w.dispose();
    _h.dispose();
    super.dispose();
  }

  void _apply() {
    final w = int.tryParse(_w.text.trim());
    final h = int.tryParse(_h.text.trim());
    if (w != null && h != null && w > 0 && h > 0) {
      widget.onCustomSize(w, h);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: StilloraSpacing.snug),
      child: Row(
        children: [
          Expanded(child: _field(_w, 'Width')),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: StilloraSpacing.xs),
            child: Text('×', style: TextStyle(fontSize: 18)),
          ),
          Expanded(child: _field(_h, 'Height')),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onChanged: (_) => _apply(),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        suffixText: 'px',
      ),
    );
  }
}

class _OriginalReferencePicker extends StatelessWidget {
  const _OriginalReferencePicker({
    required this.editor,
    required this.onReferenceSelected,
  });

  final EditorState editor;
  final void Function(int index) onReferenceSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: StilloraSpacing.snug),
        Text('Use the size of', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: StilloraSpacing.xs),
        Wrap(
          spacing: StilloraSpacing.xs,
          runSpacing: StilloraSpacing.xs,
          children: [
            for (var i = 0; i < editor.media.length; i++)
              ChoiceChip(
                selected: editor.originalReferenceIndex == i,
                onSelected: (_) => onReferenceSelected(i),
                label: Text(
                  editor.media[i].dimensionsLabel == null
                      ? 'Clip ${i + 1}'
                      : 'Clip ${i + 1} · ${editor.media[i].dimensionsLabel}',
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'The other clips fit inside this size.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
