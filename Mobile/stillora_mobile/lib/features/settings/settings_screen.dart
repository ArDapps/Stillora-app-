import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/constants/app_constants.dart';
import '../tabs/app_tabs_screen.dart';

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        'This will permanently delete your account and all associated data. This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(authControllerProvider.notifier).deleteAccount();
    if (context.mounted) {
      // Deleting an account drops the user back to guest mode — they can keep
      // making basic videos without signing in.
      context.go(AppTabsScreen.routePath);
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routePath = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authControllerProvider).asData?.value != null;
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
          if (signedIn) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Account',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppTabsScreen.routePath);
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: OutlinedButton.icon(
                onPressed: () => _confirmDeleteAccount(context, ref),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Delete Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
