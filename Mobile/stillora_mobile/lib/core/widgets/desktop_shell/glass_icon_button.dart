import 'package:flutter/material.dart';

import '../../design/stillora_colors.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    // Opaque fill + a full-strength outline rather than a translucent one. In
    // the light palette a 60%-alpha surfaceContainer over the shell gradient
    // landed within a couple of percent of the backdrop, so the collapse/expand
    // control was effectively invisible until you hovered it.
    //
    // On a control this small the *ring* is what carries the shape — the fill
    // can only ever be a hair different from the page behind it (~1.2:1 in
    // light), so the border does the work and uses `outline` undiluted, which
    // clears 3:1 against the surface in both palettes.
    final button = Material(
      color: StilloraColors.surfaceContainerHigh,
      shape: CircleBorder(
        side: BorderSide(color: StilloraColors.outline, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: StilloraColors.onSurface),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}
