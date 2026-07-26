import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import 'package:stillora_mobile/features/images_to_pdf/pdf_builder.dart';
import 'package:stillora_mobile/features/images_to_pdf/pdf_import.dart';
import 'package:stillora_mobile/features/images_to_pdf/pdf_layout.dart';
import 'package:stillora_mobile/features/images_to_pdf/pdf_page_source.dart';

/// End-to-end cover for the Images → PDF section on a real device.
///
/// The unit tests can only reach the pure-Dart half. Importing a PDF goes
/// through `Printing.raster`, which is native on every platform — this is the
/// only place that path actually runs, so it is where a broken plugin build or
/// an unsupported rasteriser shows up.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUpAll(() async {
    tmp = Directory('${(await getTemporaryDirectory()).path}/pdf_it')
      ..createSync(recursive: true);
  });

  tearDownAll(() async {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<String> writePng(String name, int w, int h, Color color) async {
    final image = img.Image(width: w, height: h);
    img.fill(
      image,
      color: img.ColorRgb8(
        (color.r * 255).round(),
        (color.g * 255).round(),
        (color.b * 255).round(),
      ),
    );
    final file = File('${tmp.path}/$name');
    await file.writeAsBytes(img.encodePng(image), flush: true);
    return file.path;
  }

  String textOf(String path) =>
      latin1.decode(File(path).readAsBytesSync(), allowInvalid: true);

  testWidgets('this platform can rasterise a PDF', (tester) async {
    final info = await Printing.info();
    expect(
      info.canRaster,
      isTrue,
      reason: 'Importing a PDF depends on Printing.raster being available.',
    );
  });

  testWidgets('images become one PDF, one page each', (tester) async {
    final paths = [
      await writePng('a.png', 300, 400, const Color(0xffEF4444)),
      await writePng('b.png', 800, 400, const Color(0xff2563EB)),
    ];

    final imported = await importPdfPages(paths, remaining: 10);
    expect(imported.skipped, isEmpty);
    expect(imported.pages, hasLength(2));

    final out = await buildPdfDocument(
      PdfBuildRequest(
        pages: imported.pages,
        outputPath: '${tmp.path}/images.pdf',
      ),
    );

    final text = textOf(out);
    expect(text, contains('/MediaBox[0 0 300 400]'));
    expect(text, contains('/MediaBox[0 0 800 400]'));
    expect(File(out).lengthSync(), greaterThan(0));
  });

  testWidgets('an existing PDF is imported page by page and merged', (
    tester,
  ) async {
    // Build a three-page PDF, then feed it back in as a source alongside an
    // image — the "several PDFs and photos into one file" flow.
    final source = await buildPdfDocument(
      PdfBuildRequest(
        pages: (await importPdfPages([
          await writePng('p1.png', 200, 300, const Color(0xff10B981)),
          await writePng('p2.png', 200, 300, const Color(0xffF59E0B)),
          await writePng('p3.png', 200, 300, const Color(0xff8B5CF6)),
        ], remaining: 10)).pages,
        outputPath: '${tmp.path}/source.pdf',
      ),
    );

    final extra = await writePng('extra.png', 400, 400, const Color(0xff111827));
    final imported = await importPdfPages([source, extra], remaining: 20);

    expect(imported.skipped, isEmpty);
    // Three rasterised pages from the PDF, then the image — order preserved.
    expect(imported.pages, hasLength(4));
    expect(
      imported.pages.take(3).map((p) => p.origin),
      everyElement(PdfPageOrigin.pdfPage),
    );
    expect(imported.pages.last.origin, PdfPageOrigin.image);
    expect(imported.pages.first.label, contains('page 1'));
    // Rasterised at 150 dpi, so a 200x300pt page comes back about 2.08x bigger.
    expect(imported.pages.first.displayWidth, greaterThan(300));

    final merged = await buildPdfDocument(
      PdfBuildRequest(
        pages: imported.pages,
        outputPath: '${tmp.path}/merged.pdf',
      ),
    );
    expect(RegExp('/MediaBox').allMatches(textOf(merged)), hasLength(4));
  });

  testWidgets('rotating a page turns it in the exported file', (tester) async {
    final imported = await importPdfPages([
      await writePng('portrait.png', 300, 600, const Color(0xff2563EB)),
    ], remaining: 10);

    final out = await buildPdfDocument(
      PdfBuildRequest(
        pages: [imported.pages.single.turned(1)],
        outputPath: '${tmp.path}/rotated.pdf',
      ),
    );

    expect(textOf(out), contains('/MediaBox[0 0 600 300]'));

    // The rotated document must still be readable by a real PDF engine.
    final reread = await importPdfPages([out], remaining: 10);
    expect(reread.pages, hasLength(1));
    expect(reread.pages.single.displayWidth,
        greaterThan(reread.pages.single.displayHeight));
  });

  testWidgets('a fixed sheet size lands on real A4 pages', (tester) async {
    final imported = await importPdfPages([
      await writePng('a4.png', 900, 300, const Color(0xff059669)),
    ], remaining: 10);

    final out = await buildPdfDocument(
      PdfBuildRequest(
        pages: imported.pages,
        outputPath: '${tmp.path}/a4.pdf',
        sheet: PdfSheet.a4,
        margin: PdfMarginSize.small,
      ),
    );

    // Wide image, so the sheet turned landscape: A4's long edge is the width.
    expect(textOf(out), contains('/MediaBox[0 0 841.88976 595.27559]'));
  });
}
