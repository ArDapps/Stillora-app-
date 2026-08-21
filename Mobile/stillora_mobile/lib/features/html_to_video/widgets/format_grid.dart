import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/widgets/render_panel.dart';
import '../html_to_video_options.dart';

/// Two-column grid of selectable output-size tiles: a thin [SizeOption] adapter
/// over the shared [RenderTileGrid] / [RenderFormatTile] pair.
class FormatGrid extends StatelessWidget {
  const FormatGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<SizeOption> options;
  final SizeOption selected;
  final ValueChanged<SizeOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return RenderTileGrid(
      tiles: [
        for (final option in options)
          RenderFormatTile(
            label: option.labelOf(context.strings),
            ratio: option.ratio,
            selected: option == selected,
            onTap: () => onSelected(option),
          ),
      ],
    );
  }
}
