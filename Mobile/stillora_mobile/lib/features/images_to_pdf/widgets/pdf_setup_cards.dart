import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/widgets/render_panel.dart';
import '../images_to_pdf_controller.dart';
import '../pdf_builder.dart';
import '../pdf_import.dart';
import '../pdf_layout.dart';

/// Step 1 — get files in, and act on the whole queue at once.
class PdfSourceCard extends ConsumerWidget {
  const PdfSourceCard({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imagesToPdfControllerProvider);
    final controller = ref.read(imagesToPdfControllerProvider.notifier);
    final hasPages = state.pages.isNotEmpty;

    return RenderStepCard(
      number: '1',
      title: 'Pages',
      trailing: RenderTagPill('${state.pages.length}/$kPdfMaxPages'),
      footer: state.isImporting && state.importingLabel != null
          ? 'Reading ${state.importingLabel}…'
          : 'Images and PDFs mix freely — a PDF adds one page per page it has.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: state.isBusy ? null : onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(hasPages ? 'Add more files' : 'Add images or PDFs'),
            ),
          ),
          if (hasPages) ...[
            const SizedBox(height: StilloraSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => controller.rotateAll(1),
                    icon: const Icon(Icons.rotate_right_rounded, size: 18),
                    label: const Text('Rotate all'),
                  ),
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isBusy ? null : controller.clearPages,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Step 2 — the shape of every page in the finished document.
class PdfSheetCard extends ConsumerWidget {
  const PdfSheetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imagesToPdfControllerProvider);
    final controller = ref.read(imagesToPdfControllerProvider.notifier);

    return RenderStepCard(
      number: '2',
      title: 'Page size',
      trailing: RenderTagPill(state.sheet.label),
      footer: state.sheet.hint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RenderPillSegmented(
            options: [for (final sheet in PdfSheet.values) sheet.label],
            selectedIndex: PdfSheet.values.indexOf(state.sheet),
            onSelected: (i) => controller.setSheet(PdfSheet.values[i]),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text('Margin', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: StilloraSpacing.xs),
          RenderPillSegmented(
            options: [for (final m in PdfMarginSize.values) m.label],
            selectedIndex: PdfMarginSize.values.indexOf(state.margin),
            onSelected: (i) =>
                controller.setMargin(PdfMarginSize.values[i]),
          ),
        ],
      ),
    );
  }
}

/// Step 3 — how sharply an imported PDF's pages get re-drawn.
///
/// Only shown once something has been added, because it is meaningless on an
/// empty queue and only ever applies to the *next* PDF added.
class PdfImportQualityCard extends ConsumerWidget {
  const PdfImportQualityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imagesToPdfControllerProvider);
    final controller = ref.read(imagesToPdfControllerProvider.notifier);

    return RenderStepCard(
      number: '3',
      title: 'PDF import quality',
      trailing: RenderTagPill('${state.importDpi} dpi'),
      footer:
          'Imported PDF pages are re-drawn as pictures so they can be rotated '
          'and reordered next to your images. Text stops being selectable. '
          'Applies to PDFs added from now on.',
      child: RenderPillSegmented(
        options: [for (final dpi in kPdfImportDpiOptions) '$dpi dpi'],
        selectedIndex: kPdfImportDpiOptions.indexOf(state.importDpi),
        onSelected: (i) => controller.setImportDpi(kPdfImportDpiOptions[i]),
      ),
    );
  }
}

/// Step 4 — name the file and see roughly how big it will be.
class PdfOutputCard extends ConsumerStatefulWidget {
  const PdfOutputCard({super.key});

  @override
  ConsumerState<PdfOutputCard> createState() => _PdfOutputCardState();
}

class _PdfOutputCardState extends ConsumerState<PdfOutputCard> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref.read(imagesToPdfControllerProvider).fileName,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imagesToPdfControllerProvider);
    final controller = ref.read(imagesToPdfControllerProvider.notifier);

    // "Start over" resets the name in state; mirror that back into the field
    // without stomping on what the user is mid-way through typing.
    if (_name.text != state.fileName &&
        !FocusScope.of(context).hasFocus) {
      _name.text = state.fileName;
    }

    return RenderStepCard(
      number: '4',
      title: 'File name',
      trailing: state.estimatedBytes > 0
          ? RenderTagPill('≈ ${formatPdfSize(state.estimatedBytes)}')
          : null,
      footer: 'Saves as ${normalizePdfFileName(state.fileName)}',
      child: TextField(
        controller: _name,
        enabled: !state.isBusy,
        textInputAction: TextInputAction.done,
        onChanged: controller.setFileName,
        decoration: const InputDecoration(
          hintText: 'stillora',
          suffixText: '.pdf',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Inline banner for the "skipped 2 unreadable files" / "could not build"
/// messages the controller raises, dismissable so it doesn't linger.
class PdfMessageBanner extends ConsumerWidget {
  const PdfMessageBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imagesToPdfControllerProvider);
    final message = state.error ?? state.notice;
    if (message == null || message.isEmpty) return const SizedBox.shrink();
    final isError = state.error != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: StilloraSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(StilloraSpacing.xs),
        decoration: BoxDecoration(
          color: (isError ? StilloraColors.error : StilloraColors.secondary)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(StilloraRadius.md),
          border: Border.all(
            color: (isError ? StilloraColors.error : StilloraColors.secondary)
                .withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              size: 18,
              color: isError
                  ? StilloraColors.error
                  : StilloraColors.secondary,
            ),
            const SizedBox(width: StilloraSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  color: StilloraColors.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: ref
                  .read(imagesToPdfControllerProvider.notifier)
                  .clearMessages,
              icon: const Icon(Icons.close_rounded, size: 16),
              visualDensity: VisualDensity.compact,
              color: StilloraColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
