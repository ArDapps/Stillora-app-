import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/core/widgets/desktop_shell.dart';
import 'package:stillora_mobile/core/widgets/section_split_view.dart';
import 'package:stillora_mobile/features/html_to_video/widgets/html_preview_pane.dart';
import 'package:stillora_mobile/features/loop_images/widgets/loop_images_panel.dart';
import 'package:stillora_mobile/features/pro/pro_screen.dart';
import 'package:stillora_mobile/main.dart' as app;

/// Walks the real app on a phone and opens every section that ships on this
/// platform, with nothing uploaded anywhere. The claim under test: on iOS and
/// Android no section parks an empty preview above its controls — the panel
/// waits until there is something to show — while the add/upload affordance
/// that fills it is still on screen in every one of them.
///
/// `pumpAndSettle` is unusable (the brand glow animates forever), so every
/// wait is a fixed number of frames, following the other integration tests.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

    final direct = target();
    if (direct.evaluate().isNotEmpty) {
      final rect = tester.getRect(direct.last);
      final onScreen =
          rect.top >= 0 &&
          rect.left >= 0 &&
          rect.bottom <= screen.height &&
          rect.right <= screen.width;
      final scrollable = scroller();
      final inScroller =
          scrollable.evaluate().isNotEmpty &&
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

  Future<void> dismissLaunchPaywall(WidgetTester tester) async {
    if (find.byType(ProView).evaluate().isEmpty) return;
    Navigator.of(tester.element(find.byType(ProView).first)).maybePop();
    await settle(tester, 12);
  }

  /// True when any of [labels] is currently built.
  bool anyText(List<String> labels) =>
      labels.any((l) => find.text(l).evaluate().isNotEmpty);

  /// Nothing in a section may be judged from the first screenful alone: these
  /// are lazily-built scroll columns, so an off-screen widget is simply not
  /// there to be found and `findsNothing` would pass for the wrong reason.
  /// Scrolls the section top to bottom, running [check] at every stop and
  /// reporting whether [labels] ever came into view.
  Future<bool> scanSection(
    WidgetTester tester,
    List<String> labels,
    void Function(String where) check,
  ) async {
    var seen = anyText(labels);
    check('top');
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) return seen;

    for (var step = 0; step < 12; step++) {
      await tester.drag(scrollable.last, const Offset(0, -320));
      await settle(tester, 4);
      check('scroll $step');
      if (anyText(labels)) seen = true;
    }
    return seen;
  }

  testWidgets('no section shows an empty preview before an upload', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'stillora.onboarding.seen': true});
    app.main();
    await settle(tester, 30);
    await dismissLaunchPaywall(tester);

    if (isDesktopShell()) {
      debugPrint('SKIP: desktop shell keeps its pinned preview pane by design');
      return;
    }

    // Every section that ships on iOS. Android hides the engine-gated five,
    // and goToSection would fail loudly on a missing drawer row, so each is
    // checked for presence first.
    const sections = <String>[
      'Create',
      'Text',
      'Loop images',
      'HTML',
      'Watermark',
      'Remove Silence',
      'Speed',
      'Compress',
      'Convert',
      'PDF Converter',
    ];

    // What each section offers instead of the preview it is not showing.
    const affordances = <String, List<String>>{
      'Create': ['Upload media'],
      'Text': ['Choose a video to caption'],
      'Loop images': ['Add images'],
      'HTML': ['Paste'],
      'Watermark': ['Choose a video to watermark'],
      'Remove Silence': ['Upload video'],
      'Speed': ['Upload video'],
      'Compress': ['Upload video'],
      'Convert': ['Select images'],
      'PDF Converter': ['Add images or PDFs'],
    };

    var visited = 0;
    for (final section in sections) {
      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);
      if (find.text(section).evaluate().isEmpty) {
        // Gated off this platform — close the drawer and move on.
        Navigator.of(tester.element(find.byType(Drawer).first)).maybePop();
        await settle(tester, 8);
        debugPrint('GATED  $section — not on this platform, skipped');
        continue;
      }
      await tapText(tester, section);
      await settle(tester, 14);
      visited++;

      // The panel is the first child of a section's column, so this one is
      // conclusive on its own: were it building, it would be on screen here.
      expect(
        find.byType(LivePreviewPanel),
        findsNothing,
        reason: '$section still builds a LivePreviewPanel while empty',
      );
      await shot(
        tester,
        'gating-${section.toLowerCase().replaceAll(' ', '-')}',
      );

      // Everything else is judged over the whole scroll, not one screenful.
      final ways = affordances[section]!;
      final found = await scanSection(tester, ways, (where) {
        expect(
          find.text('LIVE PREVIEW'),
          findsNothing,
          reason: '$section shows an empty live preview at $where',
        );
        expect(
          find.byType(LivePreviewPanel),
          findsNothing,
          reason: '$section builds a LivePreviewPanel at $where',
        );
        // The two sections with their own layouts, not SectionSplitView.
        expect(
          find.byType(LoopImagesPanel),
          findsNothing,
          reason: 'Loop images shows its queue panel while empty, at $where',
        );
        expect(
          find.byType(PreviewPane),
          findsNothing,
          reason: 'HTML shows its render canvas before a render, at $where',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '$section threw while laying out at $where',
        );
      });

      expect(
        found,
        isTrue,
        reason:
            '$section lost its upload affordance — none of $ways anywhere in '
            'the section',
      );

      debugPrint(
        'OK     $section — no empty preview, "${ways.first}" reachable',
      );
    }

    debugPrint('VISITED $visited sections');
    expect(visited, greaterThanOrEqualTo(5), reason: 'too few sections opened');
  });
}
