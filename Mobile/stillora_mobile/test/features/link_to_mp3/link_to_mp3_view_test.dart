import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:stillora_mobile/core/widgets/desktop_shell.dart';
import 'package:stillora_mobile/features/link_to_mp3/link_to_mp3_screen.dart';
import 'package:stillora_mobile/features/link_to_mp3/link_to_mp3_service.dart';

/// Service stub whose conversion never resolves, so the view stays in its
/// loading state and the progress UI can be inspected.
class _NeverEndingService extends LinkToMp3Service {
  _NeverEndingService(super.ref);
  @override
  Future<Mp3Result> convert(
    String url, {
    String? language,
    CancelToken? cancelToken,
  }) =>
      Completer<Mp3Result>().future;
}

void main() {
  // Drives the real "MP3 Converter" section as a user would: render it, tap
  // Convert with no/bad input, and confirm the client-side validation (which
  // needs no backend) surfaces the right message. Also checks the section is
  // listed in the desktop sidebar under its new name.

  Widget harness(Widget home) {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => home)],
    );
    return ProviderScope(child: MaterialApp.router(routerConfig: router));
  }

  // Pumps [home] the way desktop_sidebar_test does: pumpWidget inside runAsync
  // (so the embedded ad widget's network call settles), then a plain pump.
  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1400, 1300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(() async {
      await tester.pumpWidget(harness(home));
    });
    await tester.pump();
  }

  // Disposing the tree cancels the ad widget's repeating animation so no
  // fake-async timer is left pending at teardown.
  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  }

  testWidgets('renders and validates an empty link', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pump(tester, const Scaffold(body: LinkToMp3View()));

      // The section rendered.
      expect(find.text('Convert to MP3'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Tapping Convert with an empty field surfaces the validation message.
      await tester.tap(find.text('Convert to MP3'));
      await tester.pump();
      expect(find.text('Paste a YouTube or TikTok link.'), findsOneWidget);

      await teardownTree(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('rejects a non-URL string', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pump(tester, const Scaffold(body: LinkToMp3View()));

      await tester.enterText(find.byType(TextField), 'just some text');
      await tester.tap(find.text('Convert to MP3'));
      await tester.pump();
      expect(find.textContaining('valid link'), findsOneWidget);

      await teardownTree(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('offers a video-language selector', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pump(tester, const Scaffold(body: LinkToMp3View()));
      expect(find.text('Video language'), findsOneWidget);
      // The default "Original" track is selected.
      expect(find.text('Original'), findsOneWidget);
      await teardownTree(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop sidebar lists the section as "MP3 Converter"',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pump(
        tester,
        const DesktopShell(
          activeIndex: 10,
          title: 'MP3 Converter',
          child: Text('MP3_BODY'),
        ),
      );

      expect(find.text('MP3 Converter'), findsWidgets);
      expect(find.text('MP3_BODY'), findsOneWidget);

      await teardownTree(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('renders on a phone-sized iOS surface', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.runAsync(() async {
        await tester.pumpWidget(harness(const Scaffold(body: LinkToMp3View())));
      });
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Video language'), findsOneWidget);
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('Convert to MP3'), findsOneWidget);

      await teardownTree(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('shows the loading progress UI while converting', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: LinkToMp3View()),
          ),
        ],
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              linkToMp3ServiceProvider
                  .overrideWith((ref) => _NeverEndingService(ref)),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
      });
      await tester.pump();

      // A valid link + Convert → the conversion starts (and never resolves).
      await tester.enterText(
        find.byType(TextField),
        'https://www.youtube.com/watch?v=abcdefghijk',
      );
      await tester.tap(find.text('Convert to MP3'));
      await tester.pump();

      // The progress card is shown with its title, first stage, an
      // indeterminate bar, and a Cancel affordance.
      expect(find.text('Converting…'), findsOneWidget);
      expect(find.text('Fetching the video…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      // The Convert button is replaced while in progress.
      expect(find.text('Convert to MP3'), findsNothing);

      await teardownTree(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
