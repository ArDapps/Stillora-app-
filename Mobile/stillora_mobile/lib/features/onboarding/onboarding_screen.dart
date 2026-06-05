import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/app_preferences.dart';
import '../../core/widgets/stillora_mark.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const routePath = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.auto_awesome_motion_rounded,
      title: 'Turn images into videos',
      subtitle:
          'Create social-media-ready MP4 videos from your photos in seconds.',
    ),
    _OnboardingPage(
      icon: Icons.crop_rounded,
      title: 'Made for every platform',
      subtitle:
          'Create videos for Reels, TikTok, Stories, YouTube Shorts, square posts, and landscape videos.',
    ),
    _OnboardingPage(
      icon: Icons.graphic_eq_rounded,
      title: 'Bring your image to life',
      subtitle:
          'Add optional audio and generate a video ready to save or share.',
    ),
    _OnboardingPage(
      icon: Icons.lock_rounded,
      title: '100% local processing',
      subtitle: 'Your images, audio files, and videos never leave your phone.',
    ),
    _OnboardingPage(
      icon: Icons.play_circle_rounded,
      title: 'Create your first video',
      subtitle:
          'Select an image and turn it into a video in a few simple steps.',
    ),
  ];

  Future<void> _finish() async {
    final preferences = await ref.read(appPreferencesBootstrapProvider.future);
    await preferences.setOnboardingComplete(true);
    if (mounted) {
      context.go(LoginScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: _index == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => _controller.previousPage(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                ),
              ),
        actions: [
          TextButton(onPressed: _finish, child: const Text('Skip')),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            children: [
              const StilloraMark(size: 48),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) =>
                      _OnboardingPanel(page: _pages[index]),
                ),
              ),
              LinearProgressIndicator(value: (_index + 1) / _pages.length),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: isLast
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                      ),
                icon: Icon(
                  isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                ),
                label: Text(isLast ? 'Get Started' : 'Next'),
              ),
              const SizedBox(height: 8),
              if (isLast)
                OutlinedButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Continue with Google'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(page.icon, size: 92, color: colorScheme.primary),
        const SizedBox(height: 28),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          page.subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
