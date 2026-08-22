import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_gate.dart';
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
              SettingsSectionLabel(strings.yourPlan),
              const PlanBlock(),

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

/// "Your plan" — what the tier you are actually on gives you.
///
/// Free is a complete toolkit, not a trial, but nothing outside the paywall
/// ever said so: a user who dismissed the upsell had no way to check what they
/// still had. This lists the Free inclusions plainly — sponsored content
/// included, marked as what it is rather than dressed up as a feature — so the
/// picture is honest in both directions.
class PlanBlock extends ConsumerWidget {
  const PlanBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final text = Theme.of(context).textTheme;
    final isPro = ref.watch(isProProvider);

    // (icon, label, isBenefit) — ads are part of the Free deal but are not a
    // perk, so they do not get a tick.
    final includes = <(IconData, String, bool)>[
      (Icons.check_circle_rounded, strings.planIncludesTools, true),
      (Icons.check_circle_rounded, strings.planIncludesQuality, true),
      (Icons.check_circle_rounded, strings.planIncludesNoWatermark, true),
      (Icons.check_circle_rounded, strings.planIncludesLocal, true),
      (Icons.campaign_rounded, strings.planIncludesAds, false),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StilloraSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(StilloraSpacing.sm),
        decoration: BoxDecoration(
          color: StilloraColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(StilloraRadius.card),
          border: Border.all(color: StilloraColors.glassStroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPro
                      ? Icons.workspace_premium_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isPro
                      ? StilloraColors.brandCyan
                      : StilloraColors.accentText,
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: Text(
                    isPro ? strings.planPro : strings.planFree,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isPro) const ProBadge(),
              ],
            ),
            const SizedBox(height: StilloraSpacing.base + 2),
            Text(
              isPro ? strings.planProBody : strings.planFreeBody,
              style: text.bodyMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            if (!isPro) ...[
              const SizedBox(height: StilloraSpacing.xs),
              for (final (icon, label, benefit) in includes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        icon,
                        size: 17,
                        color: benefit
                            ? StilloraColors.secondary
                            : StilloraColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: StilloraSpacing.base + 2),
                      Expanded(
                        child: Text(label, style: text.bodyMedium),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: StilloraSpacing.base),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => openProUpgrade(context),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: Text(strings.planSeePro),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
