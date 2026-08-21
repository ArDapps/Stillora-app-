import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/widgets/desktop_shell.dart';
import '../../core/widgets/settings_controls.dart';
import '../profile/profile_screen.dart';
import '../tabs/app_tabs_screen.dart';

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final strings = context.strings;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(strings.deleteAccountTitle),
      content: Text(strings.deleteAccountBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(strings.delete),
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

/// Route wrapper. Settings is also a home tab ([SettingsView]); this keeps the
/// `/settings` deep link working and gives the desktop shell a titled page.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routePath = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SidebarScaffold(
      desktopTitle: context.strings.settings,
      appBar: AppBar(title: Text(context.strings.settings)),
      body: const SettingsView(),
    );
  }
}

/// The Settings tab. Holds appearance, language, defaults, storage and the
/// About block that used to be its own "Info" tab.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final signedIn = ref.watch(authControllerProvider).asData?.value != null;
    final preferences = ref.watch(appPreferencesProvider);

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          // Same cap the About block uses, so the page reads as one tidy
          // column on wide desktop windows instead of stretching.
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            children: [
              SettingsSectionLabel(strings.appearance),
              const ThemeModeTile(),
              const LanguageTile(),

              SettingsSectionLabel(strings.defaults),
              ListTile(
                leading: const Icon(Icons.timer_rounded),
                title: Text(strings.defaultDuration),
                subtitle: Text(
                  strings.secondsValue(preferences.defaultDurationSeconds),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.aspect_ratio_rounded),
                title: Text(strings.defaultPreset),
                subtitle: Text(preferences.defaultPresetId),
              ),
              ListTile(
                leading: const Icon(Icons.fit_screen_rounded),
                title: Text(strings.defaultResizeMode),
                subtitle: Text(preferences.defaultResizeMode),
              ),

              SettingsSectionLabel(strings.storage),
              ListTile(
                leading: const Icon(Icons.cleaning_services_rounded),
                title: Text(strings.clearTempFiles),
                subtitle: Text(strings.clearTempFilesSubtitle),
              ),

              SettingsSectionLabel(strings.about),
              const AboutStilloraBlock(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_rounded),
                title: Text(strings.privacyPolicy),
                subtitle: const Text(AppConstants.privacyUrl),
              ),
              ListTile(
                leading: const Icon(Icons.description_rounded),
                title: Text(strings.termsOfService),
                subtitle: const Text(AppConstants.termsUrl),
              ),

              if (signedIn) ...[
                SettingsSectionLabel(strings.account),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StilloraSpacing.sm,
                    StilloraSpacing.base,
                    StilloraSpacing.sm,
                    StilloraSpacing.xs,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go(AppTabsScreen.routePath);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(strings.logout),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StilloraSpacing.sm,
                    0,
                    StilloraSpacing.sm,
                    StilloraSpacing.md,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeleteAccount(context, ref),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: Text(strings.deleteAccount),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: StilloraSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
