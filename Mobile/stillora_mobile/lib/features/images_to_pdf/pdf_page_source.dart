import 'package:pdf/pdf.dart';

/// Where a queued page came from. Images keep their original file; PDF pages
/// are rasterised on import and stored as PNGs in the section's work folder,
/// so from here on every page is just "an image with a size".
enum PdfPageOrigin { image, pdfPage }

/// One page of the document being assembled: a file on disk, the pixel size of
/// what is in it, and the rotation the user has dialled in.
///
/// [quarterTurns] is *not* baked into the file — nothing is ever re-encoded.
/// It is composed with the image's own EXIF orientation into a single
/// [PdfImageOrientation] that the PDF writer applies as a draw matrix, so a
/// rotated page costs nothing and loses nothing.
class PdfPageSource {
  const PdfPageSource({
    required this.id,
    required this.path,
    required this.label,
    required this.origin,
    required this.pixelWidth,
    required this.pixelHeight,
    this.byteSize = 0,
    this.exifOrientation = PdfImageOrientation.topLeft,
    this.quarterTurns = 0,
  });

  final String id;

  /// Absolute path of the image file backing this page.
  final String path;

  /// What the user sees in the page list, e.g. `receipt.jpg` or `scan.pdf · 3`.
  final String label;

  final PdfPageOrigin origin;

  /// Size as stored in the file, *before* orientation is applied.
  final int pixelWidth;
  final int pixelHeight;

  /// Size of [path] on disk, recorded at import. Because images are embedded
  /// as-is, summing these is a good estimate of the finished PDF — and keeping
  /// it on the page means the estimate never needs an async disk walk.
  final int byteSize;

  /// Orientation already baked into the file (EXIF). [PdfImageOrientation.topLeft]
  /// for anything that isn't a tagged JPEG.
  final PdfImageOrientation exifOrientation;

  /// User rotation in clockwise quarter turns, 0-3.
  final int quarterTurns;

  /// The file's own orientation plus the user's turns — what the PDF writer and
  /// the page-size maths both work from.
  PdfImageOrientation get orientation =>
      rotateOrientation(exifOrientation, quarterTurns);

  /// Orientations 4-7 are the quarter-turned ones, which swap width and height.
  bool get _swapsAxes => orientation.index >= 4;

  int get displayWidth => _swapsAxes ? pixelHeight : pixelWidth;
  int get displayHeight => _swapsAxes ? pixelWidth : pixelHeight;

  bool get isLandscape => displayWidth > displayHeight;

  PdfPageSource copyWith({String? label, int? quarterTurns}) {
    return PdfPageSource(
      id: id,
      path: path,
      label: label ?? this.label,
      origin: origin,
      pixelWidth: pixelWidth,
      pixelHeight: pixelHeight,
      byteSize: byteSize,
      exifOrientation: exifOrientation,
      quarterTurns: quarterTurns ?? this.quarterTurns,
    );
  }

  /// This page turned [delta] quarter turns clockwise (negative = anti-clockwise).
  PdfPageSource turned(int delta) =>
      copyWith(quarterTurns: (quarterTurns + delta) % 4);
}

/// The four non-mirrored EXIF orientations, in clockwise order.
const _clockwise = <PdfImageOrientation>[
  PdfImageOrientation.topLeft, // 0°
  PdfImageOrientation.rightTop, // 90°
  PdfImageOrientation.bottomRight, // 180°
  PdfImageOrientation.leftBottom, // 270°
];

/// The same cycle for the mirrored orientations, so flipped scans keep their
/// flip when the user rotates them.
const _clockwiseMirrored = <PdfImageOrientation>[
  PdfImageOrientation.topRight,
  PdfImageOrientation.rightBottom,
  PdfImageOrientation.bottomLeft,
  PdfImageOrientation.leftTop,
];

/// [base] turned [quarterTurns] steps clockwise, staying inside whichever of
/// the two cycles (mirrored or not) [base] belongs to.
PdfImageOrientation rotateOrientation(
  PdfImageOrientation base,
  int quarterTurns,
) {
  final turns = quarterTurns % 4;
  final plain = _clockwise.indexOf(base);
  if (plain >= 0) {
    return _clockwise[(plain + turns) % 4];
  }
  final mirrored = _clockwiseMirrored.indexOf(base);
  return _clockwiseMirrored[(mirrored + turns) % 4];
}
