import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/usage_tracker.dart';
import '../core/i18n/app_locale.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/language_controller.dart';
import '../features/export/export_controller.dart';
import '../features/html_to_video/html_to_video_controller.dart';
import '../features/html_to_video/html_to_video_service.dart';
import 'paywall_schedule_host.dart';
import 'router.dart';
import 'theme.dart';
import 'theme_controller.dart';

/// App-wide messenger so background jobs (HTML → MP4, export) can surface a
/// toast no matter which tab or screen is currently visible.
final stilloraMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showStilloraToast(String message) {
  stilloraMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

class StilloraApp extends ConsumerWidget {
  const StilloraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final language = ref.watch(languageControllerProvider);

    return MaterialApp.router(
      title: 'Stillora',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: stilloraMessengerKey,
      theme: buildStilloraTheme(Brightness.light, language),
      darkTheme: buildStilloraTheme(Brightness.dark, language),
      themeMode: themeMode,
      // Setting `locale` also sets the text direction, which is what flips the
      // whole app to RTL for Arabic.
      locale: language.locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      // Both scopes sit *inside* MaterialApp: the palette one so it can read
      // the brightness resolved from [themeMode] + the OS, and the strings one
      // so every screen below can read `context.strings`.
      builder: (context, child) => AppStringsScope(
        strings: AppStrings.of(language),
        child: StilloraPaletteScope(
          child: UsageTrackerHost(
            child: ProPaywallScheduleHost(
              child: _BackgroundJobToasts(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Listens to long-running job providers and shows a toast on completion. Lives
/// in MaterialApp.builder so it stays mounted across every route and tab.
class _BackgroundJobToasts extends ConsumerWidget {
  const _BackgroundJobToasts({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(htmlToVideoControllerProvider, (previous, next) {
      if (previous?.isLoading != true) return; // only react to a finished job
      next.when(
        data: (file) {
          if (file != null) showStilloraToast(context.strings.toastVideoReady);
        },
        error: (error, _) => showStilloraToast(
          error is HtmlToVideoException
              ? error.message
              : context.strings.toastConversionFailed,
        ),
        loading: () {},
      );
    });

    ref.listen(exportControllerProvider, (previous, next) {
      if (previous?.isLoading != true) return;
      next.when(
        data: (result) {
          if (result != null)
            showStilloraToast(context.strings.toastExportComplete);
        },
        error: (_, _) => showStilloraToast(context.strings.toastExportFailed),
        loading: () {},
      );
    });

    return child;
  }
}
