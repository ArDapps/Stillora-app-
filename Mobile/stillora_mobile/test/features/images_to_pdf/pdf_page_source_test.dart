import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import 'package:stillora_mobile/features/images_to_pdf/pdf_page_source.dart';

PdfPageSource page({
  int width = 1200,
  int height = 1600,
  PdfImageOrientation exif = PdfImageOrientation.topLeft,
  int quarterTurns = 0,
}) {
  return PdfPageSource(
    id: 'p',
    path: '/tmp/p.jpg',
    label: 'p.jpg',
    origin: PdfPageOrigin.image,
    pixelWidth: width,
    pixelHeight: height,
    exifOrientation: exif,
    quarterTurns: quarterTurns,
  );
}

void main() {
  // Rotation is never baked into the file — it is composed with whatever EXIF
  // orientation the photo already carried and handed to the PDF writer as one
  // orientation. If that composition is wrong, a rotated iPhone photo lands in
  // the document sideways (or mirrored), which is exactly the bug this section
  // exists to fix.

  group('rotateOrientation', () {
    test('walks the plain orientations clockwise', () {
      expect(
        rotateOrientation(PdfImageOrientation.topLeft, 1),
        PdfImageOrientation.rightTop,
      );
      expect(
        rotateOrientation(PdfImageOrientation.topLeft, 2),
        PdfImageOrientation.bottomRight,
      );
      expect(
        rotateOrientation(PdfImageOrientation.topLeft, 3),
        PdfImageOrientation.leftBottom,
      );
      expect(
        rotateOrientation(PdfImageOrientation.topLeft, 4),
        PdfImageOrientation.topLeft,
      );
    });

    test('keeps a mirrored image mirrored', () {
      // topRight is EXIF "flipped horizontally". Turning it must land on
      // another mirrored orientation, never on a plain one.
      const mirrored = {
        PdfImageOrientation.topRight,
        PdfImageOrientation.rightBottom,
        PdfImageOrientation.bottomLeft,
        PdfImageOrientation.leftTop,
      };
      for (var turns = 0; turns < 4; turns++) {
        expect(
          mirrored,
          contains(rotateOrientation(PdfImageOrientation.topRight, turns)),
        );
      }
    });

    test('composes on top of the file\'s own orientation', () {
      // A photo already tagged "rotate 90" plus one more turn is 180.
      expect(
        rotateOrientation(PdfImageOrientation.rightTop, 1),
        PdfImageOrientation.bottomRight,
      );
    });
  });

  group('display size', () {
    test('is the stored size when nothing is turned', () {
      final p = page();
      expect(p.displayWidth, 1200);
      expect(p.displayHeight, 1600);
      expect(p.isLandscape, isFalse);
    });

    test('swaps axes on a quarter turn', () {
      final p = page(quarterTurns: 1);
      expect(p.displayWidth, 1600);
      expect(p.displayHeight, 1200);
      expect(p.isLandscape, isTrue);
    });

    test('is unswapped again after half a turn', () {
      final p = page(quarterTurns: 2);
      expect(p.displayWidth, 1200);
      expect(p.displayHeight, 1600);
    });

    test('honours an EXIF-rotated photo with no user rotation', () {
      // The file stores 1600x1200 but is tagged "rotate 90", so it *displays*
      // as 1200x1600 — the page must be portrait.
      final p = page(
        width: 1600,
        height: 1200,
        exif: PdfImageOrientation.rightTop,
      );
      expect(p.displayWidth, 1200);
      expect(p.displayHeight, 1600);
    });
  });

  group('turned', () {
    test('wraps around at four quarter turns', () {
      expect(page(quarterTurns: 3).turned(1).quarterTurns, 0);
    });

    test('accepts an anti-clockwise turn', () {
      expect(page().turned(-1).quarterTurns, 3);
    });
  });
}
