import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
