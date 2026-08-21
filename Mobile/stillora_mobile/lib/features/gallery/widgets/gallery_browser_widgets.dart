import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/widgets/ad_widget.dart';
import '../../../core/widgets/stillora_video_player_panel.dart';
import '../local_export_record.dart';
import 'gallery_cards.dart';
import '../../../core/i18n/app_strings.dart';

/// Right-hand Library pane: the picked render playing on a loop plus its specs,
/// or a prompt while nothing is picked.
class GalleryPreview extends StatelessWidget {
  const GalleryPreview({super.key, required this.record, required this.player});

  final LocalExportRecord? record;
  final VideoPlayerController? player;

  @override
  Widget build(BuildContext context) {
    final item = record;
    if (item == null) {
      return Center(
        child: Icon(
          Icons.video_library_outlined,
          size: 40,
          color: StilloraColors.onSurfaceVariant,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: player == null
              ? const Center(child: CircularProgressIndicator())
              : StilloraVideoPlayerPanel(controller: player),
        ),
        const SizedBox(height: StilloraSpacing.snug),
        Text(
          '${item.preset} · ${item.width}×${item.height} · '
          '${item.durationSeconds}s',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class GallerySelectionBar extends StatelessWidget {
  const GallerySelectionBar({
    super.key,
    required this.selecting,
    required this.selectedCount,
    required this.totalCount,
    required this.onStart,
    required this.onCancel,
    required this.onSelectAll,
    required this.onDelete,
  });

  final bool selecting;
  final int selectedCount;
  final int totalCount;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StilloraSpacing.sm,
        StilloraSpacing.xs,
        StilloraSpacing.sm,
        0,
      ),
      child: selecting
          ? Row(
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(context.strings.cancel),
                ),
                const Spacer(),
                Text(
                  '$selectedCount selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
                TextButton.icon(
                  onPressed: onSelectAll,
                  icon: const Icon(Icons.select_all_rounded, size: 18),
                  label: Text(
                    selectedCount == totalCount
                        ? context.strings.galSelectNone
                        : context.strings.galSelectAll,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: context.strings.galDeleteSelected,
                  color: StilloraColors.error,
                ),
              ],
            )
          : Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.checklist_rounded, size: 18),
                label: Text(context.strings.galSelect),
              ),
            ),
    );
  }
}

/// Responsive poster-card grid used on desktop / wide windows.
class GalleryGrid extends StatelessWidget {
  const GalleryGrid({
    super.key,
    required this.items,
    required this.totalCount,
    required this.remaining,
    required this.onLoadMore,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final List<LocalExportRecord> items;
  final int totalCount;
  final int remaining;
  final VoidCallback onLoadMore;
  final bool selecting;
  final Set<String> selected;
  final void Function(LocalExportRecord) onTap;
  final void Function(String id) onLongPress;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(StilloraSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$totalCount ${totalCount == 1 ? 'video' : 'videos'}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Wrap(
            spacing: StilloraSpacing.sm,
            runSpacing: StilloraSpacing.sm,
            children: [
              for (final record in items)
                GalleryCard(
                  record: record,
                  selecting: selecting,
                  selected: selected.contains(record.id),
                  onTap: () => onTap(record),
                  onLongPress: () => onLongPress(record.id),
                ),
            ],
          ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: StilloraSpacing.sm),
              child: GalleryLoadMoreButton(
                remaining: remaining,
                onPressed: onLoadMore,
              ),
            ),
          const SizedBox(height: 16),
          const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
        ],
      ),
    );
  }
}
