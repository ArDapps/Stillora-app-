import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_preferences.dart';
import 'app_locale.dart';

/// Holds the active language and writes every change straight to
/// [AppPreferences]. Until the user picks one, Stillora follows the OS locale;
/// after that the explicit choice wins on every launch.
class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    final saved = ref.read(appPreferencesProvider).language;
    if (saved != null) return saved;
    return AppLanguage.fromSystem(
      WidgetsBinding.instance.platformDispatcher.locales,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    state = language;
    await ref.read(appPreferencesProvider).setLanguage(language);
  }
}

final languageControllerProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);
