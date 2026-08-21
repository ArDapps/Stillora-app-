import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme_controller.dart';
import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';
import '../i18n/app_locale.dart';
import '../i18n/app_strings.dart';
import '../i18n/language_controller.dart';

/// Small caps label used to group the settings list.
class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StilloraSpacing.sm,
        StilloraSpacing.md,
        StilloraSpacing.sm,
        StilloraSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: StilloraColors.accentText,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// One settings row that opens a single-choice sheet.
class SettingsChoiceTile extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: StilloraColors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

/// Shared single-choice bottom sheet used by both the theme and the language
/// rows, so the two settings behave identically.
Future<void> showStilloraChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T) labelOf,
  required IconData Function(T) iconOf,
  required ValueChanged<T> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: StilloraColors.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(StilloraRadius.xl),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StilloraSpacing.md,
              StilloraSpacing.md,
              StilloraSpacing.md,
              StilloraSpacing.xs,
            ),
            child: Text(
              title,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          for (final option in options)
            ListTile(
              leading: Icon(
                iconOf(option),
                color: option == selected
                    ? StilloraColors.accentText
                    : StilloraColors.onSurfaceVariant,
              ),
              title: Text(labelOf(option)),
              trailing: option == selected
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: StilloraColors.accentText,
                    )
                  : null,
              onTap: () {
                onSelected(option);
                Navigator.of(sheetContext).pop();
              },
            ),
          const SizedBox(height: StilloraSpacing.sm),
        ],
      ),
    ),
  );
}

/// Settings row for light / dark / follow-the-system.
class ThemeModeTile extends ConsumerWidget {
  const ThemeModeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);
    final strings = context.strings;

    String label(ThemeMode m) => switch (m) {
      ThemeMode.system => strings.themeSystem,
      ThemeMode.light => strings.themeLight,
      ThemeMode.dark => strings.themeDark,
    };

    return SettingsChoiceTile(
      icon: themeModeIcon(mode),
      title: strings.theme,
      value: label(mode),
      onTap: () => showStilloraChoiceSheet<ThemeMode>(
        context: context,
        title: strings.appearance,
        options: ThemeMode.values,
        selected: mode,
        labelOf: label,
        iconOf: themeModeIcon,
        onSelected: (value) =>
            ref.read(themeModeControllerProvider.notifier).setMode(value),
      ),
    );
  }
}

/// Settings row for the app language. Options are labelled in their own
/// language, which is how a language list stays usable when you can't read the
/// one currently active.
class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageControllerProvider);
    final strings = context.strings;

    return SettingsChoiceTile(
      icon: Icons.language_rounded,
      title: strings.languageLabel,
      value: language.nativeName,
      onTap: () => showStilloraChoiceSheet<AppLanguage>(
        context: context,
        title: strings.languageLabel,
        options: AppLanguage.values,
        selected: language,
        labelOf: (value) => value.nativeName,
        iconOf: (_) => Icons.translate_rounded,
        onSelected: (value) =>
            ref.read(languageControllerProvider.notifier).setLanguage(value),
      ),
    );
  }
}
