import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:stillora_mobile/app/theme.dart';
import 'package:stillora_mobile/core/design/stillora_colors.dart';
import 'package:stillora_mobile/core/i18n/app_locale.dart';
import 'package:stillora_mobile/core/i18n/app_strings.dart';
import 'package:stillora_mobile/core/widgets/desktop_shell.dart';

/// The desktop shell has to carry the same language + palette switching as the
/// phone layout — the sidebar and top bar are its only navigation.
void main() {
  Widget harness({
    required AppLanguage language,
    required ThemeMode mode,
    Widget home = const SidebarScaffold(
      desktopTitle: 'Preview',
      body: Text('BODY'),
    ),
  }) {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => home)],
    );
    return ProviderScope(
      child: MaterialApp.router(
        theme: buildStilloraTheme(Brightness.light),
        darkTheme: buildStilloraTheme(Brightness.dark),
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
        routerConfig: router,
      ),
    );
  }

  Future<void> pumpDesktop(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    // runAsync lets the sidebar ad widget's network call settle so no timer is
    // left pending at teardown.
    await tester.runAsync(() async => tester.pumpWidget(app));
    await tester.pump();
    // MaterialApp crossfades between themes over ~200ms, so the palette only
    // settles a few frames in. (pumpAndSettle is unusable — the brand glow
    // animates forever.)
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the sidebar shows Settings, not the old Info tab', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpDesktop(
        tester,
        harness(language: AppLanguage.english, mode: ThemeMode.dark),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Info'), findsNothing);
      expect(find.text('Library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the sidebar is translated', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpDesktop(
        tester,
        harness(language: AppLanguage.french, mode: ThemeMode.dark),
      );
      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('Bibliothèque'), findsOneWidget);
      expect(find.text('ESPACE DE TRAVAIL'), findsOneWidget); // SidebarLabel uppercases

      await pumpDesktop(
        tester,
        harness(language: AppLanguage.arabic, mode: ThemeMode.dark),
      );
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('المكتبة'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('الإعدادات'))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the desktop backdrop follows the palette', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpDesktop(
        tester,
        harness(language: AppLanguage.english, mode: ThemeMode.light),
      );
      // The shell used to paint a hardcoded near-black gradient, which stayed
      // dark in light mode.
      expect(StilloraColors.shellGradient.colors.first.computeLuminance(),
          greaterThan(0.7));
      expect(tester.takeException(), isNull);

      await pumpDesktop(
        tester,
        harness(language: AppLanguage.english, mode: ThemeMode.dark),
      );
      expect(StilloraColors.shellGradient.colors.first.computeLuminance(),
          lessThan(0.1));
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
