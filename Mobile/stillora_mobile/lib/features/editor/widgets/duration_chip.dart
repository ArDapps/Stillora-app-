import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_glow.dart';
import '../../../core/design/stillora_spacing.dart';

class DurationChip extends StatelessWidget {
  const DurationChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(StilloraRadius.full);
    final textStyle =
        (compact
                ? Theme.of(context).textTheme.labelMedium
                : Theme.of(context).textTheme.labelLarge)
            ?.copyWith(
              color: selected ? Colors.white : StilloraColors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected ? stilloraBrandGradient : null,
            color: selected ? null : StilloraColors.surfaceContainerLow,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.28)
                  : StilloraColors.outlineVariant,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: StilloraColors.accent.withValues(alpha: 0.42),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 7 : 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey('selected'),
                          color: Colors.white,
                          size: compact ? 15 : 18,
                        )
                      : Icon(
                          Icons.radio_button_unchecked_rounded,
                          key: const ValueKey('unselected'),
                          color: StilloraColors.onSurfaceVariant.withValues(
                            alpha: 0.78,
                          ),
                          size: compact ? 15 : 18,
                        ),
                ),
                SizedBox(width: compact ? 5 : 7),
                Text(label, style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
