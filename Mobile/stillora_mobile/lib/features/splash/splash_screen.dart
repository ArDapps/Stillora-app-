import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/widgets/stillora_mark.dart';
import '../onboarding/onboarding_screen.dart';
import '../tabs/app_tabs_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const routePath = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    ref.read(authControllerProvider.future);
    if (!mounted) {
      return;
    }
    final seenOnboarding = ref.read(appPreferencesProvider).hasSeenOnboarding;
    context.go(
      seenOnboarding ? AppTabsScreen.routePath : OnboardingScreen.routePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StilloraMark(size: 72),
            SizedBox(height: 18),
            Text(
              'Stillora',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text('Turn images into videos in seconds.'),
          ],
        ),
      ),
    );
  }
}
