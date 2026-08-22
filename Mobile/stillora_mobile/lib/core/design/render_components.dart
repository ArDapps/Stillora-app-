import 'package:flutter/material.dart';

import 'stillora_colors.dart';
import 'stillora_spacing.dart';

/// Shared visual language for the "render" screens (Create + HTML → Video):
/// numbered step cards, selectable tiles, pill segments and the preview shell.
/// Keeping these in one place lets both flows look identical.
class RenderTokens {
  const RenderTokens._();

  // Now aliases onto the unified StilloraColors palette so the render flows and
  // the rest of the app share one colour language. These are getters, not
  // `static const`/`static final`, so they follow the active light/dark palette
  // instead of freezing whichever one happened to be live at first access.
  static Color get accent => StilloraColors.accent;
  static Color get accentText => StilloraColors.accentText;
  static Color get panel => StilloraColors.panel;
  static Color get panelBorder => StilloraColors.panelBorder;
}

/// A numbered panel: square number badge + title + optional trailing pill, with
/// an optional muted footer line.
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
        color: RenderTokens.panel,
        borderRadius: BorderRadius.circular(StilloraRadius.xl),
        border: Border.all(color: RenderTokens.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RenderNumberBadge(number),
              const SizedBox(width: StilloraSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: StilloraColors.onSurface,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          child,
          if (footer != null) ...[
            const SizedBox(height: StilloraSpacing.sm),
            Text(
              footer!,
              style: TextStyle(
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
        color: RenderTokens.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(StilloraRadius.sm),
        border: Border.all(color: RenderTokens.accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        number,
        style: TextStyle(
          color: RenderTokens.accentText,
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
        border: Border.all(color: RenderTokens.panelBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: StilloraColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// A selectable tile with a check box, title and subtitle — used for output
/// sizes/presets in a two-column grid.
class RenderSelectTile extends StatelessWidget {
  const RenderSelectTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? RenderTokens.accent.withValues(alpha: 0.12)
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
              color: selected ? RenderTokens.accent : RenderTokens.panelBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? RenderTokens.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected
                        ? RenderTokens.accent
                        : StilloraColors.outline,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : (leadingIcon != null
                          ? Icon(
                              leadingIcon,
                              size: 13,
                              color: StilloraColors.outline,
                            )
                          : null),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: StilloraColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: StilloraColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
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

/// Lays selectable tiles into a responsive two-column grid.
class RenderTileGrid extends StatelessWidget {
  const RenderTileGrid({super.key, required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          Padding(
            padding: EdgeInsets.only(
              bottom: i + 2 < tiles.length ? StilloraSpacing.xs : 0,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: StilloraSpacing.xs),
                  Expanded(
                    child: i + 1 < tiles.length
                        ? tiles[i + 1]
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A rounded segmented control with a solid accent active segment.
class RenderPillSegmented extends StatelessWidget {
  const RenderPillSegmented({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.badges,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Optional trailing marker per option (a PRO chip, a "beta" tag, …). Index
  /// aligns with [options]; a null entry — or a shorter/absent list — means no
  /// badge on that chip.
  final List<Widget?>? badges;

  @override
  Widget build(BuildContext context) {
    // Distinct button chips (separated, rounded-rect) rather than a single
    // sliding-pill track — reads as buttons, not a slider. The selected chip
    // carries the solid violet accent; the rest match the charcoal card look.
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: StilloraSpacing.xs),
          Expanded(
            child: _SegChip(
              label: options[i],
              badge: (badges != null && i < badges!.length) ? badges![i] : null,
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _SegChip extends StatelessWidget {
  const _SegChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? RenderTokens.accent
          : StilloraColors.surfaceContainerHigh,
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
              color: selected ? RenderTokens.accent : RenderTokens.panelBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scale the label down rather than ellipsing it. Four chips plus
              // three PRO badges leave very little width on a phone, and
              // "1080p" was rendering as "10…" — a resolution the user cannot
              // read is no more useful than one they cannot see.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? StilloraColors.onAccent
                          : StilloraColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 4), badge!],
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable bordered drop zone (icon + title + hint).
class RenderDropZone extends StatelessWidget {
  const RenderDropZone({
    super.key,
    required this.title,
    required this.hint,
    required this.onTap,
    this.icon = Icons.upload_file_outlined,
  });

  final String title;
  final String hint;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StilloraColors.surfaceDim,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RenderTokens.panelBorder),
          ),
          child: Column(
            children: [
              Icon(icon, size: 30, color: RenderTokens.accent),
              const SizedBox(height: StilloraSpacing.xs),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: StilloraColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: StilloraColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RenderEyebrow extends StatelessWidget {
  const RenderEyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, size: 14, color: RenderTokens.accent),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: RenderTokens.accent,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

/// Diagonal hatch fill used behind empty preview canvases.
class RenderHatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = StilloraColors.onSurface.withValues(alpha: 0.03)
      ..strokeWidth = 8;
    const gap = 26.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
