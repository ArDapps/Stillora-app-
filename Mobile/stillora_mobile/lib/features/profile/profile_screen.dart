import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/constants/app_constants.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const routePath = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const ProfileView(),
    );
  }
}

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).asData?.value;

    if (session == null) {
      return SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Register when you convert',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse the app freely. Google sign-in is only required before video conversion.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.go(LoginScreen.routePath),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 18),
            const _PolicyLinks(),
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 42,
            child: Text(session.user.name.characters.first),
          ),
          const SizedBox(height: 14),
          Text(
            session.user.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(session.user.email, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const _PolicyLinks(),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go(LoginScreen.routePath);
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class ProfileSettingsButton extends StatelessWidget {
  const ProfileSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_rounded),
      onPressed: () => context.push('/settings'),
    );
  }
}

class _PolicyLinks extends StatelessWidget {
  const _PolicyLinks();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ListTile(
          leading: Icon(Icons.privacy_tip_rounded),
          title: Text('Privacy Policy'),
          subtitle: Text(AppConstants.privacyUrl),
        ),
        ListTile(
          leading: Icon(Icons.description_rounded),
          title: Text('Terms of Service'),
          subtitle: Text(AppConstants.termsUrl),
        ),
      ],
    );
  }
}
