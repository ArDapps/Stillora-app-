import 'package:flutter/material.dart';

import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';

/// Shared "render" design language (accent + dark panel cards with numbered
/// steps) used by the HTML → Video and Loop images screens so they look alike.
const renderAccent = StilloraColors.accent;
const renderPanel = StilloraColors.panel;
const renderPanelBorder = StilloraColors.panelBorder;

class RenderEyebrow extends StatelessWidget {
  const RenderEyebrow(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome, size: 14, color: renderAccent),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: renderAccent,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class RenderNumberBadge extends StatelessWidget {
  const RenderNumberBadge(this.number, {super.key});
  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: renderAccent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: renderAccent.withValues(alpha: 0.5)),
      ),
      child: Text(
        number,
        style: const TextStyle(
          color: Color(0xffd8c9ff),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class RenderTagPill extends StatelessWidget {
  const RenderTagPill(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: StilloraColors.surfaceDim,
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        border: Border.all(color: renderPanelBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: StilloraColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// Numbered panel: badge + title + optional trailing pill + optional footer.
class RenderStepCard extends StatelessWidget {
  const RenderStepCard({
    super.key,
    required this.number,
    required this.title,
    required this.child,
    this.trailing,
    this.footer,
  });

  final String number;
  final String title;
  final Widget child;
  final Widget? trailing;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.md),
      decoration: BoxDecoration(
        color: renderPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renderPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RenderNumberBadge(number),
              const SizedBox(width: StilloraSpacing.xs),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: StilloraColors.onSurface,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          child,
          if (footer != null) ...[
            const SizedBox(height: StilloraSpacing.sm),
            Text(
              footer!,
              style: const TextStyle(
                color: StilloraColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rounded segmented control with a solid accent active segment.
class RenderPillSegmented extends StatelessWidget {
  const RenderPillSegmented({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // Distinct button chips instead of a sliding-pill track (see the matching
    // RenderPillSegmented in render_components.dart).
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: StilloraSpacing.xs),
          Expanded(
            child: _RenderSegChip(
              label: options[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _RenderSegChip extends StatelessWidget {
  const _RenderSegChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? renderAccent : StilloraColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(StilloraRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StilloraRadius.sm),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StilloraRadius.sm),
            border: Border.all(
              color: selected ? renderAccent : renderPanelBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : StilloraColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

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
      color: selected ? renderAccent.withValues(alpha: 0.12) : StilloraColors.surfaceDim,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? renderAccent : renderPanelBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? renderAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? renderAccent : StilloraColors.outline,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: StilloraColors.onSurface,
                      ),
                    ),
                    Text(
                      ratio,
                      style: const TextStyle(
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
          const Icon(Icons.error_outline_rounded, color: StilloraColors.error),
          const SizedBox(width: StilloraSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: StilloraColors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
