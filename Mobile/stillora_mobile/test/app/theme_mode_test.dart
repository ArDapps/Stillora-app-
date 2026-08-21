import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/app/theme.dart';
import 'package:stillora_mobile/app/theme_controller.dart';
import 'package:stillora_mobile/core/design/stillora_colors.dart';
import 'package:stillora_mobile/core/storage/app_preferences.dart';
import 'package:stillora_mobile/core/i18n/app_locale.dart';
import 'package:stillora_mobile/core/i18n/app_strings.dart';
import 'package:stillora_mobile/core/i18n/language_controller.dart';
import 'package:stillora_mobile/core/widgets/settings_controls.dart';
import 'package:stillora_mobile/features/compress/compress_screen.dart';
import 'package:stillora_mobile/features/convert/convert_screen.dart';
import 'package:stillora_mobile/features/editor/editor_screen.dart';
import 'package:stillora_mobile/features/gallery/gallery_screen.dart';
import 'package:stillora_mobile/features/html_to_video/html_to_video_screen.dart';
import 'package:stillora_mobile/features/images_to_pdf/images_to_pdf_screen.dart';
import 'package:stillora_mobile/features/loop_images/loop_images_screen.dart';
import 'package:stillora_mobile/core/auth/auth_repository.dart';
import 'package:stillora_mobile/core/auth/session.dart';
import 'package:stillora_mobile/features/settings/settings_screen.dart';
import 'package:stillora_mobile/features/silence/silence_screen.dart';
import 'package:stillora_mobile/features/speed/speed_screen.dart';
import 'package:stillora_mobile/features/text_overlay/text_overlay_screen.dart';
import 'package:stillora_mobile/features/watermark/watermark_screen.dart';

/// Every section of the app, in the order they appear in `AppTabsScreen`.
const _sections = <String, Widget>{
  'Create': EditorView(),
  'Library': GalleryView(),
  'HTML': HtmlToVideoView(),
  'Settings': SettingsView(),
  'Loop images': LoopImagesView(),
  'Remove Silence': SilenceView(),
  'Watermark': WatermarkView(),
  'Speed': SpeedView(),
  'Convert': ConvertView(),
  'Text': TextOverlayView(),
  'Compress': CompressView(),
  'PDF Converter': ImagesToPdfView(),
};

