import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/core/design/render_components.dart';
import 'package:stillora_mobile/core/design/stillora_colors.dart';
import 'package:stillora_mobile/core/widgets/desktop_shell.dart';
import 'package:stillora_mobile/features/editor/video_preset.dart';
import 'package:stillora_mobile/core/pro/pro_quality_picker.dart';
import 'package:stillora_mobile/features/pro/pro_screen.dart';
import 'package:stillora_mobile/main.dart' as app;

/// Drives the *real* app into light mode and measures what is actually painted
/// on screen, for the three light-theme complaints:
///
///   1. the export-quality chips (720p / 1080p / 2K / 4K) had invisible labels
///   2. the nav group headings read as greyed-out nav rows
///   3. the sidebar collapse button vanished into the shell backdrop
///
/// Colours are read off the built widgets rather than eyeballed, so this works
/// on macOS too, where `binding.takeScreenshot` is unsupported.
///
/// `pumpAndSettle` is unusable — the brand glow animates forever — so every
/// wait is a fixed number of frames, following `appearance_test.dart`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  double luminance(Color c) {
    double ch(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a), lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  String hex(Color? c) => c == null
      ? 'null'
      : '#${(c.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';

  Future<void> settle(WidgetTester tester, [int frames = 8]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  bool isDesktopShell() => find.byType(DesktopSidebar).evaluate().isNotEmpty;

  Future<void> shot(WidgetTester tester, String name) async {
    try {
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
        await settle(tester, 2);
      }
      await binding.takeScreenshot(name);
    } catch (error) {
      debugPrint('screenshot "$name" skipped: $error');
    }
  }

  // Same scroll-into-viewport tap as appearance_test.dart: a finder matching is
  // not enough, since a ListView keeps off-fold items in the tree.
  Future<void> tapText(WidgetTester tester, String label, {Finder? within}) async {
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    Finder target() => within == null
        ? find.text(label)
        : find.descendant(of: within, matching: find.text(label));
    Finder scroller() {
      if (within != null) {
        final scoped =
            find.descendant(of: within, matching: find.byType(Scrollable));
        if (scoped.evaluate().isNotEmpty) return scoped.first;
      }
      if (find.byType(Drawer).evaluate().isNotEmpty) {
        return find
            .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
            .first;
      }
      return find.byType(Scrollable).last;
    }

    // The desktop sidebar pins ACCOUNT / APP (Stillora Pro, Info) *below* its
    // scroll view, so those rows never fall inside the scrollable's rect and
    // the scroll loop below would hunt for them forever. If the target is
    // already painted on screen and is not part of the scroller, just tap it.
    final direct = target();
    if (direct.evaluate().isNotEmpty) {
      final rect = tester.getRect(direct.last);
      final onScreen = rect.top >= 0 &&
          rect.left >= 0 &&
          rect.bottom <= screen.height &&
          rect.right <= screen.width;
      final scrollable = scroller();
      final inScroller = scrollable.evaluate().isNotEmpty &&
          find
              .descendant(of: scrollable, matching: direct)
              .evaluate()
              .isNotEmpty;
      if (onScreen && !inScroller) {
        await tester.tap(direct.last);
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

  Future<void> choose(WidgetTester tester, String row, String option) async {
    await tapText(tester, row);
    await tapText(tester, option);
  }

  testWidgets('light theme renders every fixed control legibly', (tester) async {
    SharedPreferences.setMockInitialValues({'stillora.onboarding.seen': true});
    app.main();
    await settle(tester, 30);

    final desktop = isDesktopShell();
    debugPrint('SHELL: ${desktop ? "desktop sidebar" : "phone drawer"}');

    // What actually came up on launch — onboarding, a scheduled paywall and the
    // tab shell all look different, and the walk below depends on which.
    void dumpText(String stage) {
      final labels = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
      debugPrint('ONSCREEN[$stage] (${labels.length}): ${labels.join(" | ")}');
      debugPrint('ROUTES[$stage]: '
          'paywall=${find.byType(ProView).evaluate().isNotEmpty}');
    }

    dumpText('launch');

    // A scheduled/after-onboarding paywall pushes over the shell. Dismiss it
    // the way a user would before carrying on.
    if (find.byType(ProView).evaluate().isNotEmpty) {
      debugPrint('PAYWALL was open on launch — popping it');
      final ctx = tester.element(find.byType(ProView).first);
      Navigator.of(ctx).maybePop();
      await settle(tester, 12);
      dumpText('after-paywall-pop');
    }

    // Switch to Light through the real Settings UI, exactly as a user would.
    await goToSection(tester, 'Info');
    await choose(tester, 'Theme', 'Light');
    await settle(tester, 10);
    expect(
      StilloraColors.active.isDark,
      isFalse,
      reason: 'app did not actually switch to the light palette',
    );
    debugPrint('PALETTE: light  accent=${hex(StilloraColors.accent)} '
        'onAccent=${hex(StilloraColors.onAccent)}');
    await shot(tester, 'light-01-settings');

    // ── 1. Export-quality chips ────────────────────────────────────────────
    // Desktop Create shows the quality picker inline; the phone flow keeps it
    // on a later step, so fall through the sections until one paints it.
    var pickerHost = '';
    for (final section in ['Create', 'Loop images', 'HTML']) {
      await goToSection(tester, section);
      await settle(tester, 10);
      if (find.byType(ProQualityPicker).evaluate().isNotEmpty) {
        pickerHost = section;
        break;
      }
    }
    debugPrint('QUALITY PICKER found on: '
        '${pickerHost.isEmpty ? "(nowhere)" : pickerHost}');

    // These screens paint several pill-segmented controls (Resize, Duration,
    // Quality); scope to the quality one, not whichever comes first.
    final picker = find.byType(ProQualityPicker);
    expect(picker, findsWidgets,
        reason: 'no quality picker on Create / Loop images / HTML');
    final chips = find
        .descendant(of: picker.first, matching: find.byType(RenderPillSegmented))
        .first;

    for (final quality in ExportQuality.values) {
      final label = quality.label;
      final text = find.descendant(of: chips, matching: find.text(label));
      expect(text, findsOneWidget, reason: 'chip "$label" missing');

      final fg = tester.widget<Text>(text).style?.color;
      final material = tester.widget<Material>(
        find.ancestor(of: text, matching: find.byType(Material)).first,
      );
      final bg = material.color;
      expect(fg, isNotNull, reason: '$label has no explicit colour');
      expect(bg, isNotNull, reason: '$label chip has no fill');

      final ratio = contrast(fg!, bg!);
      final selected = bg.toARGB32() == StilloraColors.accent.toARGB32();
      debugPrint('CHIP ${label.padRight(6)} '
          '${selected ? "SELECTED" : "unselected"} '
          'fg=${hex(fg)} bg=${hex(bg)} contrast=${ratio.toStringAsFixed(2)}');

      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason: '"$label" is illegible in light mode '
            '(fg ${hex(fg)} on bg ${hex(bg)})',
      );

      // Legible also means *whole*: four chips plus PRO badges used to squeeze
      // "1080p" down to "10…".
      final paragraph = tester.renderObject<RenderParagraph>(text);
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '"$label" is truncated in the chip row',
      );
    }
    await shot(tester, 'light-02-quality-chips');

    // ── 2. Nav group headings ──────────────────────────────────────────────
    if (!desktop) {
      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);
    }
    final heading = find.text('CREATE');
    expect(heading, findsWidgets, reason: 'no CREATE group heading');
    final headingColor = tester.widget<Text>(heading.first).style?.color;
    final headingRatio = contrast(headingColor!, StilloraColors.surfaceDim);
    debugPrint('HEADING CREATE fg=${hex(headingColor)} '
        'on ${hex(StilloraColors.surfaceDim)} '
        'contrast=${headingRatio.toStringAsFixed(2)}');
    expect(headingColor.toARGB32(), StilloraColors.accentText.toARGB32(),
        reason: 'heading is not using the brand heading colour');
    expect(headingRatio, greaterThanOrEqualTo(4.5));
    await shot(tester, 'light-03-nav-headings');
    if (!desktop) {
      Navigator.of(tester.element(heading.first)).pop();
      await settle(tester);
    }

    // ── 3. Sidebar collapse button (desktop only) ──────────────────────────
    if (desktop) {
      final button = find.byType(GlassIconButton);
      expect(button, findsWidgets, reason: 'no collapse button in the sidebar');
      final material = tester.widget<Material>(
        find.descendant(of: button.first, matching: find.byType(Material)).first,
      );
      final fill = material.color!;
      // On a 32px circle the ring is what makes the control findable; the fill
      // can never differ much from the page behind it.
      final ring = (material.shape! as CircleBorder).side.color;
      final fillRatio = contrast(fill, StilloraColors.surface);
      final ringRatio = contrast(ring, StilloraColors.surface);
      debugPrint('COLLAPSE fill=${hex(fill)} (alpha=${fill.a}, '
          'contrast=${fillRatio.toStringAsFixed(2)}) '
          'ring=${hex(ring)} contrast=${ringRatio.toStringAsFixed(2)}');
      expect(fill.a, 1.0, reason: 'collapse button fill is still translucent');
      expect(
        ringRatio,
        greaterThanOrEqualTo(3.0),
        reason: 'collapse button ring ${hex(ring)} disappears into the surface',
      );

      // And it still works: tapping collapses the sidebar.
      await tester.tap(button.first);
      await settle(tester, 10);
      expect(find.byType(DesktopSidebar), findsOneWidget);
      debugPrint('COLLAPSE tapped — sidebar still mounted, no exception');
      expect(tester.takeException(), isNull);
      await shot(tester, 'light-04-sidebar-collapsed');
    }
  });
}
