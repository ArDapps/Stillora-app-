import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/widgets/stillora_mark.dart';
import '../pro/paywall_scheduler.dart';
import '../tabs/app_tabs_screen.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

// A function rather than a `const`/`final` list: the slide accents come from
// the active palette, and the copy comes from the active language, so both have
// to be rebuilt when either flips.
List<_OnboardingSlide> _buildSlides(AppStrings s) => [
  _OnboardingSlide(
    icon: Icons.perm_media_rounded,
    title: s.obUploadTitle,
    body: s.obUploadBody,
    color: StilloraColors.brandMagenta,
  ),
  _OnboardingSlide(
    icon: Icons.timer_rounded,
    title: s.obTimeTitle,
    body: s.obTimeBody,
    color: StilloraColors.accent,
  ),
  _OnboardingSlide(
    icon: Icons.music_note_rounded,
    title: s.obExportTitle,
    body: s.obExportBody,
    color: StilloraColors.brandCyan,
  ),
];

/// First-launch walkthrough shown once before the Create page. Skippable, and
/// it never appears again after [AppPreferences.setHasSeenOnboarding].
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const routePath = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _buildSlides(context.strings).length - 1;

  Future<void> _finish() async {
    await ref.read(appPreferencesProvider).setHasSeenOnboarding(true);
    if (!mounted) {
      return;
    }
    // Captured before the `go()` below, which takes this screen off the stack.
    final router = GoRouter.of(context);
    context.go(AppTabsScreen.routePath);
    // Pushed on top of Create, so dismissing it lands on the app rather than
    // back here. Fires for Skip and Get started alike — both mean "onboarding
    // is done", which is the moment the offer makes sense.
    unawaited(showPaywallAfterOnboarding(router, ref));
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides(context.strings);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StilloraSpacing.sm,
                    vertical: StilloraSpacing.xs,
                  ),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(context.strings.obSkip),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) =>
                      _SlideView(slide: slides[index], showMark: index == 0),
                ),
              ),
              const SizedBox(height: StilloraSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: i == _page ? stilloraBrandGradient : null,
                        color: i == _page
                            ? null
                            : StilloraColors.outlineVariant,
                        borderRadius: BorderRadius.circular(
                          StilloraRadius.full,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: StilloraSpacing.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  StilloraSpacing.mobileMargin,
                  0,
                  StilloraSpacing.mobileMargin,
                  StilloraSpacing.lg,
                ),
                child: StilloraPrimaryButton(
                  onPressed: _next,
                  icon: _isLast
                      ? Icons.auto_fix_high_rounded
                      : Icons.arrow_forward_rounded,
                  label: _isLast
                      ? context.strings.obGetStarted
                      : context.strings.obNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.showMark});

  final _OnboardingSlide slide;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StilloraSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showMark) ...[
            const StilloraMark(size: 56),
            const SizedBox(height: StilloraSpacing.lg),
          ],
          _AnimatedSlideIcon(icon: slide.icon, color: slide.color),
          const SizedBox(height: StilloraSpacing.lg),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The onboarding slide icon: a halo that breathes continuously, plus a
/// settle-in of the glyph itself.
///
/// The entrance replays whenever the icon changes, because each slide builds a
/// new one — swiping therefore *feels* like arriving somewhere rather than
/// sliding a static card. Both motions are suppressed under
/// `MediaQuery.disableAnimations` (Reduce Motion), which leaves the same
/// composition sitting still rather than a different layout.
class _AnimatedSlideIcon extends StatefulWidget {
  const _AnimatedSlideIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_AnimatedSlideIcon> createState() => _AnimatedSlideIconState();
}

class _AnimatedSlideIconState extends State<_AnimatedSlideIcon>
    with TickerProviderStateMixin {
  /// Never-ending halo pulse.
  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// One-shot entrance: the glyph scales up and fades in.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late final Animation<double> _scale = CurvedAnimation(
    parent: _enter,
    // A touch of overshoot so the glyph lands rather than merely appears.
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _enter,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _halo.repeat(reverse: true);
    _enter.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedSlideIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.icon != widget.icon) _enter.forward(from: 0);
  }

  @override
  void dispose() {
    _halo.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AnimatedBuilder(
      animation: Listenable.merge([_halo, _enter]),
      builder: (context, child) {
        final pulse = still ? 0.5 : _halo.value;
        return Container(
          width: 112,
          height: 112,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.28 + pulse * 0.24),
                blurRadius: 24 + pulse * 22,
                spreadRadius: 1 + pulse * 4,
              ),
            ],
          ),
          child: Transform.scale(
            scale: still ? 1 : 0.72 + _scale.value * 0.28,
            child: Opacity(
              opacity: still ? 1 : _fade.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      // Built once and reused every frame — the glyph itself never changes.
      child: Icon(widget.icon, size: 52, color: widget.color),
    );
  }
}
