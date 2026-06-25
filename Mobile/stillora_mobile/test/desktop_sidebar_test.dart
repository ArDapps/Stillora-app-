import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:stillora_mobile/core/widgets/desktop_shell.dart';

void main() {
  // SidebarScaffold is what every export/editor sub-page now uses. On a desktop
  // surface it must render the persistent sidebar (so navigating into the export
  // flow never loses the navigation); on a phone surface it must fall back to a
  // plain Scaffold + AppBar with no sidebar.

  Widget harness(Widget home) {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => home)],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('shows the sidebar on a desktop-sized macOS surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      // runAsync lets the sidebar ad widget's network call settle so no timer
      // is left pending at teardown.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          harness(
            const SidebarScaffold(
              desktopTitle: 'Preview',
              body: Text('EXPORT_BODY'),
            ),
          ),
        );
      });
      await tester.pump();

      // Sidebar nav labels are present → the navigation is visible on the
      // export sub-page, not hidden.
      expect(find.text('Loop images'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('EXPORT_BODY'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('hides the sidebar on a phone surface', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        harness(
          SidebarScaffold(
            desktopTitle: 'Preview',
            appBar: AppBar(title: const Text('Preview')),
            body: const Text('EXPORT_BODY'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loop images'), findsNothing);
      expect(find.text('EXPORT_BODY'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
