import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'pdf_page_source.dart';

/// Ceiling on one document. Every page holds an open file plus a decoded
/// thumbnail, so an unbounded queue is an out-of-memory crash waiting to happen.
const kPdfMaxPages = 300;

/// Extensions accepted by the file picker. HEIC is included: the platform
/// decoder handles it even though the pure-Dart one cannot, and [_transcodePng]
/// bridges the gap.
const kPdfInputExtensions = <String>[
  'pdf',
  'jpg',
  'jpeg',
  'png',
  'webp',
  'heic',
  'heif',
  'gif',
  'bmp',
  'tif',
  'tiff',
];

/// What one import run produced, including the files it had to skip so the UI
/// can say so rather than silently dropping them.
class PdfImportResult {
  const PdfImportResult({required this.pages, this.skipped = const []});

  final List<PdfPageSource> pages;

  /// Names of files nothing could be read from.
  final List<String> skipped;
}

/// Scratch folder for rasterised PDF pages and transcoded images. Lives in the
/// temp directory: these are derived files, regenerated on every import.
Future<Directory> pdfWorkDirectory() async {
  final base = await getTemporaryDirectory();
  final dir = Directory('${base.path}/stillora_pdf_pages');
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Deletes everything the section has cached. Called from "Start over" so a
/// long session doesn't leave hundreds of rasterised pages behind.
Future<void> clearPdfWorkDirectory() async {
  try {
    final dir = await pdfWorkDirectory();
    if (dir.existsSync()) await dir.delete(recursive: true);
  } catch (_) {
    // Best effort — the OS reclaims the temp directory anyway.
  }
}

String _baseName(String path) => path.split(RegExp(r'[/\\]')).last;

String _extension(String path) {
  final name = _baseName(path);
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

var _idCounter = 0;
String _nextId() =>
    'pdfpage-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

/// No real page is bigger than this; anything past it came from a misread
/// header rather than a photograph.
const _maxProbeDimension = 65535;

/// Size and baked-in orientation of an encoded image, read from its header
/// without decoding the pixels. Null when nothing here recognises it — HEIC
/// most notably, which only the platform codec can open.
///
/// Deliberately restricted to the formats with real magic numbers. `image`'s
/// [img.findDecoderForData] also offers formats such as TGA that have no
/// signature at all and will happily "recognise" a text file, which would put a
/// garbage page in the user's document.
({int width, int height, PdfImageOrientation orientation})? probeImageBytes(
  Uint8List bytes,
) {
  try {
    final decoder = img.findDecoderForData(bytes);
    if (decoder == null) return null;

    if (decoder is img.JpegDecoder) {
      final info = PdfJpegInfo(bytes);
      return _probe(info.width, info.height, info.orientation);
    }

    final recognised =
        decoder is img.PngDecoder ||
        decoder is img.WebPDecoder ||
        decoder is img.GifDecoder ||
        decoder is img.BmpDecoder ||
        decoder is img.TiffDecoder;
    if (!recognised) return null;

    final info = decoder.startDecode(bytes);
    if (info == null) return null;
    return _probe(info.width, info.height, PdfImageOrientation.topLeft);
  } catch (_) {
    return null;
  }
}

({int width, int height, PdfImageOrientation orientation})? _probe(
  int? width,
  int? height,
  PdfImageOrientation orientation,
) {
  if (width == null || height == null) return null;
  if (width <= 0 || height <= 0) return null;
  if (width > _maxProbeDimension || height > _maxProbeDimension) return null;
  return (width: width, height: height, orientation: orientation);
}

/// Last resort for formats only the platform can read (HEIC from an iPhone,
/// exotic TIFFs): decode through Flutter's own codec and write a PNG the PDF
/// writer can embed. The PNG lands in the work folder, not next to the original.
Future<PdfPageSource?> _transcodePng(String path, String label) async {
  try {
    final codec = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final width = image.width;
    final height = image.height;
    image.dispose();
    codec.dispose();
    if (data == null || width <= 0 || height <= 0) return null;

    final dir = await pdfWorkDirectory();
    final id = _nextId();
    final png = data.buffer.asUint8List();
    final file = File('${dir.path}/$id.png');
    await file.writeAsBytes(png, flush: true);
    return PdfPageSource(
      id: id,
      path: file.path,
      label: label,
      origin: PdfPageOrigin.image,
      pixelWidth: width,
      pixelHeight: height,
      byteSize: png.length,
    );
  } catch (_) {
    return null;
  }
}

/// Rasterises every page of a PDF at [dpi] and writes each one out as a PNG.
///
/// The pages are re-laid-out alongside the images rather than copied through as
/// PDF objects, which is what lets a scanned page be rotated and reordered next
/// to a photo. The trade-off is that text stops being selectable, so the DPI is
/// exposed to the user.
Future<List<PdfPageSource>> _rasterizePdf(
  String path,
  int dpi,
  int remaining,
) async {
  final bytes = await File(path).readAsBytes();
  final name = _baseName(path);
  final dir = await pdfWorkDirectory();
  final pages = <PdfPageSource>[];

  var index = 0;
  await for (final raster in Printing.raster(bytes, dpi: dpi.toDouble())) {
    if (pages.length >= remaining) break;
    index++;
    final id = _nextId();
    final png = await raster.toPng();
    final file = File('${dir.path}/$id.png');
    await file.writeAsBytes(png, flush: true);
    pages.add(
      PdfPageSource(
        id: id,
        path: file.path,
        label: '$name · page $index',
        origin: PdfPageOrigin.pdfPage,
        pixelWidth: raster.width,
        pixelHeight: raster.height,
        byteSize: png.length,
      ),
    );
  }
  return pages;
}

/// Turns picked file paths into pages, in the order they were given.
///
/// [onProgress] is called with the name of each file as it starts, so a long
/// PDF import can show what it is chewing on. [remaining] caps how many pages
/// may still be added.
Future<PdfImportResult> importPdfPages(
  Iterable<String> paths, {
  required int remaining,
  int dpi = 150,
  void Function(String label)? onProgress,
}) async {
  final pages = <PdfPageSource>[];
  final skipped = <String>[];
  var left = remaining;

  for (final path in paths) {
    if (left <= 0) break;
    final name = _baseName(path);
    onProgress?.call(name);

    if (_extension(path) == 'pdf') {
      try {
        final rendered = await _rasterizePdf(path, dpi, left);
        if (rendered.isEmpty) {
          skipped.add(name);
        } else {
          pages.addAll(rendered);
          left -= rendered.length;
        }
      } catch (_) {
        skipped.add(name);
      }
      continue;
    }

    try {
      final bytes = await File(path).readAsBytes();
      final probe = probeImageBytes(bytes);
      if (probe != null) {
        pages.add(
          PdfPageSource(
            id: _nextId(),
            path: path,
            label: name,
            origin: PdfPageOrigin.image,
            pixelWidth: probe.width,
            pixelHeight: probe.height,
            byteSize: bytes.length,
            exifOrientation: probe.orientation,
          ),
        );
        left--;
        continue;
      }
    } catch (_) {
      // Fall through to the platform decoder below.
    }

    final transcoded = await _transcodePng(path, name);
    if (transcoded == null) {
      skipped.add(name);
    } else {
      pages.add(transcoded);
      left--;
    }
  }

  return PdfImportResult(pages: pages, skipped: skipped);
}
