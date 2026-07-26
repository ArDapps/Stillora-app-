import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../pdf_layout.dart';
import '../pdf_page_source.dart';

/// One row of the page list: where it lands in the finished document, what it
/// will look like, and the controls to turn or drop it.
///
/// The thumbnail carries the user's rotation live, so "rotate right" is
/// verifiable at a glance instead of only in the exported file.
class PdfPageRow extends StatelessWidget {
  const PdfPageRow({
    super.key,
    required this.page,
    required this.index,
    required this.total,
    required this.sheet,
    required this.enabled,
    required this.onRotate,
    required this.onShift,
    required this.onRemove,
    this.dragHandle,
  });

  final PdfPageSource page;

  /// Zero-based position; the badge shows [index] + 1.
  final int index;
  final int total;
  final PdfSheet sheet;

  /// False while an import or export is running — the queue must not change
  /// underneath a build that is already reading it.
  final bool enabled;

  /// Quarter turns clockwise (+1) or anti-clockwise (-1).
  final ValueChanged<int> onRotate;

  /// -1 moves this page one earlier, +1 one later.
  final ValueChanged<int> onShift;

  final VoidCallback onRemove;

  /// Grab area supplied by the list, so dragging is confined to one target and
  /// never steals a tap meant for the rotate/remove buttons.
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final fromPdf = page.origin == PdfPageOrigin.pdfPage;

    return Container(
      margin: const EdgeInsets.only(bottom: StilloraSpacing.xs),
      padding: const EdgeInsets.all(StilloraSpacing.xs),
      decoration: BoxDecoration(
        color: StilloraColors.surfaceDim,
        borderRadius: BorderRadius.circular(StilloraRadius.md),
        border: Border.all(color: StilloraColors.panelBorder),
      ),
      child: Row(
        children: [
          if (dragHandle != null) ...[
            dragHandle!,
            const SizedBox(width: 2),
          ],
          _PageNumber(index + 1),
          const SizedBox(width: StilloraSpacing.xs),
          _Thumbnail(page: page),
          const SizedBox(width: StilloraSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  page.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: StilloraColors.onSurface,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fromPdf ? 'PDF page' : 'Image'} · '
                  '${pageSizeLabel(page, sheet)}'
                  '${page.quarterTurns == 0 ? '' : ' · ${page.quarterTurns * 90}°'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StilloraColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _RowAction(
            icon: Icons.rotate_left_rounded,
            tooltip: 'Rotate left',
            onTap: enabled ? () => onRotate(-1) : null,
          ),
          _RowAction(
            icon: Icons.rotate_right_rounded,
            tooltip: 'Rotate right',
            onTap: enabled ? () => onRotate(1) : null,
          ),
          _RowAction(
            icon: Icons.keyboard_arrow_up_rounded,
            tooltip: 'Move up',
            onTap: enabled && index > 0 ? () => onShift(-1) : null,
          ),
          _RowAction(
            icon: Icons.keyboard_arrow_down_rounded,
            tooltip: 'Move down',
            onTap: enabled && index < total - 1 ? () => onShift(1) : null,
          ),
          _RowAction(
            icon: Icons.close_rounded,
            tooltip: 'Remove page',
            danger: true,
            onTap: enabled ? onRemove : null,
          ),
        ],
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber(this.number);
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: StilloraColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(StilloraRadius.sm),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: StilloraColors.accentText,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.page});
  final PdfPageSource page;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(StilloraRadius.sm),
      child: Container(
        width: 44,
        height: 56,
        color: Colors.white,
        // The queue can be hundreds of pages; decoding each thumbnail at full
        // resolution would blow the image cache, so cap the decode width.
        child: RotatedBox(
          quarterTurns: page.quarterTurns,
          child: Image.file(
            File(page.path),
            fit: BoxFit.cover,
            cacheWidth: 120,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) => const ColoredBox(
              color: StilloraColors.surfaceContainerHigh,
              child: Icon(
                Icons.broken_image_outlined,
                size: 16,
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      color: danger ? StilloraColors.error : StilloraColors.onSurfaceVariant,
    );
  }
}
