import 'package:flutter/material.dart';

import 'stillora_colors.dart';
import 'stillora_spacing.dart';

/// Brand gradient used across glowing surfaces (magenta -> violet -> cyan),
/// matching the Stillora promo art.
const stilloraBrandGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xffd946ef), Color(0xff8b5cf6), Color(0xff22d3ee)],
);

const _glowMagenta = Color(0xffd946ef);
const _glowViolet = Color(0xff8b5cf6);
const _glowCyan = Color(0xff22d3ee);

/// Drives a looping 0..1 pulse and rebuilds [builder] each frame. Used by all
/// the glowing components so the brand glow breathes consistently.
class StilloraPulse extends StatefulWidget {
  const StilloraPulse({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 1900),
  });

  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;

  @override
  State<StilloraPulse> createState() => _StilloraPulseState();
}

class _StilloraPulseState extends State<StilloraPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);
  late final Animation<double> _pulse = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => widget.builder(context, _pulse.value),
    );
  }
}

/// Primary call-to-action with a gradient fill and an animated brand glow.
class StilloraGlowButton extends StatelessWidget {
  const StilloraGlowButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return StilloraPulse(
      builder: (context, t) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: _glowMagenta.withValues(alpha: 0.25 + t * 0.25),
                      blurRadius: 18 + t * 16,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: _glowCyan.withValues(alpha: 0.20 + t * 0.22),
                      blurRadius: 24 + t * 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(StilloraRadius.full),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: enabled ? stilloraBrandGradient : null,
                  color: enabled ? null : StilloraColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(StilloraRadius.full),
                ),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: enabled
                            ? Colors.white
                            : StilloraColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: StilloraSpacing.xs),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? Colors.white
                              : StilloraColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Card with an animated glowing gradient border, like the framed panel in the
/// promo art.
class StilloraGlowCard extends StatelessWidget {
  const StilloraGlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(StilloraSpacing.sm),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return StilloraPulse(
      builder: (context, t) {
        return Container(
          decoration: BoxDecoration(
            gradient: stilloraBrandGradient,
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            boxShadow: [
              BoxShadow(
                color: _glowViolet.withValues(alpha: 0.18 + t * 0.22),
                blurRadius: 16 + t * 16,
              ),
              BoxShadow(
                color: _glowCyan.withValues(alpha: 0.12 + t * 0.18),
                blurRadius: 22 + t * 18,
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: StilloraColors.surfaceContainer.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(StilloraRadius.full - 1.5),
            ),
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}
