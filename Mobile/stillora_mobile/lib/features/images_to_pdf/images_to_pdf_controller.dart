import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'pdf_builder.dart';
import 'pdf_import.dart';
import 'pdf_layout.dart';
import 'pdf_page_source.dart';

/// DPI choices for rasterising an imported PDF. Higher is sharper text and a
/// much bigger file — 150 is the readable-on-screen default, 300 is print.
const kPdfImportDpiOptions = <int>[100, 150, 300];

class ImagesToPdfState {
  const ImagesToPdfState({
    this.pages = const [],
    this.sheet = PdfSheet.matchImage,
    this.margin = PdfMarginSize.none,
    this.importDpi = 150,
    this.fileName = 'stillora',
    this.isImporting = false,
    this.isExporting = false,
    this.importingLabel,
    this.notice,
    this.error,
  });

  /// Pages in export order — index 0 becomes page 1.
  final List<PdfPageSource> pages;

  final PdfSheet sheet;
  final PdfMarginSize margin;
  final int importDpi;

  /// Name (without extension) offered in the save dialog.
  final String fileName;

  final bool isImporting;
  final bool isExporting;

  /// The file currently being read, shown while a long PDF import runs.
  final String? importingLabel;

  /// Rough size of the document these pages would produce. Derived, never
  /// stored: an async disk walk that wrote back into state raced with the
  /// notifier's own lifecycle every time a page was removed.
  int get estimatedBytes => pages.isEmpty
      ? 0
      : pages.fold(0, (sum, page) => sum + page.byteSize) + 1024 * pages.length;

  /// Transient message — files skipped, export saved, and so on.
  final String? notice;
  final String? error;

  bool get isBusy => isImporting || isExporting;
  bool get canExport => pages.isNotEmpty && !isBusy;
  int get remainingSlots => kPdfMaxPages - pages.length;

  int get imageCount =>
      pages.where((p) => p.origin == PdfPageOrigin.image).length;
  int get pdfPageCount =>
      pages.where((p) => p.origin == PdfPageOrigin.pdfPage).length;

  ImagesToPdfState copyWith({
    List<PdfPageSource>? pages,
    PdfSheet? sheet,
    PdfMarginSize? margin,
    int? importDpi,
    String? fileName,
    bool? isImporting,
    bool? isExporting,
    String? importingLabel,
    String? notice,
    String? error,
    bool clearImportingLabel = false,
    bool clearMessages = false,
  }) {
    return ImagesToPdfState(
      pages: pages ?? this.pages,
      sheet: sheet ?? this.sheet,
      margin: margin ?? this.margin,
      importDpi: importDpi ?? this.importDpi,
      fileName: fileName ?? this.fileName,
      isImporting: isImporting ?? this.isImporting,
      isExporting: isExporting ?? this.isExporting,
      importingLabel: clearImportingLabel
          ? null
          : (importingLabel ?? this.importingLabel),
      notice: clearMessages ? null : (notice ?? this.notice),
      error: clearMessages ? null : (error ?? this.error),
    );
  }
}

final imagesToPdfControllerProvider =
    NotifierProvider<ImagesToPdfController, ImagesToPdfState>(
      ImagesToPdfController.new,
    );

/// "PDF Converter": queue images and PDFs, order and rotate the pages, export
/// the lot as one document. Everything happens on-device — nothing is uploaded.
class ImagesToPdfController extends Notifier<ImagesToPdfState> {
  @override
  ImagesToPdfState build() => const ImagesToPdfState();

  Future<void> addPaths(Iterable<String> paths) async {
    final incoming = paths.toList();
    if (incoming.isEmpty || state.isBusy) return;
    if (state.remainingSlots <= 0) {
      state = state.copyWith(
        error: 'A document can hold up to $kPdfMaxPages pages.',
      );
      return;
    }

    state = state.copyWith(isImporting: true, clearMessages: true);
    try {
      final result = await importPdfPages(
        incoming,
        remaining: state.remainingSlots,
        dpi: state.importDpi,
        onProgress: (label) => state = state.copyWith(importingLabel: label),
      );
      final pages = [...state.pages, ...result.pages];
      state = state.copyWith(
        pages: pages,
        isImporting: false,
        clearImportingLabel: true,
        notice: result.skipped.isEmpty
            ? null
            : 'Skipped ${result.skipped.length} unreadable '
                  '${result.skipped.length == 1 ? "file" : "files"}: '
                  '${result.skipped.take(3).join(", ")}',
      );
    } catch (error) {
      state = state.copyWith(
        isImporting: false,
        clearImportingLabel: true,
        error: 'Could not read those files. $error',
      );
    }
  }

