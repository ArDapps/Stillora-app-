import '../../core/i18n/app_strings.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/app_preferences.dart';
import '../../core/widgets/stillora_mark.dart';
import '../onboarding/onboarding_screen.dart';
import '../pro/paywall_scheduler.dart';
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
    // Captured before the `go()` below, which takes this screen off the stack.
    final router = GoRouter.of(context);
    final seenOnboarding = ref.read(appPreferencesProvider).hasSeenOnboarding;
    context.go(
      seenOnboarding ? AppTabsScreen.routePath : OnboardingScreen.routePath,
    );
    if (!seenOnboarding) {
      // A first run gets exactly one paywall, and OnboardingScreen owns it.
      return;
    }
    unawaited(maybeShowScheduledPaywall(router, ref));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StilloraMark(size: 72),
            const SizedBox(height: 18),
            const Text(
              'Stillora',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(context.strings.splashTagline),
          ],
        ),
      ),
    );
  }
}
