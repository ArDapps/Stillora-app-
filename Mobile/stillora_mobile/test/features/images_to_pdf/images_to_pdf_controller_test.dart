import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:stillora_mobile/features/images_to_pdf/images_to_pdf_controller.dart';
import 'package:stillora_mobile/features/images_to_pdf/pdf_layout.dart';

Future<String> _png(Directory dir, String name, int w, int h) async {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(120, 120, 120));
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(img.encodePng(image), flush: true);
  return file.path;
}

void main() {
  // The queue *is* the document: what order the pages are in and which way up
  // they sit is the entire product of this section, so it gets exercised
  // directly rather than only through the widget tree.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late ProviderContainer container;

  ImagesToPdfController controller() =>
      container.read(imagesToPdfControllerProvider.notifier);
  ImagesToPdfState state() => container.read(imagesToPdfControllerProvider);
  List<String> labels() => state().pages.map((p) => p.label).toList();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('stillora_pdf_ctrl');
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<void> addThree() async {
    await controller().addPaths([
      await _png(dir, 'a.png', 100, 200),
      await _png(dir, 'b.png', 100, 200),
      await _png(dir, 'c.png', 100, 200),
    ]);
  }

  test('starts empty and cannot export', () {
    expect(state().pages, isEmpty);
    expect(state().canExport, isFalse);
  });

  test('adding files queues them in the order picked', () async {
    await addThree();
    expect(labels(), ['a.png', 'b.png', 'c.png']);
    expect(state().canExport, isTrue);
    expect(state().imageCount, 3);
    expect(state().pdfPageCount, 0);
    // The size hint is filled in from the real files on disk.
    expect(state().estimatedBytes, greaterThan(0));
  });

  test('adding more appends rather than replaces', () async {
    await addThree();
    await controller().addPaths([await _png(dir, 'd.png', 10, 10)]);
    expect(labels(), ['a.png', 'b.png', 'c.png', 'd.png']);
  });

  group('move', () {
    test('drags a page to the front', () async {
      await addThree();
      controller().move(2, 0);
      expect(labels(), ['c.png', 'a.png', 'b.png']);
    });

    test('drags a page to the back', () async {
      await addThree();
      controller().move(0, 2);
      expect(labels(), ['b.png', 'c.png', 'a.png']);
    });

    test('ignores a move that changes nothing', () async {
      await addThree();
      controller().move(1, 1);
      expect(labels(), ['a.png', 'b.png', 'c.png']);
    });

    test('ignores an out-of-range source', () async {
      await addThree();
      controller().move(9, 0);
      expect(labels(), ['a.png', 'b.png', 'c.png']);
    });
  });

  group('shift', () {
    test('nudges a page one step earlier', () async {
      await addThree();
      controller().shift(state().pages[2].id, -1);
      expect(labels(), ['a.png', 'c.png', 'b.png']);
    });

    test('nudges a page one step later', () async {
      await addThree();
      controller().shift(state().pages.first.id, 1);
      expect(labels(), ['b.png', 'a.png', 'c.png']);
    });

    test('does nothing at the ends of the list', () async {
      await addThree();
      controller().shift(state().pages.first.id, -1);
      controller().shift(state().pages.last.id, 1);
      expect(labels(), ['a.png', 'b.png', 'c.png']);
    });
  });

  group('rotate', () {
    test('turns one page and leaves the rest alone', () async {
      await addThree();
      controller().rotate(state().pages[1].id, 1);
      expect(state().pages.map((p) => p.quarterTurns), [0, 1, 0]);
      // A quarter turn swaps the page's shape.
      expect(state().pages[1].displayWidth, 200);
      expect(state().pages[1].displayHeight, 100);
    });

    test('rotate all turns every page', () async {
      await addThree();
      controller().rotateAll(1);
      controller().rotateAll(1);
      expect(state().pages.map((p) => p.quarterTurns), [2, 2, 2]);
    });
  });

  test('remove drops just that page', () async {
    await addThree();
    controller().remove(state().pages[1].id);
    expect(labels(), ['a.png', 'c.png']);
  });

  test('clear empties the queue but keeps the page setup', () async {
    await addThree();
    controller().setSheet(PdfSheet.a4);
    controller().setMargin(PdfMarginSize.wide);
    controller().clearPages();

    expect(state().pages, isEmpty);
    expect(state().sheet, PdfSheet.a4);
    expect(state().margin, PdfMarginSize.wide);
    expect(state().canExport, isFalse);
  });

  test('start over drops the settings as well', () async {
    await addThree();
    controller().setSheet(PdfSheet.letter);
    controller().setFileName('receipts');
    await controller().reset();

    expect(state().pages, isEmpty);
    expect(state().sheet, PdfSheet.matchImage);
    expect(state().fileName, 'stillora');
  });

  test('unreadable files are reported, not silently dropped', () async {
    final good = await _png(dir, 'good.png', 20, 20);
    final bad = '${dir.path}/bad.png';
    File(bad).writeAsStringSync('nope');

    await controller().addPaths([good, bad]);

    expect(labels(), ['good.png']);
    expect(state().notice, contains('bad.png'));
  });
}
