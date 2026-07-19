import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_surface.dart';
import '../../../core/platform/platform_info.dart';
import '../../color/color_correction_panel.dart';
import '../editor_state.dart';
import '../video_styles.dart';

/// Effect + transition pickers shown on the main Create screen so styles are
/// discoverable without opening the format sub-screen. Mirrors the same
/// controls in ChoosePresetScreen (both drive the shared editor state).
class StyleCard extends StatelessWidget {
  const StyleCard({super.key, required this.editor, required this.controller});

  final EditorState editor;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: StilloraColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Style & effects',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StylePickerRow<ClipEffect>(
            title: 'Effect',
            values: ClipEffect.values,
            selected: editor.effect,
            labelOf: (e) => e.label,
            iconOf: (e) => e.icon,
            onSelected: controller.setEffect,
          ),
          const SizedBox(height: 14),
          StylePickerRow<FrameTransition>(
            title: 'Transition',
            values: FrameTransition.values,
            selected: editor.transition,
            labelOf: (t) => t.label,
            iconOf: (t) => t.icon,
            onSelected: controller.setTransition,
          ),
          // Colour correction is a real (baked) grade, unlike the preview-only
          // effects above — desktop only for now.
          if (colorGradingSupported) ...[
            const SizedBox(height: 14),
            ColorCorrectionPanel(
              value: editor.color,
              onChanged: controller.setColor,
            ),
          ],
        ],
      ),
    );
  }
}
