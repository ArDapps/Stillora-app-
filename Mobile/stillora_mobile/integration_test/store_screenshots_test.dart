import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/core/i18n/app_locale.dart';
import 'package:stillora_mobile/core/i18n/app_strings.dart';
import 'package:stillora_mobile/core/pro/pro_controller.dart';
import 'package:stillora_mobile/core/widgets/desktop_shell.dart';
import 'package:stillora_mobile/features/tabs/app_sections.dart';
import 'package:stillora_mobile/features/compress/compress_state.dart';
import 'package:stillora_mobile/features/gallery/local_export_store.dart';
import 'package:stillora_mobile/features/silence/silence_state.dart';
import 'package:stillora_mobile/features/speed/speed_state.dart';
import 'package:stillora_mobile/features/text_overlay/text_overlay_controller.dart';
import 'package:stillora_mobile/features/watermark/watermark_controller.dart';
import 'package:stillora_mobile/main.dart' as app;

import 'fixtures/sample_video.dart';

/// Captures the App Store / Mac App Store screenshot set from the real running
/// app, with mock media seeded so no screen is photographed empty.
///
/// Run once per device class *per language* — the required device sets are
/// iPhone 6.9", iPad 13" and Mac, and the store listing ships in English,
/// Arabic and French:
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/store_screenshots_test.dart \
///     --dart-define=SHOT_LANG=ar -d `device-id`
///
/// PNGs land in `screenshots/<lang>/`, numbered in upload order.
///
/// Nav labels are read from [AppStrings] rather than hardcoded, so the walk
/// works in every language — including Arabic, where the whole shell flips to
/// RTL. Note the tool screens themselves carry no localized strings today, so
/// their body copy stays English whatever this is set to.
/// Apple shows the first three in search results, so Create / Library / Pro
/// lead deliberately.
///
/// **Mock data is synthesised, never bundled.** Photos are generated in-process
/// with the `image` package; the one video is a base64 fixture in
/// `fixtures/sample_video.dart`. Nothing here ships in a release build.
///
/// `pumpAndSettle` is unusable — the brand glow animates forever — so every
/// wait is a fixed number of frames, following `appearance_test.dart`.
/// Which language to shoot, e.g. `--dart-define=SHOT_LANG=fr`.
const _langCode = String.fromEnvironment('SHOT_LANG', defaultValue: 'en');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final language = AppLanguage.fromCode(_langCode);
  final strings = AppStrings.of(language);

  Future<void> settle(WidgetTester tester, [int frames = 8]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  bool isDesktopShell() => find.byType(DesktopSidebar).evaluate().isNotEmpty;

  /// Where macOS captures are written. The app runs under App Sandbox, so it
  /// can only write inside its own container — the files are copied out to the
  /// repo afterwards by the run script.
  late final Directory macShotDir;

  Future<void> shot(WidgetTester tester, String name) async {
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await settle(tester, 2);
    }

    // `integration_test` implements captureScreenshot on iOS and Android only —
    // on macOS the method channel has no implementation at all. Rasterise the
    // render layer instead, which needs no plugin support.
    if (Platform.isMacOS) {
      final renderView = tester.binding.renderViews.first;
      final layer = renderView.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        renderView.paintBounds,
        pixelRatio: tester.view.devicePixelRatio,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      File('${macShotDir.path}/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
      debugPrint('SHOT $name ${data.lengthInBytes}B');
      return;
    }

    // Filed per language so one run never overwrites another's set.
    await binding.takeScreenshot('$_langCode/$name');
  }

  /// Scrolls [label] into its scrollable's viewport, then taps it. A finder
  /// matching is not enough: a ListView keeps items just past the fold in the
  /// tree, and those sit inside the screen but outside the clipped viewport, so
  /// a tap would land on whatever is painted there instead.
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

    // Items pinned *outside* the scrolling list — the desktop sidebar's
    // ACCOUNT / APP footer (Stillora Pro, Info) — are already on screen. The
    // loop below measures against the scrollable's viewport, so it would scroll
    // the tool list forever trying to "reach" something that never moves.
    final pinned = target();
    if (pinned.evaluate().isNotEmpty) {
      final scrollable = scroller();
      final inScroller =
          scrollable.evaluate().isNotEmpty &&
          find
              .descendant(of: scrollable, matching: pinned)
              .evaluate()
              .isNotEmpty;
      final rect = tester.getRect(pinned.last);
      final onScreen =
          rect.top >= 0 &&
          rect.bottom <= screen.height &&
          rect.left >= 0 &&
          rect.right <= screen.width;
      if (!inScroller && onScreen) {
        await tester.tap(pinned.last);
        await settle(tester);
        return;
      }
    }

    for (var attempt = 0; attempt < 14; attempt++) {
      final finder = target();
      final scrollable = scroller();
      final bounds = scrollable.evaluate().isNotEmpty
          ? tester.getRect(scrollable)
          : Offset.zero & screen;

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
      await tapText(tester, label, within: find.byType(DesktopSidebar));
      return;
    }
    await tester.tap(find.byIcon(Icons.menu));
    await settle(tester);
    await tapText(tester, label);
  }

  /// The Riverpod container the running app is using, so the harness can seed a
  /// tool's state the same way picking a file would.
  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

  testWidgets('App Store screenshot set', (tester) async {
    // ── Mock media ───────────────────────────────────────────────────────────
    final docs = await getApplicationDocumentsDirectory();

    if (Platform.isMacOS) {
      // Mac App Store accepts a fixed set of canvas sizes; 2880x1800 is the
      // retina 1440x900. Forcing it means the captures are upload-ready rather
      // than whatever size the window happened to open at.
      tester.view.physicalSize = const Size(2880, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      macShotDir = Directory('${docs.path}/store_shots/$_langCode')
        ..createSync(recursive: true);
    }
    final fixtures = Directory('${docs.path}/store_screenshot_fixtures')
      ..createSync(recursive: true);

    /// Stand-in photos, generated rather than bundled. Each is a distinct
    /// two-tone brand-ish gradient so a timeline of them reads as separate
    /// shots at thumbnail size.
    String makePhoto(String name, int from, int to) {
      const w = 1080, h = 1350;
      final image = img.Image(width: w, height: h);
      final fr = (from >> 16) & 0xff, fg = (from >> 8) & 0xff, fb = from & 0xff;
      final tr = (to >> 16) & 0xff, tg = (to >> 8) & 0xff, tb = to & 0xff;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final t = (x / w * 0.35) + (y / h * 0.65);
          image.setPixelRgb(
            x,
            y,
            (fr + (tr - fr) * t).round(),
            (fg + (tg - fg) * t).round(),
            (fb + (tb - fb) * t).round(),
          );
        }
      }
      final file = File('${fixtures.path}/$name.jpg')
        ..writeAsBytesSync(img.encodeJpg(image, quality: 88));
      return file.path;
    }

    final photos = [
      makePhoto('shot-01', 0x2B1055, 0x7597DE),
      makePhoto('shot-02', 0xD946EF, 0x4C1D95),
      makePhoto('shot-03', 0x0E7490, 0x22D3EE),
      makePhoto('shot-04', 0x7C2D12, 0xF59E0B),
    ];

    final videoBytes = base64Decode(sampleVideoBase64.replaceAll('\n', ''));
    String makeVideo(String name) {
      final file = File('${fixtures.path}/$name.mp4')
        ..writeAsBytesSync(videoBytes);
      return file.path;
    }

    final sourceVideo = makeVideo('source-clip');
    final libraryVideos = [
      makeVideo('export-reels'),
      makeVideo('export-square'),
      makeVideo('export-landscape'),
    ];

    // ── Seeded persistence ───────────────────────────────────────────────────
    // Create restores its last session from prefs, and the Library migrates a
    // legacy `stillora.exports` list into Hive on first open — so both screens
    // come up populated without touching a file picker.
    Map<String, dynamic> exportRecord(
      String id,
      String path,
      String preset,
      int w,
      int h,
      int seconds,
      int daysAgo,
    ) => {
      'id': id,
      'outputPath': path,
      'preset': preset,
      'width': w,
      'height': h,
      'durationSeconds': seconds,
      'createdAt': DateTime(2026, 8, 20)
          .subtract(Duration(days: daysAgo))
          .toIso8601String(),
    };

    SharedPreferences.setMockInitialValues({
      'stillora.onboarding.seen': true,
      // Stillora's identity is the deep-violet dark world, and a store set
      // should not depend on whatever appearance the simulator happens to be
      // in. Flip to 'light' here to shoot the light palette instead.
      'stillora.appearance.themeMode': 'dark',
      'stillora.appearance.language': language.code,
      // Pro on, so the sponsored banners are gone. This is not cosmetic: the
      // ad slots serve live third-party creative, and shipping another brand's
      // advert inside an App Store screenshot gets the listing rejected. The
      // paywall shot below flips Pro off for exactly one capture so it still
      // shows the offer rather than the "ACTIVE" state.
      'stillora.pro.lifetimeUnlocked': true,
      'stillora.editor.session.v1': jsonEncode({
        'media': [
          for (final path in photos.take(3))
            {'path': path, 'd': 4, 'vol': 1.0},
        ],
        'presetId': 'reels',
        'durationSeconds': 12,
        'resizeMode': 'fill',
        'exportQuality': 'hd720',
      }),
    });

    // Write the library straight into its Hive box, in the same shape
    // `HiveLocalExportStore.saveAll` uses. Seeding the legacy prefs list and
    // letting the migration pick it up is one indirection too many — the box is
    // the store's real home.
    //
    // SAFETY: a simulator gets a throwaway container, but on macOS this runs
    // against the *real* app container in ~/Library/Containers — the same Hive
    // box holding whatever the user has actually exported. So the box is only
    // ever seeded when it is empty, and is never cleared. Wiping somebody's
    // library to take a marketing screenshot is not a trade worth making.
    await Hive.initFlutter();
    final libraryBox = await Hive.openBox<Object?>(localExportHiveBoxName);
    if (libraryBox.isEmpty) {
      await libraryBox.putAll({
        'lib-1':
            exportRecord('lib-1', libraryVideos[0], 'Reels', 1080, 1920, 12, 0),
        'lib-2':
            exportRecord('lib-2', libraryVideos[1], 'Square', 1080, 1080, 8, 1),
        'lib-3':
            exportRecord('lib-3', libraryVideos[2], 'YouTube', 1920, 1080, 20, 3),
      });
    } else {
      debugPrint(
        'Library box already holds ${libraryBox.length} real records — '
        'left untouched. Run on a simulator for a clean seeded library.',
      );
    }
    await libraryBox.close();

    app.main();
    await settle(tester, 40);

    // ── Seed the tools that hold no session of their own ─────────────────────
    // `loadVideo` / `loadBaseVideo` are the same path a real pick takes, minus
    // the file picker.
    final container = containerOf(tester);
    await container.read(silenceControllerProvider.notifier).loadVideo(sourceVideo);
    await container.read(speedControllerProvider.notifier).loadVideo(sourceVideo);
    await container.read(compressControllerProvider.notifier).loadVideo(sourceVideo);
    await container
        .read(watermarkControllerProvider.notifier)
        .loadBaseVideo(sourceVideo);
    await container
        .read(textOverlayControllerProvider.notifier)
        .loadBaseVideo(sourceVideo);
    await settle(tester, 15);

    // ── The set, in upload order ─────────────────────────────────────────────
    // Apple shows the first three in search results.
    final set = <(String file, AppSection section)>[
      ('01-create', AppSection.create),
      ('02-library', AppSection.library),
      ('03-pro', AppSection.stilloraPro),
      ('04-watermark', AppSection.watermark),
      ('05-remove-silence', AppSection.removeSilence),
      ('06-speed', AppSection.speed),
      ('07-compress', AppSection.compress),
      ('08-text', AppSection.text),
      ('09-loop-images', AppSection.loopImages),
      ('10-pdf-converter', AppSection.pdfConverter),
    ];

    for (final (file, appSection) in set) {
      final section = appSection.title(strings);
      // Sections are platform-gated: five tools are hidden on Android, and the
      // set should simply skip whatever this device doesn't offer.
      final reachable = isDesktopShell()
          ? find
                .descendant(
                  of: find.byType(DesktopSidebar),
                  matching: find.text(section),
                )
                .evaluate()
                .isNotEmpty
          : true;
      if (!reachable || !appSection.isAvailable) {
        debugPrint('SKIP $file — "$section" not available on this platform');
        continue;
      }
      await goToSection(tester, section);

      // The paywall has to be photographed as a Free user sees it.
      final showsOffer = appSection == AppSection.stilloraPro;
      if (showsOffer) {
        await container.read(proControllerProvider.notifier).setPro(false);
      }
      await settle(tester, 12);
      await shot(tester, file);
      if (showsOffer) {
        await container.read(proControllerProvider.notifier).setPro(true);
        await settle(tester, 4);
      }
    }

    // No sponsored creative may survive into the set.
    expect(find.text('Sponsored'), findsNothing);
  });
}
