import 'package:flutter/material.dart';

/// The languages Stillora ships. Arabic drives the app into RTL; the other two
/// stay LTR.
enum AppLanguage {
  english('en', 'English', 'English'),
  arabic('ar', 'العربية', 'Arabic'),
  french('fr', 'Français', 'French');

  const AppLanguage(this.code, this.nativeName, this.englishName);

  /// ISO-639-1 code, also what gets written to preferences.
  final String code;

  /// Endonym — a language list should name each language in that language.
  final String nativeName;

  final String englishName;

  Locale get locale => Locale(code);

  bool get isRtl => this == AppLanguage.arabic;

  /// Typeface for this script. The Latin-first UI font has no Arabic glyphs, so
  /// Arabic falls back to whatever the OS picks — inconsistent across devices
  /// and visually unrelated to the rest of the app. Cairo is bundled for it.
  ///
  /// `Geist` is not bundled; naming it keeps the app on the platform's default
  /// UI font for Latin scripts, which is the behaviour the app shipped with.
  String get fontFamily => this == AppLanguage.arabic ? 'Cairo' : 'Geist';

  static AppLanguage fromCode(String? code) {
    for (final language in AppLanguage.values) {
      if (language.code == code) return language;
    }
    return AppLanguage.english;
  }

  /// Picks the best match for the OS locale list, falling back to English.
  static AppLanguage fromSystem(List<Locale> systemLocales) {
    for (final locale in systemLocales) {
      for (final language in AppLanguage.values) {
        if (language.code == locale.languageCode) return language;
      }
    }
    return AppLanguage.english;
  }
}

const supportedAppLocales = [Locale('en'), Locale('ar'), Locale('fr')];
