import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/app_preferences.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routePath = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.language_rounded),
            title: Text('Language'),
            subtitle: Text('English'),
          ),
          const ListTile(
            leading: Icon(Icons.dark_mode_rounded),
            title: Text('Theme'),
            subtitle: Text('System default'),
          ),
          const ListTile(
            leading: Icon(Icons.timer_rounded),
            title: Text('Default video duration'),
            subtitle: Text('10 seconds'),
          ),
          const ListTile(
            leading: Icon(Icons.aspect_ratio_rounded),
            title: Text('Default video preset'),
            subtitle: Text('Reels'),
          ),
          const ListTile(
            leading: Icon(Icons.fit_screen_rounded),
            title: Text('Default resize mode'),
            subtitle: Text('Fit'),
          ),
          ListTile(
            leading: const Icon(Icons.replay_rounded),
            title: const Text('Replay onboarding'),
            onTap: () async {
              final preferences = await ref.read(
                appPreferencesBootstrapProvider.future,
              );
              await preferences.setOnboardingComplete(false);
              if (context.mounted) {
                context.go(OnboardingScreen.routePath);
              }
            },
          ),
          const ListTile(
            leading: Icon(Icons.cleaning_services_rounded),
            title: Text('Clear temporary files'),
            subtitle: Text('Video engine cleanup will run here.'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_rounded),
            title: Text('Privacy Policy'),
            subtitle: Text(AppConstants.privacyUrl),
          ),
          const ListTile(
            leading: Icon(Icons.description_rounded),
            title: Text('Terms of Service'),
            subtitle: Text(AppConstants.termsUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(LoginScreen.routePath);
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
