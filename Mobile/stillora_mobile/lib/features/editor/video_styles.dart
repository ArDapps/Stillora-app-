import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/stillora_colors.dart';

/// Continuous animation applied to a clip/layer in the preview. Shared by the
/// Create editor and the Reel section. Preview-only — the export engine does not
/// render these yet.
enum ClipEffect { none, glow, kenBurns, float, shake }

/// Looping full-frame transition that periodically sweeps the whole preview.
/// `fade` is baked into export; the rest are preview-only (the native/FFmpeg
/// compositors fall back to no transition for names they don't render).
enum FrameTransition {
  none,
  fade,
  swipe,
  zoom,
  slideUp,
  slideDown,
  glitch,
  flash,
  pulse,
}

extension ClipEffectMeta on ClipEffect {
  String get label => switch (this) {
    ClipEffect.none => 'None',
    ClipEffect.glow => 'Glow',
    ClipEffect.kenBurns => 'Pan & Zoom',
    ClipEffect.float => 'Float',
    ClipEffect.shake => 'Shake',
  };

  IconData get icon => switch (this) {
    ClipEffect.none => Icons.block_rounded,
    ClipEffect.glow => Icons.blur_on_rounded,
    ClipEffect.kenBurns => Icons.zoom_out_map_rounded,
    ClipEffect.float => Icons.waves_rounded,
    ClipEffect.shake => Icons.vibration_rounded,
  };
}

extension FrameTransitionMeta on FrameTransition {
  String get label => switch (this) {
    FrameTransition.none => 'None',
    FrameTransition.fade => 'Fade',
    FrameTransition.swipe => 'Swipe',
    FrameTransition.zoom => 'Zoom',
    FrameTransition.slideUp => 'Slide Up',
    FrameTransition.slideDown => 'Slide Down',
    FrameTransition.glitch => 'Glitch',
    FrameTransition.flash => 'Flash',
    FrameTransition.pulse => 'Pulse',
  };

  IconData get icon => switch (this) {
    FrameTransition.none => Icons.block_rounded,
    FrameTransition.fade => Icons.gradient_rounded,
    FrameTransition.swipe => Icons.swipe_rounded,
    FrameTransition.zoom => Icons.center_focus_strong_rounded,
    FrameTransition.slideUp => Icons.north_rounded,
    FrameTransition.slideDown => Icons.south_rounded,
    FrameTransition.glitch => Icons.grain_rounded,
    FrameTransition.flash => Icons.flash_on_rounded,
    FrameTransition.pulse => Icons.graphic_eq_rounded,
  };
}

ClipEffect clipEffectByName(String? name) => ClipEffect.values.firstWhere(
  (e) => e.name == name,
  orElse: () => ClipEffect.none,
);

FrameTransition frameTransitionByName(String? name) =>
    FrameTransition.values.firstWhere(
      (t) => t.name == name,
      orElse: () => FrameTransition.none,
    );

/// How long the crossfade/slide between two consecutive clips runs. `none` is a
/// hard cut, so it uses a near-zero duration.
Duration frameTransitionDuration(FrameTransition transition) =>
    transition == FrameTransition.none
        ? const Duration(milliseconds: 1)
        : const Duration(milliseconds: 650);

/// Builds the [AnimatedSwitcher.transitionBuilder] that animates the handoff
/// from one clip/asset to the next. Unlike [TransitionAnimator] (a looping
/// full-frame overlay on a single clip), this drives the actual asset-to-asset
/// transition in a slideshow. [animation] runs 0→1 for the incoming clip and
/// 1→0 for the outgoing one.
Widget frameTransitionBuilder(
  FrameTransition transition,
  Widget child,
  Animation<double> animation,
) {
  switch (transition) {
    case FrameTransition.none:
    case FrameTransition.fade:
      return FadeTransition(opacity: animation, child: child);
    case FrameTransition.swipe:
      return SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(animation),
        child: child,
      );
    case FrameTransition.slideUp:
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(animation),
        child: child,
      );
    case FrameTransition.slideDown:
      return SlideTransition(
        position: Tween(begin: const Offset(0, -1), end: Offset.zero)
            .animate(animation),
        child: child,
      );
    case FrameTransition.zoom:
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.82, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    case FrameTransition.pulse:
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 1.12, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    case FrameTransition.glitch:
      // Fade in with a decaying horizontal jitter.
      return FadeTransition(
        opacity: animation,
        child: AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, c) {
            final v = animation.value;
            final dx = math.sin(v * math.pi * 8) * 6 * (1 - v);
            return Transform.translate(offset: Offset(dx, 0), child: c);
          },
        ),
      );
    case FrameTransition.flash:
      // Fade in under a white flash that fades out on the incoming clip.
      return FadeTransition(
        opacity: animation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            IgnorePointer(
              child: FadeTransition(
                opacity: Tween(begin: 0.6, end: 0.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: const ColoredBox(color: Colors.white),
              ),
            ),
          ],
        ),
      );
  }
}

