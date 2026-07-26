import 'package:pdf/pdf.dart';

import 'pdf_page_source.dart';

/// Sheet size for every page of the exported document.
enum PdfSheet {
  /// One page per image, exactly the image's shape — nothing is cropped, letter-
  /// boxed or scaled. The default, and the only mode that guarantees the export
  /// looks pixel-for-pixel like what went in.
  matchImage,
  a4,
  letter;

  String get label => switch (this) {
    PdfSheet.matchImage => 'Match image',
    PdfSheet.a4 => 'A4',
    PdfSheet.letter => 'Letter',
  };

  String get hint => switch (this) {
    PdfSheet.matchImage => 'Every page takes the shape of its own image',
    PdfSheet.a4 => '21 × 29.7 cm · pages turn landscape to fit wide images',
    PdfSheet.letter => '8.5 × 11 in · pages turn landscape to fit wide images',
  };
}

/// White border left around each page.
enum PdfMarginSize {
  none,
  small,
  wide;

  /// In PDF points (72 per inch).
  double get points => switch (this) {
    PdfMarginSize.none => 0,
    PdfMarginSize.small => 18,
    PdfMarginSize.wide => 45,
  };

  String get label => switch (this) {
    PdfMarginSize.none => 'None',
    PdfMarginSize.small => 'Small',
    PdfMarginSize.wide => 'Wide',
  };
}

/// Fallback for a page whose pixel size could not be read — better a readable
/// A4 sheet than a zero-sized page the writer would reject.
const _fallback = PdfPageFormat.a4;

/// The page format for [page] under [sheet], with [margin] points of white
/// space on every side.
///
/// In [PdfSheet.matchImage] the margin is added *around* the image rather than
/// eating into it, so the picture is never scaled down; the fixed sheets keep
/// their real-world size and the image is fitted inside the remaining area.
PdfPageFormat sheetFormatFor(
  PdfPageSource page,
  PdfSheet sheet,
  double margin,
) {
  switch (sheet) {
    case PdfSheet.matchImage:
      final width = page.displayWidth;
      final height = page.displayHeight;
      if (width <= 0 || height <= 0) {
        return PdfPageFormat(
          _fallback.width,
          _fallback.height,
          marginAll: margin,
        );
      }
      // 1 image pixel = 1 PDF point (72 dpi), which keeps the aspect ratio
      // exact and gives a sensible on-screen size for phone photos and scans.
      return PdfPageFormat(
        width + margin * 2,
        height + margin * 2,
        marginAll: margin,
      );

    case PdfSheet.a4:
    case PdfSheet.letter:
      final base = sheet == PdfSheet.a4
          ? PdfPageFormat.a4
          : PdfPageFormat.letter;
      // Turn the sheet to match the page so a wide photo isn't shrunk into a
      // portrait strip.
      final format = page.isLandscape ? base.landscape : base.portrait;
      return PdfPageFormat(format.width, format.height, marginAll: margin);
  }
}

/// Human-readable size of the page that [page] will produce, e.g. `1200 × 1600`
/// for a matched image or `A4 · portrait` for a fixed sheet. Used in the UI so
/// the shape of the export is visible before rendering it.
String pageSizeLabel(PdfPageSource page, PdfSheet sheet) {
  if (sheet == PdfSheet.matchImage) {
    return '${page.displayWidth} × ${page.displayHeight}';
  }
  return '${sheet.label} · ${page.isLandscape ? 'landscape' : 'portrait'}';
}
