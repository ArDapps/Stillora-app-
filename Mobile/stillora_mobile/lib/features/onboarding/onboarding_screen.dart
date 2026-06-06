import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/widgets/stillora_mark.dart';
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

const _slides = [
  _OnboardingSlide(
    icon: Icons.perm_media_rounded,
    title: 'Upload your media',
    body:
        'Pick one or many photos and videos. Drag to reorder them into the perfect sequence.',
    color: Color(0xffd946ef),
  ),
  _OnboardingSlide(
    icon: Icons.timer_rounded,
    title: 'Time each clip',
    body:
        'Set how long the whole video runs, or tap any clip to give it its own duration.',
    color: Color(0xff8b5cf6),
  ),
  _OnboardingSlide(
    icon: Icons.music_note_rounded,
    title: 'Add sound & export',
    body:
        'Drop in an optional soundtrack, choose a format, and export a ready-to-share MP4.',
    color: Color(0xff22d3ee),
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

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish() async {
    await ref.read(appPreferencesProvider).setHasSeenOnboarding(true);
    if (!mounted) {
      return;
    }
    context.go(AppTabsScreen.routePath);
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
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff0c0718), Color(0xff060611), Color(0xff030309)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
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
                    child: const Text('Skip'),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) => _SlideView(
                    slide: _slides[index],
                    showMark: index == 0,
                  ),
                ),
              ),
              const SizedBox(height: StilloraSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
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
                        borderRadius: BorderRadius.circular(StilloraRadius.full),
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
                  label: _isLast ? 'Get started' : 'Next',
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
      padding: const EdgeInsets.symmetric(
        horizontal: StilloraSpacing.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showMark) ...[
            const StilloraMark(size: 56),
            const SizedBox(height: StilloraSpacing.lg),
          ],
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: slide.color.withValues(alpha: 0.4),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(slide.icon, size: 52, color: slide.color),
          ),
          const SizedBox(height: StilloraSpacing.lg),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
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