/// A named one-tap look that bundles an [effect] + [transition], used by the
/// Reel section's "Styles" row.
class ReelStyle {
  const ReelStyle({
    required this.id,
    required this.label,
    required this.effect,
    required this.transition,
  });

  final String id;
  final String label;
  final ClipEffect effect;
  final FrameTransition transition;
}

const reelStyles = [
  ReelStyle(
    id: 'clean',
    label: 'Clean',
    effect: ClipEffect.none,
    transition: FrameTransition.none,
  ),
  ReelStyle(
    id: 'neon',
    label: 'Neon',
    effect: ClipEffect.glow,
    transition: FrameTransition.fade,
  ),
  ReelStyle(
    id: 'cinematic',
    label: 'Cinematic',
    effect: ClipEffect.kenBurns,
    transition: FrameTransition.fade,
  ),
  ReelStyle(
    id: 'dreamy',
    label: 'Dreamy',
    effect: ClipEffect.float,
    transition: FrameTransition.zoom,
  ),
  ReelStyle(
    id: 'energetic',
    label: 'Energetic',
    effect: ClipEffect.shake,
    transition: FrameTransition.swipe,
  ),
];

/// Wraps [child] with the selected [effect] and [transition] animations.
/// Effects transform/decorate the media; transitions overlay a looping sweep on
/// top, so the two compose cleanly.
class StyledMedia extends StatelessWidget {
  const StyledMedia({
    super.key,
    required this.effect,
    required this.transition,
    required this.child,
  });

  final ClipEffect effect;
  final FrameTransition transition;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TransitionAnimator(
      transition: transition,
      child: EffectAnimator(effect: effect, child: child),
    );
  }
}

class EffectAnimator extends StatefulWidget {
  const EffectAnimator({super.key, required this.effect, required this.child});

  final ClipEffect effect;
  final Widget child;

  @override
  State<EffectAnimator> createState() => _EffectAnimatorState();
}

class _EffectAnimatorState extends State<EffectAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _durationFor(widget.effect),
  );

  static Duration _durationFor(ClipEffect effect) => switch (effect) {
    ClipEffect.kenBurns => const Duration(seconds: 12),
    ClipEffect.glow => const Duration(seconds: 2),
    ClipEffect.float => const Duration(seconds: 3),
    ClipEffect.shake => const Duration(milliseconds: 600),
    ClipEffect.none => const Duration(seconds: 1),
  };

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant EffectAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect != widget.effect) {
      _controller.duration = _durationFor(widget.effect);
      _restart();
    }
  }

  void _restart() {
    _controller.reset();
    if (widget.effect != ClipEffect.none) {
      _controller.repeat(reverse: widget.effect == ClipEffect.kenBurns);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effect == ClipEffect.none) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _apply(_controller.value, child!),
      child: widget.child,
    );
  }

  Widget _apply(double t, Widget child) {
    switch (widget.effect) {
      case ClipEffect.none:
        return child;
      case ClipEffect.glow:
        final pulse = (math.sin(t * 2 * math.pi) + 1) / 2; // 0..1
        // Soft, bloomed lavender border to match the export compositor.
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: StilloraColors.primary
                        .withValues(alpha: 0.45 + 0.5 * pulse),
                    width: 3 + 5 * pulse,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: StilloraColors.primary
                          .withValues(alpha: 0.3 + 0.4 * pulse),
                      blurRadius: 10 + 16 * pulse,
                      spreadRadius: 1 + 3 * pulse,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case ClipEffect.kenBurns:
        // Centred zoom to match the export compositor.
        final scale = 1.0 + 0.14 * t;
        return ClipRect(child: Transform.scale(scale: scale, child: child));
      case ClipEffect.float:
        final dy = math.sin(t * 2 * math.pi) * 8;
        return Transform.translate(offset: Offset(0, dy), child: child);
      case ClipEffect.shake:
        final dx = math.sin(t * 2 * math.pi) * 4;
        final angle = math.sin(t * 2 * math.pi) * 0.012;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(angle: angle, child: child),
        );
    }
  }
}

