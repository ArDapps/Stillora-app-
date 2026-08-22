import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/core/i18n/app_locale.dart';
import 'package:stillora_mobile/features/pro/pro_screen.dart';
import 'package:stillora_mobile/features/tabs/app_tabs_screen.dart';
import 'package:stillora_mobile/main.dart' as app;

/// Captures the navigation drawer, open, in one language.
///
/// Run once per language:
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/drawer_shots_test.dart \
///     --dart-define=SHOT_LANG=ar -d `device-id`
///
/// The PNG lands in `screenshots/drawer-`+code+`.png`. Arabic flips the whole
/// shell to RTL, so its drawer opens from the right — that is correct, not a
/// bug in the capture.
///
/// `pumpAndSettle` is unusable — the brand glow animates forever — so every
/// wait is a fixed number of frames, following `appearance_test.dart`.
const _langCode = String.fromEnvironment('SHOT_LANG', defaultValue: 'en');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final language = AppLanguage.fromCode(_langCode);

  Future<void> settle(WidgetTester tester, [int frames = 8]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('drawer, open, in ${language.englishName}', (tester) async {
    // Seed the language straight into preferences rather than walking the
    // settings UI: the drawer is the subject here, and every extra tap is
    // another thing that can fail differently per locale.
    SharedPreferences.setMockInitialValues({
      'stillora.onboarding.seen': true,
      'stillora.appearance.language': language.code,
    });
    app.main();
    await settle(tester, 30);

    // An automatic paywall would cover the very thing being photographed.
    if (find.byType(ProView).evaluate().isNotEmpty) {
      Navigator.of(tester.element(find.byType(ProView).first)).maybePop();
      await settle(tester, 12);
    }

    expect(
      find.byType(AppNavDrawer),
      findsNothing,
      reason: 'drawer should start closed',
    );

    final menu = find.byIcon(Icons.menu);
    expect(
      menu,
      findsOneWidget,
      reason: 'no hamburger — is this the desktop shell? run on a phone target',
    );
    await tester.tap(menu);
    await settle(tester, 12);

    expect(find.byType(AppNavDrawer), findsOneWidget, reason: 'drawer did not open');

    // Prove the capture is really in the requested language: the drawer's own
    // group headings are localized, so an unswitched app would fail here
    // rather than quietly produce three identical English screenshots.
    final directionality = Directionality.of(
      tester.element(find.byType(AppNavDrawer)),
    );
    debugPrint(
      'DRAWER lang=${language.code} (${language.englishName}) '
      'rtl=${directionality == TextDirection.rtl}',
    );
    expect(
      directionality,
      language.isRtl ? TextDirection.rtl : TextDirection.ltr,
      reason: 'text direction does not match ${language.englishName}',
    );

    try {
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
        await settle(tester, 2);
      }
      await binding.takeScreenshot('drawer-${language.code}');
      debugPrint('DRAWER shot written for ${language.code}');
    } catch (error) {
      debugPrint('DRAWER screenshot failed for ${language.code}: $error');
      rethrow;
    }

    expect(tester.takeException(), isNull);
  });
}
