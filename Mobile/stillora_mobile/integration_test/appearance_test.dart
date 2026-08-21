import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/core/i18n/app_locale.dart';
import 'package:stillora_mobile/core/widgets/desktop_shell.dart';
import 'package:stillora_mobile/main.dart' as app;

/// Walks the real app on a device: opens every section, switches theme and
/// language, and screenshots the key states.
///
/// Runs against both shells — the phone drawer and the desktop sidebar — so one
/// suite covers `-d <simulator>` and `-d macos`.
///
/// Note: `pumpAndSettle` is unusable here — the brand glow (`StilloraPulse`)
/// repeats forever, so the tree never goes quiet. Every wait below is a fixed
/// number of frames instead.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester, [int frames = 8]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// True when the desktop sidebar shell is on screen rather than the phone
  /// drawer.
  bool isDesktopShell() => find.byType(DesktopSidebar).evaluate().isNotEmpty;

  Future<void> shot(WidgetTester tester, String name) async {
    try {
      // Android needs the surface converted first; iOS screenshots directly.
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
        await settle(tester, 2);
      }
      await binding.takeScreenshot(name);
    } catch (error) {
      // Screenshots aren't supported on every platform (desktop in
      // particular). The functional assertions are the real check.
      debugPrint('screenshot "$name" skipped: $error');
    }
  }

  /// Taps a label, scrolling it into its scrollable's viewport first.
  ///
  /// A finder matching isn't enough, and neither is being inside the screen: a
  /// `ListView` keeps items just past the fold in the tree, and those sit
  /// *inside the screen* but *outside the clipped viewport*, so the tap lands on
  /// whatever is painted there instead. Compare against the viewport rect.
  ///
  /// [within] scopes both the search and the scrolling to one subtree — needed
  /// on desktop, where the sidebar and the page content are both scrollable and
  /// may hold the same word.
  Future<void> tapText(
    WidgetTester tester,
    String label, {
    Finder? within,
  }) async {
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    Finder target() => within == null
        ? find.text(label)
        : find.descendant(of: within, matching: find.text(label));

    Finder scroller() {
      if (within != null) {
        final scoped = find.descendant(
          of: within,
          matching: find.byType(Scrollable),
        );
        if (scoped.evaluate().isNotEmpty) return scoped.first;
      }
      if (find.byType(Drawer).evaluate().isNotEmpty) {
        return find
            .descendant(
              of: find.byType(Drawer),
              matching: find.byType(Scrollable),
            )
            .first;
      }
      return find.byType(Scrollable).last;
    }

    for (var attempt = 0; attempt < 14; attempt++) {
      final finder = target();
      final scrollable = scroller();
      final bounds = scrollable.evaluate().isNotEmpty
          ? tester.getRect(scrollable)
          : Offset.zero & screen;

      // Scroll toward the target rather than always downward: the desktop
      // sidebar keeps its offset between sections, so after reaching Settings
      // at the bottom, Create is *above* the viewport and scrolling further
      // down would never reach it.
      var delta = -220.0;
      if (finder.evaluate().isNotEmpty) {
        final rect = tester.getRect(finder.last);
        if (rect.top >= bounds.top && rect.bottom <= bounds.bottom) {
          await tester.tap(finder.last);
          await settle(tester);
          return;
        }
        if (rect.top < bounds.top) delta = 220.0;
      }
      if (scrollable.evaluate().isEmpty) break;
      await tester.drag(scrollable, Offset(0, delta));
      await settle(tester, 4);
    }
    fail('could not bring "$label" into view to tap it');
  }

  Future<void> goToSection(WidgetTester tester, String label) async {
    if (isDesktopShell()) {
      // The sidebar is always visible; tap the nav item directly, scoped so a
      // matching word in the page body can't win.
      await tapText(tester, label, within: find.byType(DesktopSidebar));
      return;
    }
    await tester.tap(find.byIcon(Icons.menu));
    await settle(tester);
    await tapText(tester, label);
  }

  /// Opens a settings choice row and picks an option from its sheet.
  Future<void> choose(WidgetTester tester, String row, String option) async {
    await tapText(tester, row);
    await tapText(tester, option);
  }

  testWidgets('every section opens, in both themes and three languages', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'stillora.onboarding.seen': true});
    app.main();
    await settle(tester, 30);

    final desktop = isDesktopShell();
    debugPrint('SHELL: ${desktop ? "desktop sidebar" : "phone drawer"}');
    if (!desktop) expect(find.byIcon(Icons.menu), findsOneWidget);
    await shot(tester, '01-create-default');

    // Settings replaced the old Info tab.
    await goToSection(tester, 'Settings');
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    await shot(tester, '02-settings-system-theme');

    // Dark.
    await choose(tester, 'Theme', 'Dark');
    expect(tester.takeException(), isNull);
    await shot(tester, '03-settings-dark');

    // French.
    await choose(tester, 'Language', AppLanguage.french.nativeName);
    expect(find.text('Paramètres'), findsWidgets);
    await shot(tester, '04-settings-french');

    // Arabic — also flips the whole app to RTL.
    await choose(tester, 'Langue', AppLanguage.arabic.nativeName);
    expect(find.text('الإعدادات'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text('الإعدادات').first)),
      TextDirection.rtl,
    );
    await shot(tester, '05-settings-arabic');

    // Back to English, then light, for the section sweep.
    await choose(tester, 'اللغة', AppLanguage.english.nativeName);
    expect(find.text('Settings'), findsWidgets);
    await choose(tester, 'Theme', 'Light');

    const sections = [
      'Create',
      'Text',
      'Watermark',
      'Remove Silence',
      'Speed',
      'Compress',
      'Convert',
      'PDF Converter',
      'HTML',
      'Loop images',
      'Library',
    ];
    for (final section in sections) {
      await goToSection(tester, section);
      expect(tester.takeException(), isNull, reason: '$section (light)');
    }
    await shot(tester, '06-light-sweep-end');

    // And the same sweep in dark.
    await goToSection(tester, 'Settings');
    await choose(tester, 'Theme', 'Dark');
    for (final section in sections) {
      await goToSection(tester, section);
      expect(tester.takeException(), isNull, reason: '$section (dark)');
    }
    await shot(tester, '07-dark-sweep-end');
  });
}
