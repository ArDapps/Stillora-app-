import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import 'package:stillora_mobile/core/i18n/app_locale.dart';
import 'package:stillora_mobile/core/i18n/app_strings.dart';
import 'package:stillora_mobile/features/images_to_pdf/pdf_layout.dart';
import 'package:stillora_mobile/features/images_to_pdf/pdf_page_source.dart';

PdfPageSource page({
  int width = 1200,
  int height = 1600,
  int quarterTurns = 0,
}) {
  return PdfPageSource(
    id: 'p',
    path: '/tmp/p.jpg',
    label: 'p.jpg',
    origin: PdfPageOrigin.image,
    pixelWidth: width,
    pixelHeight: height,
    quarterTurns: quarterTurns,
  );
}

/// Labels are language-dependent now; the test pins English.
final _en = AppStrings.of(AppLanguage.english);

void main() {
  group('sheetFormatFor · match image', () {
    test('gives the page the image\'s exact shape', () {
      final format = sheetFormatFor(page(), PdfSheet.matchImage, 0);
      expect(format.width, 1200);
      expect(format.height, 1600);
    });

    test('grows the sheet by the margin instead of shrinking the image', () {
      final format = sheetFormatFor(page(), PdfSheet.matchImage, 18);
      expect(format.width, 1200 + 36);
      expect(format.height, 1600 + 36);
      // The printable area is still exactly the image.
      expect(format.availableWidth, 1200);
      expect(format.availableHeight, 1600);
    });

    test('follows a rotated page into landscape', () {
      final format = sheetFormatFor(
        page(quarterTurns: 1),
        PdfSheet.matchImage,
        0,
      );
      expect(format.width, 1600);
      expect(format.height, 1200);
    });

    test('falls back to A4 when the size could not be read', () {
      final format = sheetFormatFor(
        page(width: 0, height: 0),
        PdfSheet.matchImage,
        0,
      );
      expect(format.width, PdfPageFormat.a4.width);
      expect(format.height, PdfPageFormat.a4.height);
    });
  });

  group('sheetFormatFor · fixed sheets', () {
    test('keeps A4 portrait for a portrait image', () {
      final format = sheetFormatFor(page(), PdfSheet.a4, 0);
      expect(format.width, PdfPageFormat.a4.width);
      expect(format.height, PdfPageFormat.a4.height);
    });

    test('turns the sheet landscape for a wide image', () {
      final format = sheetFormatFor(
        page(width: 1600, height: 900),
        PdfSheet.a4,
        0,
      );
      expect(format.width, greaterThan(format.height));
      expect(format.width, PdfPageFormat.a4.height);
    });

    test('a rotated portrait image turns the sheet too', () {
      final format = sheetFormatFor(
        page(quarterTurns: 1),
        PdfSheet.letter,
        0,
      );
      expect(format.width, greaterThan(format.height));
    });

    test('eats the margin out of the fixed sheet, not around it', () {
      final format = sheetFormatFor(page(), PdfSheet.a4, 45);
      expect(format.width, PdfPageFormat.a4.width);
      expect(format.availableWidth, PdfPageFormat.a4.width - 90);
    });
  });

  test('pageSizeLabel describes what the export will produce', () {
    expect(pageSizeLabel(page(), PdfSheet.matchImage, _en), '1200 × 1600');
    expect(pageSizeLabel(page(), PdfSheet.a4, _en), 'A4 · portrait');
    expect(
      pageSizeLabel(page(quarterTurns: 1), PdfSheet.a4, _en),
      'A4 · landscape',
    );
  });

  test('margin sizes are in PDF points', () {
    expect(PdfMarginSize.none.points, 0);
    expect(PdfMarginSize.small.points, 18); // quarter inch
    expect(PdfMarginSize.wide.points, 45);
  });
}
