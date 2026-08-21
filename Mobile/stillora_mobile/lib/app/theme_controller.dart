import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/app_preferences.dart';

/// Holds the user's light/dark preference and writes it straight through to
/// [AppPreferences], so the choice survives a restart. Seeded synchronously
/// from prefs (they are already loaded in `main()`), which means the very first
/// frame paints in the right mode — no flash of the wrong theme.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(appPreferencesProvider).themeMode;

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await ref.read(appPreferencesProvider).setThemeMode(mode);
  }

  /// Convenience for a single-tap toggle: flips between light and dark,
  /// resolving `system` against whatever the OS is currently showing.
  Future<void> toggle(Brightness current) =>
      setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Human-readable label for the settings row.
String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'System default',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};

IconData themeModeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.system => Icons.brightness_auto_rounded,
  ThemeMode.light => Icons.light_mode_rounded,
  ThemeMode.dark => Icons.dark_mode_rounded,
};
