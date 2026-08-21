import 'dart:io';

import 'package:pdf/widgets.dart' as pw;

import 'pdf_layout.dart';
import 'pdf_page_source.dart';

/// Everything the writer needs, in plain values so the whole build can be sent
/// to a background isolate (assembling a hundred-page document on the UI
/// isolate janks the app for seconds).
class PdfBuildRequest {
  const PdfBuildRequest({
    required this.pages,
    required this.outputPath,
    this.sheet = PdfSheet.matchImage,
    this.margin = PdfMarginSize.none,
    this.title,
  });

  final List<PdfPageSource> pages;

  /// Where to write the finished document.
  final String outputPath;

  final PdfSheet sheet;
  final PdfMarginSize margin;
  final String? title;
}

/// Thrown when one page cannot be turned into PDF content, naming the file so
/// the user knows which one to drop.
class PdfBuildException implements Exception {
  const PdfBuildException(this.label, this.cause);

  final String label;
  final Object cause;

  @override
  String toString() => 'Could not add "$label" to the PDF.';
}

/// Writes [request] out as a single PDF and returns its path.
///
/// Top-level and free of Flutter bindings on purpose: it is invoked through
/// `compute`, so it must be runnable on a bare isolate.
///
/// Images are embedded as-is — a JPEG stays a JPEG inside the document — so
/// nothing is re-encoded and the export is lossless. Rotation rides along as
/// the image's orientation matrix rather than as rewritten pixels.
Future<String> buildPdfDocument(PdfBuildRequest request) async {
  final document = pw.Document(title: request.title);
  final margin = request.margin.points;

  for (final page in request.pages) {
    final pw.MemoryImage image;
    try {
      final bytes = await File(page.path).readAsBytes();
      image = pw.MemoryImage(bytes, orientation: page.orientation);
    } catch (error) {
      throw PdfBuildException(page.label, error);
    }

    document.addPage(
      pw.Page(
        pageFormat: sheetFormatFor(page, request.sheet, margin),
        build: (context) =>
            pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
  }

  final bytes = await document.save();
  final file = File(request.outputPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

/// `1.4 MB`-style label for [bytes].
String formatPdfSize(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}

/// Turns a user-typed name into a safe `something.pdf` filename.
String normalizePdfFileName(String raw) {
  var name = raw.trim().replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
  name = name.replaceAll(RegExp(r'[^A-Za-z0-9 _-]+'), '').trim();
  if (name.isEmpty) name = 'stillora';
  if (name.length > 60) name = name.substring(0, 60).trim();
  return '$name.pdf';
}

/// Guards against a document nobody's device can open — and against the writer
/// choking on a page whose size could not be read.
bool pageIsUsable(PdfPageSource page) =>
    page.displayWidth > 0 && page.displayHeight > 0;
