import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/platform/import_directory.dart';
import '../../core/platform/media_actions.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/render_panel.dart';
import '../../core/widgets/section_split_view.dart';
import 'images_to_pdf_controller.dart';
import 'pdf_builder.dart';
import 'pdf_import.dart';
import 'widgets/pdf_pages_panel.dart';
import 'widgets/pdf_setup_cards.dart';

/// "PDF Converter": drop in photos, scans and existing PDFs, put the pages in
/// the right order, rotate the ones that came in sideways, and export the whole
/// lot as a single document.
///
/// Nothing leaves the device — the PDF is written locally, then handed to the
/// system save dialog (desktop) or share sheet (phone).
class ImagesToPdfView extends ConsumerWidget {
  const ImagesToPdfView({super.key});

  Future<void> _pick(WidgetRef ref) async {
    final result = await pickImportFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: kPdfInputExtensions,
    );
    if (result == null) return;
    final paths = result.files.map((f) => f.path).whereType<String>();
    await ref.read(imagesToPdfControllerProvider.notifier).addPaths(paths);
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(imagesToPdfControllerProvider.notifier);
    final name = normalizePdfFileName(
      ref.read(imagesToPdfControllerProvider).fileName,
    );

    final path = await controller.export();
    if (path == null || !context.mounted) return;

    void snack(String message, {bool offerSettings = false}) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          action: offerSettings
              ? SnackBarAction(label: 'Settings', onPressed: openAppSettings)
              : null,
        ),
      );
    }

    // Desktop gets a real "Save As"; a phone has no filesystem to speak of, so
    // the share sheet ("Save to Files", Drive, Mail…) is the way out.
    if (isDesktopPlatform) {
      final outcome = await MediaActions.savePdfToFile(
        path,
        suggestedName: name,
      );
      switch (outcome) {
        case SaveOutcome.saved:
          snack('PDF saved.');
        case SaveOutcome.missingFile:
          snack('The exported PDF is no longer available.');
        case SaveOutcome.permissionDenied:
          snack('Allow file access to save the PDF.', offerSettings: true);
        case SaveOutcome.failed:
          snack('Could not save the PDF. Please try again.');
        case SaveOutcome.cancelled:
          break; // User dismissed the dialog.
      }
      return;
    }

    if (!context.mounted) return;
    final shared = await MediaActions.sharePdf(context, path);
    if (!shared) snack('The exported PDF is no longer available.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imagesToPdfControllerProvider);
    final controller = ref.read(imagesToPdfControllerProvider.notifier);

    return SectionSplitView(
      onStartOver: controller.reset,
      canStartOver: state.pages.isNotEmpty && !state.isBusy,
      previewCaption:
          'Drag the handle to reorder — page 1 at the top. Everything stays on '
          'this device.',
      previewActions: _ExportButton(onExport: () => _export(context, ref)),
      preview: PdfPagesPanel(onAdd: () => _pick(ref)),
      controls: [
        const RenderEyebrow('PDF CONVERTER'),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          'Images & PDFs → one PDF',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          'Add photos, scans and existing PDFs, order the pages, rotate the '
          'crooked ones, and export the whole set as a single file.',
          style: TextStyle(color: StilloraColors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: StilloraSpacing.sm),
        const PdfMessageBanner(),
        PdfSourceCard(onAdd: () => _pick(ref)),
        const SizedBox(height: StilloraSpacing.xs),
        const PdfSheetCard(),
        const SizedBox(height: StilloraSpacing.xs),
        const PdfImportQualityCard(),
        const SizedBox(height: StilloraSpacing.xs),
        const PdfOutputCard(),
        const SizedBox(height: StilloraSpacing.sm),
        const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
      ],
    );
  }
}

/// The one button that turns the queue into a file. Kept under the page list on
/// both layouts so it sits next to what it is about to export.
class _ExportButton extends ConsumerWidget {
  const _ExportButton({required this.onExport});

  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imagesToPdfControllerProvider);
    final count = state.pages.length;

    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: state.canExport ? onExport : null,
        icon: state.isExporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isDesktopPlatform
                    ? Icons.download_rounded
                    : Icons.ios_share_rounded,
              ),
        label: Text(
          state.isExporting
              ? 'Building PDF…'
              : count == 0
              ? 'Export PDF'
              : 'Export $count ${count == 1 ? "page" : "pages"} as PDF',
        ),
      ),
    );
  }
}
