import 'package:flutter/material.dart';

import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';

/// Shared "render" design language (accent + dark panel cards with numbered
/// steps) used by the HTML → Video and Loop images screens so they look alike.
/// The step-card / eyebrow / badge / pill vocabulary is defined once in
/// render_components.dart and re-exported here, so importing either file brings
/// the whole language.
export '../design/render_components.dart';

/// Selectable format tile (checkbox + label + ratio) used in a 2-up grid.
class RenderFormatTile extends StatelessWidget {
  const RenderFormatTile({
    super.key,
    required this.label,
    required this.ratio,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String ratio;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? StilloraColors.accent.withValues(alpha: 0.12)
          : StilloraColors.surfaceDim,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? StilloraColors.accent
                  : StilloraColors.panelBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? StilloraColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected
                        ? StilloraColors.accent
                        : StilloraColors.outline,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: StilloraColors.onSurface,
                      ),
                    ),
                    Text(
                      ratio,
                      style: TextStyle(
                        color: StilloraColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RenderErrorBanner extends StatelessWidget {
  const RenderErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.sm),
      decoration: BoxDecoration(
        color: StilloraColors.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(StilloraRadius.xl),
        border: Border.all(color: StilloraColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: StilloraColors.error),
          const SizedBox(width: StilloraSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: StilloraColors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
