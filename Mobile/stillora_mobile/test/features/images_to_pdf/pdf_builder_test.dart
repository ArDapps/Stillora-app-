import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:stillora_mobile/features/images_to_pdf/pdf_builder.dart';
import 'package:stillora_mobile/features/images_to_pdf/pdf_import.dart';
import 'package:stillora_mobile/features/images_to_pdf/pdf_layout.dart';
import 'package:stillora_mobile/features/images_to_pdf/pdf_page_source.dart';

/// Writes a solid PNG of the given size and returns its path.
Future<String> _png(Directory dir, String name, int width, int height) async {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 40, 90));
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(img.encodePng(image), flush: true);
  return file.path;
}

/// Writes a solid JPEG, which is the format that carries EXIF orientation.
Future<String> _jpg(Directory dir, String name, int width, int height) async {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(20, 140, 200));
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(img.encodeJpg(image), flush: true);
  return file.path;
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('stillora_pdf_test');
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  group('probeImageBytes', () {
    test('reads a PNG\'s size without decoding it', () async {
      final path = await _png(dir, 'a.png', 320, 180);
      final probe = probeImageBytes(await File(path).readAsBytes());
      expect(probe, isNotNull);
      expect(probe!.width, 320);
      expect(probe.height, 180);
    });

    test('reads a JPEG\'s size', () async {
      final path = await _jpg(dir, 'a.jpg', 240, 400);
      final probe = probeImageBytes(await File(path).readAsBytes());
      expect(probe!.width, 240);
      expect(probe.height, 400);
    });

    test('returns null for something that is not an image', () {
      expect(probeImageBytes(utf8.encode('not an image at all')), isNull);
    });
  });

  group('importPdfPages', () {
    test('turns image files into pages, in the order given', () async {
      final first = await _png(dir, '1.png', 100, 200);
      final second = await _jpg(dir, '2.jpg', 300, 150);

      final result = await importPdfPages([first, second], remaining: 10);

      expect(result.skipped, isEmpty);
      expect(result.pages.map((p) => p.label), ['1.png', '2.jpg']);
      expect(result.pages.first.displayWidth, 100);
      expect(result.pages.last.displayWidth, 300);
      // Images are referenced in place — nothing is copied or re-encoded.
      expect(result.pages.first.path, first);
    });

    test('reports files it could not read instead of dropping them', () async {
      final good = await _png(dir, 'ok.png', 40, 40);
      final bad = File('${dir.path}/broken.png')
        ..writeAsStringSync('definitely not a png');

      final result = await importPdfPages([good, bad.path], remaining: 10);

      expect(result.pages, hasLength(1));
      expect(result.skipped, ['broken.png']);
    });

    test('stops at the remaining page budget', () async {
      final paths = [
        for (var i = 0; i < 4; i++) await _png(dir, '$i.png', 20, 20),
      ];
      final result = await importPdfPages(paths, remaining: 2);
      expect(result.pages, hasLength(2));
    });
  });

  group('buildPdfDocument', () {
    test('writes one real PDF page per queued page', () async {
      final paths = [
        await _png(dir, 'a.png', 120, 240),
        await _jpg(dir, 'b.jpg', 400, 200),
      ];
      final imported = await importPdfPages(paths, remaining: 10);

      final out = await buildPdfDocument(
        PdfBuildRequest(
          pages: imported.pages,
          outputPath: '${dir.path}/out/doc.pdf',
        ),
      );

      final bytes = await File(out).readAsBytes();
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      final text = latin1.decode(bytes, allowInvalid: true);
      // Two pages, each sized to its own image (match-image is the default).
      expect(RegExp(r'/MediaBox').allMatches(text), hasLength(2));
      expect(text, contains('/MediaBox[0 0 120 240]'));
      expect(text, contains('/MediaBox[0 0 400 200]'));
    });

    test('a rotated page turns its sheet without re-encoding the file',
        () async {
      final path = await _png(dir, 'portrait.png', 120, 240);
      final imported = await importPdfPages([path], remaining: 10);
      final sizeBefore = await File(path).length();

      final out = await buildPdfDocument(
        PdfBuildRequest(
          pages: [imported.pages.single.turned(1)],
          outputPath: '${dir.path}/out/rotated.pdf',
        ),
      );

      final text = latin1.decode(
        await File(out).readAsBytes(),
        allowInvalid: true,
      );
      expect(text, contains('/MediaBox[0 0 240 120]'));
      // The source image is untouched on disk.
      expect(await File(path).length(), sizeBefore);
    });

    test('honours a fixed sheet size and margin', () async {
      final path = await _png(dir, 'a.png', 120, 240);
      final imported = await importPdfPages([path], remaining: 10);

      final out = await buildPdfDocument(
        PdfBuildRequest(
          pages: imported.pages,
          outputPath: '${dir.path}/out/a4.pdf',
          sheet: PdfSheet.a4,
          margin: PdfMarginSize.wide,
        ),
      );

      final text = latin1.decode(
        await File(out).readAsBytes(),
        allowInvalid: true,
      );
      expect(text, contains('/MediaBox[0 0 595.27559 841.88976]'));
    });

    test('names the failing page when a file has gone missing', () async {
      final missing = PdfPageSource(
        id: 'x',
        path: '${dir.path}/vanished.png',
        label: 'vanished.png',
        origin: PdfPageOrigin.image,
        pixelWidth: 10,
        pixelHeight: 10,
      );

      expect(
        () => buildPdfDocument(
          PdfBuildRequest(
            pages: [missing],
            outputPath: '${dir.path}/out/nope.pdf',
          ),
        ),
        throwsA(
          isA<PdfBuildException>().having(
            (e) => e.toString(),
            'message',
            contains('vanished.png'),
          ),
        ),
      );
    });
  });

  group('normalizePdfFileName', () {
    test('adds the extension and strips a duplicate one', () {
      expect(normalizePdfFileName('receipts'), 'receipts.pdf');
      expect(normalizePdfFileName('receipts.pdf'), 'receipts.pdf');
      expect(normalizePdfFileName('receipts.PDF'), 'receipts.pdf');
    });

    test('drops characters a filesystem would choke on', () {
      expect(normalizePdfFileName('my/scan:2026'), 'myscan2026.pdf');
    });

    test('falls back to a usable name when nothing is left', () {
      expect(normalizePdfFileName('   '), 'stillora.pdf');
      expect(normalizePdfFileName('///'), 'stillora.pdf');
    });
  });

  test('formatPdfSize reads like a file listing', () {
    expect(formatPdfSize(512), '512 B');
    expect(formatPdfSize(2048), '2 KB');
    expect(formatPdfSize(3 * 1024 * 1024), '3.0 MB');
  });
}