class TransitionAnimator extends StatefulWidget {
  const TransitionAnimator({
    super.key,
    required this.transition,
    required this.child,
  });

  final FrameTransition transition;
  final Widget child;

  @override
  State<TransitionAnimator> createState() => _TransitionAnimatorState();
}

class _TransitionAnimatorState extends State<TransitionAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant TransitionAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transition != widget.transition) _restart();
  }

  void _restart() {
    _controller.reset();
    if (widget.transition != FrameTransition.none) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transition == FrameTransition.none) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) =>
              IgnorePointer(child: _overlay(_controller.value)),
        ),
      ],
    );
  }

  Widget _overlay(double t) {
    switch (widget.transition) {
      case FrameTransition.none:
        return const SizedBox.shrink();
      case FrameTransition.fade:
        // A brief dip to black near the end of each cycle.
        final phase = t < 0.85 ? 0.0 : (t - 0.85) / 0.15;
        final opacity = math.sin(phase * math.pi) * 0.65;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: const ColoredBox(color: Colors.black),
        );
      case FrameTransition.swipe:
        // A soft vertical white bar sweeping across (matches the export).
        return Align(
          alignment: Alignment(-1.3 + 2.6 * t, 0),
          child: FractionallySizedBox(
            widthFactor: 0.25,
            heightFactor: 1,
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.22)),
          ),
        );
      case FrameTransition.zoom:
        // A brief white flash near the end of each cycle (matches the export).
        final phase = t < 0.8 ? 0.0 : (t - 0.8) / 0.2;
        if (phase == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: (1 - phase) * 0.4,
          child: const ColoredBox(color: Colors.white),
        );
      case FrameTransition.slideUp:
        // A soft highlight bar sweeping from bottom to top.
        return Align(
          alignment: Alignment(0, 1.3 - 2.6 * t),
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: 0.25,
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.22)),
          ),
        );
      case FrameTransition.slideDown:
        // A soft highlight bar sweeping from top to bottom.
        return Align(
          alignment: Alignment(0, -1.3 + 2.6 * t),
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: 0.25,
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.22)),
          ),
        );
      case FrameTransition.glitch:
        // Rapid RGB-split slice flicker several times per cycle.
        final active = (t * 6) % 1 < 0.25;
        if (!active) return const SizedBox.shrink();
        final shift = (t * 37) % 1;
        return Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment(-0.15, -1 + 2 * shift),
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.08,
                child: ColoredBox(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                ),
              ),
            ),
            Align(
              alignment: Alignment(0.15, -1 + 2 * ((shift + 0.5) % 1)),
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.06,
                child: ColoredBox(
                  color: const Color(0xFFFF1744).withValues(alpha: 0.30),
                ),
              ),
            ),
          ],
        );
      case FrameTransition.flash:
        // A full-frame white strobe pulsing a few times per cycle.
        final strobe = math.sin(t * 2 * math.pi * 3);
        final opacity = strobe > 0.7 ? (strobe - 0.7) / 0.3 * 0.5 : 0.0;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: const ColoredBox(color: Colors.white),
        );
      case FrameTransition.pulse:
        // A soft breathing vignette around the frame edges.
        final p = (math.sin(t * 2 * math.pi) + 1) / 2;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.0,
              stops: const [0.6, 1.0],
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.15 + 0.25 * p),
              ],
            ),
          ),
        );
    }
  }
}

/// Horizontal chip selector shared by both sections for picking an effect or
/// transition. [values] are rendered as labelled icon chips.
class StylePickerRow<T> extends StatelessWidget {
  const StylePickerRow({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.iconOf,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final IconData Function(T) iconOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final value in values) ...[
                _Chip(
                  label: labelOf(value),
                  icon: iconOf(value),
                  selected: value == selected,
                  onTap: () => onSelected(value),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : StilloraColors.onSurfaceVariant;
    return Material(
      color: selected
          ? StilloraColors.primary.withValues(alpha: 0.9)
          : StilloraColors.surfaceContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
