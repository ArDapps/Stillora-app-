import 'package:flutter/material.dart';

import '../../../core/design/render_components.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../html_to_video_options.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key, required this.mode, required this.onChanged});

  final InputMode mode;
  final ValueChanged<InputMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return RenderPillSegmented(
      options: const ['Paste', 'File', 'URL'],
      selectedIndex: InputMode.values.indexOf(mode),
      onSelected: (i) => onChanged(InputMode.values[i]),
    );
  }
}

/// The source field for the active [InputMode]: a markup editor, a file drop
/// zone, or a URL field.
class HtmlSourceInput extends StatelessWidget {
  const HtmlSourceInput({
    super.key,
    required this.mode,
    required this.htmlController,
    required this.urlController,
    required this.pickedFileName,
    required this.onPickFile,
  });

  final InputMode mode;
  final TextEditingController htmlController;
  final TextEditingController urlController;
  final String? pickedFileName;
  final VoidCallback onPickFile;

  static InputDecoration fieldDecoration(String hint, {Widget? prefixIcon}) {
    const radius = BorderRadius.all(Radius.circular(StilloraRadius.xl));
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: StilloraColors.onSurfaceVariant),
      prefixIcon: prefixIcon,
      alignLabelWithHint: true,
      filled: true,
      fillColor: StilloraColors.surfaceDim,
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: StilloraColors.panelBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: StilloraColors.accent, width: 1.5),
      ),
      border: const OutlineInputBorder(borderRadius: radius),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case InputMode.paste:
        return TextField(
          controller: htmlController,
          minLines: 5,
          maxLines: 10,
          keyboardType: TextInputType.multiline,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: StilloraColors.onSurface,
          ),
          decoration: fieldDecoration('<html>…</html>'),
        );
      case InputMode.file:
        return RenderDropZone(
          title: pickedFileName ?? 'Drop an .html file',
          hint: 'or click to browse · .html .htm',
          icon: Icons.description_outlined,
          onTap: onPickFile,
        );
      case InputMode.url:
        return TextField(
          controller: urlController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: TextStyle(color: StilloraColors.onSurface),
          decoration: fieldDecoration(
            'https://example.com/animation.html',
            prefixIcon: const Icon(Icons.link),
          ),
        );
    }
  }
}
