import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';

// The animation widgets and the chip picker row live in their own files but
// stay part of this library's public surface for existing importers.
export 'widgets/video_style_animators.dart';
export 'widgets/video_style_picker_row.dart';

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
  String label(AppStrings s) => switch (this) {
    ClipEffect.none => s.fxNone,
    ClipEffect.glow => s.fxGlow,
    ClipEffect.kenBurns => s.fxPanZoom,
    ClipEffect.float => s.fxFloat,
    ClipEffect.shake => s.fxShake,
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
  String label(AppStrings s) => switch (this) {
    FrameTransition.none => s.fxNone,
    FrameTransition.fade => s.trFade,
    FrameTransition.swipe => s.trSwipe,
    FrameTransition.zoom => s.trZoom,
    FrameTransition.slideUp => s.trSlideUp,
    FrameTransition.slideDown => s.trSlideDown,
    FrameTransition.glitch => s.trGlitch,
    FrameTransition.flash => s.trFlash,
    FrameTransition.pulse => s.trPulse,
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

FrameTransition frameTransitionByName(String? name) => FrameTransition.values
    .firstWhere((t) => t.name == name, orElse: () => FrameTransition.none);

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
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    case FrameTransition.slideUp:
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    case FrameTransition.slideDown:
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    case FrameTransition.zoom:
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(
            begin: 0.82,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
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
