import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/export/export_controller.dart';
import '../features/html_to_video/html_to_video_controller.dart';
import '../features/html_to_video/html_to_video_service.dart';
import 'router.dart';
import 'theme.dart';

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

    return MaterialApp.router(
      title: 'Stillora',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: stilloraMessengerKey,
      theme: buildStilloraTheme(Brightness.light),
      darkTheme: buildStilloraTheme(Brightness.dark),
      routerConfig: router,
      builder: (context, child) =>
          _BackgroundJobToasts(child: child ?? const SizedBox.shrink()),
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
          if (file != null) showStilloraToast('Your video is ready ✓');
        },
        error: (error, _) => showStilloraToast(
          error is HtmlToVideoException
              ? error.message
              : 'Conversion failed. Please try again.',
        ),
        loading: () {},
      );
    });

    ref.listen(exportControllerProvider, (previous, next) {
      if (previous?.isLoading != true) return;
      next.when(
        data: (result) {
          if (result != null) showStilloraToast('Export complete ✓');
        },
        error: (_, _) => showStilloraToast('Export failed. Please try again.'),
        loading: () {},
      );
    });

    return child;
  }
}
