import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/widgets/render_panel.dart';
import '../images_to_pdf_controller.dart';
import '../pdf_import.dart';
import 'pdf_page_row.dart';

/// Tallest the page list grows to inside the phone layout's scroll column —
/// about five rows, enough to work with while keeping the setup cards below it
/// within reach.
const double _phoneListMax = 420;

/// The document being assembled, top to bottom in export order.
///
/// A list rather than a grid: reordering is the whole point of this section,
/// and a vertical list makes "page 3 comes after page 2" literal — plus it
/// leaves room for the per-page rotate controls on a phone.
class PdfPagesPanel extends ConsumerWidget {
  const PdfPagesPanel({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The same panel is hosted two ways: in the desktop preview pane it gets a
    // bounded height and should fill it, scrolling internally; inside the phone
    // layout's single scroll column the height is unbounded and it must
    // shrink-wrap instead. Asking the constraints is more reliable than passing
    // a flag down — only the parent that actually lays it out knows.
    return LayoutBuilder(
      builder: (context, constraints) =>
          _build(context, ref, fill: constraints.hasBoundedHeight),
    );
  }

  Widget _build(BuildContext context, WidgetRef ref, {required bool fill}) {
    final state = ref.watch(imagesToPdfControllerProvider);
    final controller = ref.read(imagesToPdfControllerProvider.notifier);
    final pages = state.pages;

    final list = ReorderableListView.builder(
      shrinkWrap: !fill,
      padding: EdgeInsets.zero,
      // Dragging is limited to the handle in each row so the rotate/remove
      // buttons stay tappable.
      buildDefaultDragHandles: false,
      itemCount: pages.length,
      onReorderItem: controller.move,
      itemBuilder: (context, i) {
        final page = pages[i];
        return PdfPageRow(
          key: ValueKey(page.id),
          page: page,
          index: i,
          total: pages.length,
          sheet: state.sheet,
          enabled: !state.isBusy,
          dragHandle: ReorderableDragStartListener(
            index: i,
            enabled: !state.isBusy,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
          ),
          onRotate: (turns) => controller.rotate(page.id, turns),
          onShift: (delta) => controller.shift(page.id, delta),
          onRemove: () => controller.remove(page.id),
        );
      },
    );

    final body = pages.isEmpty
        ? _EmptyQueue(onAdd: onAdd, expand: fill)
        : (fill
              ? Expanded(child: list)
              // On a phone the whole section is one scroll column with the page
              // setup below this panel. Left to shrink-wrap, a fifty-page queue
              // would push "Page size" and the file name fifty rows down the
              // screen, so the list caps out and scrolls inside itself instead.
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: _phoneListMax),
                  child: list,
                ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Row(
          children: [
            RenderTagPill(
              pages.isEmpty
                  ? 'No pages yet'
                  : '${pages.length} ${pages.length == 1 ? "page" : "pages"}',
            ),
            const SizedBox(width: StilloraSpacing.base),
            if (pages.isNotEmpty)
              Expanded(
                child: Text(
                  '${state.imageCount} from images · '
                  '${state.pdfPageCount} from PDFs',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StilloraColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              )
            else
              const Spacer(),
            if (state.isImporting)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: StilloraSpacing.xs),
        body,
      ],
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.onAdd, required this.expand});

  final VoidCallback onAdd;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final zone = RenderDropZone(
      icon: Icons.picture_as_pdf_outlined,
      title: 'Add images or PDFs',
      hint: 'JPG · PNG · WebP · HEIC · PDF — up to $kPdfMaxPages pages',
      onTap: onAdd,
    );
    return expand ? Expanded(child: Center(child: zone)) : zone;
  }
}