  void remove(String id) {
    if (state.isBusy) return;
    state = state.copyWith(
      pages: state.pages.where((p) => p.id != id).toList(),
      clearMessages: true,
    );
  }

  /// Moves the page at [oldIndex] so it ends up at [newIndex] — the settled
  /// position, as `ReorderableListView.onReorderItem` reports it.
  void move(int oldIndex, int newIndex) {
    if (state.isBusy) return;
    final pages = [...state.pages];
    if (oldIndex < 0 || oldIndex >= pages.length) return;
    final target = newIndex.clamp(0, pages.length - 1);
    if (target == oldIndex) return;
    pages.insert(target, pages.removeAt(oldIndex));
    state = state.copyWith(pages: pages);
  }

  /// Nudges one page up or down — the keyboard/mobile-friendly companion to
  /// dragging, which is fiddly on a phone with a hundred pages queued.
  void shift(String id, int delta) {
    final index = state.pages.indexWhere((p) => p.id == id);
    if (index < 0) return;
    final target = index + delta;
    if (target < 0 || target >= state.pages.length) return;
    final pages = [...state.pages];
    pages.insert(target, pages.removeAt(index));
    state = state.copyWith(pages: pages);
  }

  void rotate(String id, int quarterTurns) {
    if (state.isBusy) return;
    state = state.copyWith(
      pages: [
        for (final page in state.pages)
          if (page.id == id) page.turned(quarterTurns) else page,
      ],
    );
  }

  void rotateAll(int quarterTurns) {
    if (state.isBusy || state.pages.isEmpty) return;
    state = state.copyWith(
      pages: [for (final page in state.pages) page.turned(quarterTurns)],
    );
  }

  void setSheet(PdfSheet sheet) => state = state.copyWith(sheet: sheet);

  void setMargin(PdfMarginSize margin) =>
      state = state.copyWith(margin: margin);

  /// Only affects PDFs imported *after* the change; already-rasterised pages
  /// keep the DPI they were read at.
  void setImportDpi(int dpi) => state = state.copyWith(importDpi: dpi);

  void setFileName(String name) => state = state.copyWith(fileName: name);

  void clearMessages() => state = state.copyWith(clearMessages: true);

  /// Empties the queue but keeps the page-setup choices.
  void clearPages() {
    if (state.isBusy) return;
    state = state.copyWith(pages: const [], clearMessages: true);
  }

  /// What "Start over" calls: drops the pages *and* the settings, and deletes
  /// the rasterised pages cached on disk.
  Future<void> reset() async {
    if (state.isBusy) return;
    state = const ImagesToPdfState();
    await clearPdfWorkDirectory();
  }

  /// Renders the document into the app's temp folder and returns its path, or
  /// null when the export failed (the reason lands in `state.error`).
  Future<String?> export() async {
    if (!state.canExport) return null;
    final usable = state.pages.where(pageIsUsable).toList();
    if (usable.isEmpty) {
      state = state.copyWith(
        error: 'None of these pages could be measured.',
        clearMessages: true,
      );
      return null;
    }

    state = state.copyWith(isExporting: true, clearMessages: true);
    try {
      final dir = await getTemporaryDirectory();
      final name = normalizePdfFileName(state.fileName);
      final request = PdfBuildRequest(
        pages: usable,
        outputPath: '${dir.path}/stillora_pdf_out/$name',
        sheet: state.sheet,
        margin: state.margin,
        title: name,
      );
      // Assembling and deflating a long document is seconds of CPU; keep it off
      // the UI isolate so the progress spinner actually spins.
      final path = await compute(buildPdfDocument, request);
      state = state.copyWith(isExporting: false);
      return path;
    } catch (error) {
      state = state.copyWith(
        isExporting: false,
        error: error is PdfBuildException
            ? error.toString()
            : 'Could not build the PDF. $error',
      );
      return null;
    }
  }
}
