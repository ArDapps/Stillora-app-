import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:stillora_mobile/features/images_to_pdf/images_to_pdf_controller.dart';
import 'package:stillora_mobile/features/images_to_pdf/images_to_pdf_screen.dart';
import 'package:stillora_mobile/features/images_to_pdf/widgets/pdf_page_row.dart';

/// Drives the PDF Converter's real widgets on a real device.
///
/// The other integration test covers the pipeline; this one covers the part a
/// user actually touches — the page rows, the rotate/reorder/remove buttons and
/// the export control — on the phone layout, where the section is one scrolling
/// column rather than the desktop's split pane.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late ProviderContainer container;

  ImagesToPdfController controller() =>
      container.read(imagesToPdfControllerProvider.notifier);
  ImagesToPdfState state() => container.read(imagesToPdfControllerProvider);

  setUpAll(() async {
    tmp = Directory('${(await getTemporaryDirectory()).path}/pdf_ui')
      ..createSync(recursive: true);
  });

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  Future<String> png(String name, int w, int h, img.ColorRgb8 color) async {
    final image = img.Image(width: w, height: h);
    img.fill(image, color: color);
    final file = File('${tmp.path}/$name');
    await file.writeAsBytes(img.encodePng(image), flush: true);
    return file.path;
  }

  /// Advances a few frames.
  ///
  /// Deliberately not `pumpAndSettle`, which waits for *all* animation to stop:
  /// the section's ad slot animates indefinitely, so settling never returns.
  /// That is invisible on a phone, where the ad is below the fold and never
  /// built, but hangs the desktop layout where it is on screen from the start.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  /// Drags the outer column until [target] is built.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    final column = find.byType(Scrollable).first;
    for (var i = 0; i < 10 && target.evaluate().isEmpty; i++) {
      await tester.drag(column, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// A control inside page row [index], rather than anywhere on screen. The
  /// setup card's "Rotate all" shares an icon with the per-row rotate, so an
  /// unscoped `find.byIcon(...).first` can hit the wrong one — and did, on the
  /// desktop layout where both are on screen at once.
  Finder rowControl(int index, IconData icon) => find.descendant(
    of: find.byType(PdfPageRow).at(index),
    matching: find.byIcon(icon),
  );

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SafeArea(child: ImagesToPdfView())),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the empty section invites files and blocks export', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(find.text('Add images or PDFs'), findsWidgets);
    expect(find.text('Export PDF'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Export PDF'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull, reason: 'nothing queued yet');
    expect(tester.takeException(), isNull);
  });

  testWidgets('queued pages show up as numbered rows', (tester) async {
    await controller().addPaths([
      await png('one.png', 300, 400, img.ColorRgb8(220, 60, 90)),
      await png('two.png', 300, 400, img.ColorRgb8(40, 140, 220)),
    ]);
    await pumpSection(tester);
    await settle(tester);

    expect(find.text('one.png'), findsOneWidget);
    expect(find.text('two.png'), findsOneWidget);
    expect(find.text('2 pages'), findsOneWidget);
    // The export button now names what it will produce.
    expect(find.text('Export 2 pages as PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping rotate turns that page only', (tester) async {
    await controller().addPaths([
      await png('r1.png', 300, 400, img.ColorRgb8(220, 60, 90)),
      await png('r2.png', 300, 400, img.ColorRgb8(40, 140, 220)),
    ]);
    await pumpSection(tester);
    await settle(tester);

    // "Rotate right" on the first row — not the card's "Rotate all".
    await tester.tap(rowControl(0, Icons.rotate_right_rounded));
    await settle(tester);

    expect(state().pages.first.quarterTurns, 1);
    expect(state().pages.last.quarterTurns, 0);
    // The row reports the new shape: a 300x400 page turned is 400x300.
    expect(find.textContaining('400 × 300'), findsOneWidget);
    expect(find.textContaining('90°'), findsOneWidget);
  });

  testWidgets('the move buttons reorder the document', (tester) async {
    await controller().addPaths([
      await png('m1.png', 200, 200, img.ColorRgb8(10, 200, 120)),
      await png('m2.png', 200, 200, img.ColorRgb8(240, 180, 20)),
    ]);
    await pumpSection(tester);
    await settle(tester);

    // Only the second row has an enabled "move up".
    await tester.tap(rowControl(1, Icons.keyboard_arrow_up_rounded));
    await settle(tester);

    expect(state().pages.map((p) => p.label), ['m2.png', 'm1.png']);
  });

  testWidgets('the close button drops a page', (tester) async {
    await controller().addPaths([
      await png('d1.png', 200, 200, img.ColorRgb8(10, 200, 120)),
      await png('d2.png', 200, 200, img.ColorRgb8(240, 180, 20)),
    ]);
    await pumpSection(tester);
    await settle(tester);

    await tester.tap(rowControl(0, Icons.close_rounded));
    await settle(tester);

    expect(state().pages.map((p) => p.label), ['d2.png']);
    expect(find.text('d1.png'), findsNothing);
  });

  testWidgets('changing the page size updates every row', (tester) async {
    await controller().addPaths([
      await png('s1.png', 300, 400, img.ColorRgb8(120, 90, 240)),
    ]);
    await pumpSection(tester);
    await settle(tester);

    expect(find.textContaining('300 × 400'), findsOneWidget);

    // The setup cards live below the page list in the phone layout.
    await scrollTo(tester, find.text('A4'));
    await tester.tap(find.text('A4'));
    await settle(tester);

    expect(find.textContaining('A4 · portrait'), findsOneWidget);
  });

  testWidgets('export writes a real PDF off the queue', (tester) async {
    await controller().addPaths([
      await png('e1.png', 300, 400, img.ColorRgb8(220, 60, 90)),
      await png('e2.png', 600, 300, img.ColorRgb8(40, 140, 220)),
    ]);
    controller().setFileName('mobile receipts');
    await pumpSection(tester);
    await settle(tester);

    // The export button itself opens the system share sheet on a phone, which
    // would block the test, so the controller's export is driven directly —
    // that is exactly what the button calls.
    final path = await controller().export();

    expect(path, isNotNull);
    expect(File(path!).existsSync(), isTrue);
    expect(path, endsWith('mobile receipts.pdf'));
    expect(File(path).lengthSync(), greaterThan(0));
    expect(state().error, isNull);
  });

  testWidgets('start over clears the section', (tester) async {
    await controller().addPaths([
      await png('c1.png', 200, 200, img.ColorRgb8(200, 200, 200)),
    ]);
    await pumpSection(tester);
    await settle(tester);

    await tester.tap(find.text('Start over'));
    await settle(tester);
    await tester.tap(find.text('Reset'));
    await settle(tester);

    expect(state().pages, isEmpty);
    expect(find.text('c1.png'), findsNothing);
    expect(find.text('Export PDF'), findsOneWidget);
  });

  testWidgets('a mixed image + PDF queue survives a full round trip', (
    tester,
  ) async {
    // Build a two-page PDF, then import it back alongside an image — the
    // headline flow, driven through the same code the UI uses.
    final source = await controller().export();
    expect(source, isNull, reason: 'nothing queued, so nothing to export');

    await controller().addPaths([
      await png('src1.png', 200, 300, img.ColorRgb8(0, 160, 90)),
      await png('src2.png', 200, 300, img.ColorRgb8(200, 120, 0)),
    ]);
    final built = await controller().export();
    expect(built, isNotNull);

    await controller().reset();
    await controller().addPaths([
      built!,
      await png('photo.png', 500, 500, img.ColorRgb8(30, 30, 60)),
    ]);
    await pumpSection(tester);
    await settle(tester);

    expect(state().pages, hasLength(3));
    expect(state().pdfPageCount, 2);
    expect(state().imageCount, 1);
    expect(find.text('3 pages'), findsOneWidget);
    expect(find.text('photo.png'), findsOneWidget);
    expect(find.textContaining('· page 1'), findsOneWidget);

    final merged = await controller().export();
    expect(merged, isNotNull);
    expect(File(merged!).lengthSync(), greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