Future<AppPreferences> _prefs([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues({
    'stillora.onboarding.seen': true,
    ...seed,
  });
  return AppPreferences(await SharedPreferences.getInstance());
}

/// Mirrors how `StilloraApp` wires the theme, so the ambient palette is driven
/// exactly as it is in the real app.
Widget _harness({
  required Widget child,
  required ThemeMode mode,
  required AppPreferences preferences,
  AppLanguage language = AppLanguage.english,
}) {
  return ProviderScope(
    overrides: [
      appPreferencesProvider.overrideWithValue(preferences),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
    child: MaterialApp(
      theme: buildStilloraTheme(Brightness.light, language),
      darkTheme: buildStilloraTheme(Brightness.dark, language),
      themeMode: mode,
      locale: language.locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => AppStringsScope(
        strings: AppStrings.of(language),
        child: StilloraPaletteScope(child: child ?? const SizedBox.shrink()),
      ),
      home: Scaffold(body: child),
    ),
  );
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> signInWithGoogle() {
    throw const AuthFailure('Google sign-in is not available in widget tests.');
  }

  @override
  Future<AuthSession> signInWithApple() {
    throw const AuthFailure('Apple sign-in is not available in widget tests.');
  }

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  late Directory hiveDirectory;

  // The Library section opens a Hive box as soon as it builds.
  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('stillora-theme-');
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  group('palette', () {
    test('light and dark define every token distinctly where it matters', () {
      expect(StilloraPalette.light.brightness, Brightness.light);
      expect(StilloraPalette.dark.brightness, Brightness.dark);
      // The surface ladder must actually invert, or "light mode" is a no-op.
      expect(
        StilloraPalette.light.surface.computeLuminance(),
        greaterThan(0.7),
      );
      expect(StilloraPalette.dark.surface.computeLuminance(), lessThan(0.1));
      expect(
        StilloraPalette.light.onSurface.computeLuminance(),
        lessThan(0.1),
      );
      expect(
        StilloraPalette.dark.onSurface.computeLuminance(),
        greaterThan(0.7),
      );
    });

    test('body text clears WCAG AA against its surface in both palettes', () {
      double ratio(Color fg, Color bg) {
        final a = fg.computeLuminance();
        final b = bg.computeLuminance();
        final hi = a > b ? a : b;
        final lo = a > b ? b : a;
        return (hi + 0.05) / (lo + 0.05);
      }

      for (final palette in [StilloraPalette.light, StilloraPalette.dark]) {
        final label = palette.isDark ? 'dark' : 'light';
        expect(
          ratio(palette.onSurface, palette.surface),
          greaterThanOrEqualTo(4.5),
          reason: '$label: onSurface on surface',
        );
        expect(
          ratio(palette.onSurfaceVariant, palette.surface),
          greaterThanOrEqualTo(4.5),
          reason: '$label: onSurfaceVariant on surface',
        );
        expect(
          ratio(palette.onPrimary, palette.primary),
          greaterThanOrEqualTo(4.5),
          reason: '$label: onPrimary on primary',
        );
        expect(
          ratio(palette.accentText, palette.surface),
          greaterThanOrEqualTo(4.5),
          reason: '$label: accentText on surface',
        );
        // primaryContainer is a mid-violet in the dark palette; no foreground
        // can reach 4.5:1 against it (white tops out at ~3.9). It carries chip
        // and nav-indicator labels, so the 3:1 UI-component bar is the right
        // one here.
        expect(
          ratio(palette.onPrimaryContainer, palette.primaryContainer),
          greaterThanOrEqualTo(3.0),
          reason: '$label: onPrimaryContainer on primaryContainer',
        );
      }
    });
  });

  group('theme mode preference', () {
    test('defaults to system and round-trips each mode', () async {
      final preferences = await _prefs();
      expect(preferences.themeMode, ThemeMode.system);

      for (final mode in ThemeMode.values) {
        await preferences.setThemeMode(mode);
        expect(preferences.themeMode, mode);
      }
    });

    test('a persisted choice is restored on the next launch', () async {
      final preferences = await _prefs({
        'stillora.appearance.themeMode': 'light',
      });
      expect(preferences.themeMode, ThemeMode.light);

      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      expect(container.read(themeModeControllerProvider), ThemeMode.light);
    });
  });

  group('StilloraPaletteScope', () {
    testWidgets('activates the palette matching the resolved brightness', (
      tester,
    ) async {
      final preferences = await _prefs();

      await tester.pumpWidget(
        _harness(
          child: const SizedBox.shrink(),
          mode: ThemeMode.light,
          preferences: preferences,
        ),
      );
      await tester.pumpAndSettle();
      expect(StilloraColors.active.brightness, Brightness.light);
      expect(StilloraColors.surface, StilloraPalette.light.surface);

      await tester.pumpWidget(
        _harness(
          child: const SizedBox.shrink(),
          mode: ThemeMode.dark,
          preferences: preferences,
        ),
      );
      await tester.pumpAndSettle();
      expect(StilloraColors.active.brightness, Brightness.dark);
      expect(StilloraColors.surface, StilloraPalette.dark.surface);
    });

    testWidgets('the settings row picks a mode and persists it', (
      tester,
    ) async {
      final preferences = await _prefs();

      await tester.pumpWidget(
        _harness(
          child: const ThemeModeTile(),
          mode: ThemeMode.dark,
          preferences: preferences,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ThemeModeTile));
      await tester.pumpAndSettle();

      // The sheet offers all three modes; pick Light. (The tile's own subtitle
      // also renders the current mode, hence findsWidgets.)
      expect(find.text('System default'), findsWidgets);
      expect(find.text('Dark'), findsWidgets);
      expect(find.text('Light'), findsWidgets);
      await tester.tap(find.text('Light').last);
      await tester.pumpAndSettle();

      expect(preferences.themeMode, ThemeMode.light);
    });
  });

  group('language', () {
    test('defaults to the OS language and round-trips each choice', () async {
      final preferences = await _prefs();
      expect(preferences.language, isNull); // nothing chosen yet

      for (final language in AppLanguage.values) {
        await preferences.setLanguage(language);
        expect(preferences.language, language);
      }
    });

    test('every key is translated in every language', () {
      // English is the fallback, so a missing key silently reads as English
      // rather than failing loudly — check the catalogues match instead.
      final english = AppStrings.of(AppLanguage.english);
      for (final language in AppLanguage.values) {
        if (language == AppLanguage.english) continue;
        final translated = AppStrings.of(language);
        for (final entry in <String, String Function(AppStrings)>{
          'create': (s) => s.create,
          'library': (s) => s.library,
          'settings': (s) => s.settings,
          'loopImages': (s) => s.loopImages,
          'removeSilence': (s) => s.removeSilence,
          'watermark': (s) => s.watermark,
          'speed': (s) => s.speed,
          'convert': (s) => s.convert,
          'text': (s) => s.text,
          'compress': (s) => s.compress,
          'pdfConverter': (s) => s.pdfConverter,
          'appearance': (s) => s.appearance,
          'theme': (s) => s.theme,
          'themeSystem': (s) => s.themeSystem,
          'themeLight': (s) => s.themeLight,
          'themeDark': (s) => s.themeDark,
          'language': (s) => s.languageLabel,
          'about': (s) => s.about,
          'privacyPolicy': (s) => s.privacyPolicy,
          'termsOfService': (s) => s.termsOfService,
          'appTagline': (s) => s.appTagline,
          'filesStayOnDevice': (s) => s.filesStayOnDevice,
        }.entries) {
          expect(
            entry.value(translated),
            isNot(equals(entry.value(english))),
            reason: '${language.code}: "${entry.key}" is still English',
          );
        }
      }
    });

    test('Arabic uses the bundled Cairo face, others the default UI font', () {
      expect(AppLanguage.arabic.fontFamily, 'Cairo');
      expect(AppLanguage.english.fontFamily, 'Geist');
      expect(AppLanguage.french.fontFamily, 'Geist');

      // The theme has to carry it through, or the font is declared but unused.
      expect(
        buildStilloraTheme(Brightness.dark, AppLanguage.arabic).textTheme
            .bodyMedium
            ?.fontFamily,
        'Cairo',
      );
      expect(
        buildStilloraTheme(Brightness.light, AppLanguage.english).textTheme
            .bodyMedium
            ?.fontFamily,
        'Geist',
      );
    });

    testWidgets('Arabic drives the app into RTL', (tester) async {
      final preferences = await _prefs();
      await tester.pumpWidget(
        _harness(
          child: const SizedBox.shrink(),
          mode: ThemeMode.dark,
          preferences: preferences,
          language: AppLanguage.arabic,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(SizedBox).first)),
        TextDirection.rtl,
      );
    });

    testWidgets('the settings row switches language and persists it', (
      tester,
    ) async {
      final preferences = await _prefs();
      await tester.pumpWidget(
        _harness(
          child: const LanguageTile(),
          mode: ThemeMode.dark,
          preferences: preferences,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LanguageTile));
      await tester.pumpAndSettle();

      // Options are labelled with their endonyms.
      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(preferences.language, AppLanguage.french);
    });

    testWidgets('the language controller restores a saved choice', (
      tester,
    ) async {
      final preferences = await _prefs({
        'stillora.appearance.language': 'ar',
      });
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      expect(container.read(languageControllerProvider), AppLanguage.arabic);
    });
  });

  group('sections render in both palettes', () {
    for (final entry in _sections.entries) {
      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        final label = mode == ThemeMode.dark ? 'dark' : 'light';
        testWidgets('${entry.key} renders in $label mode', (tester) async {
          // A real phone surface, and iOS so the native-engine sections build
          // the same widget tree they do on the device.
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          try {
            final preferences = await _prefs();
            // runAsync lets the ad slot's network call settle so no timer is
            // left pending at teardown (same trick as desktop_sidebar_test).
            await tester.runAsync(() async {
              await tester.pumpWidget(
                _harness(
                  child: entry.value,
                  mode: mode,
                  preferences: preferences,
                ),
              );
            });
            await tester.pump();

            expect(tester.takeException(), isNull);
            // The section painted against the palette under test.
            expect(
              StilloraColors.active.brightness,
              mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
            );
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
  });
}
