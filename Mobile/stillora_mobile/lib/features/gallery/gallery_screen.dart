import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/video_thumbnail.dart';
import 'gallery_controller.dart';
import 'gallery_video_screen.dart';
import 'local_export_record.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  static const routePath = '/gallery';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: const GalleryView(),
    );
  }
}

class GalleryView extends ConsumerStatefulWidget {
  const GalleryView({super.key});

  @override
  ConsumerState<GalleryView> createState() => _GalleryViewState();
}

/// How many videos to reveal per page in the Library. The full list lives in
/// memory, but we only build thumbnails for the visible slice to keep large
/// libraries smooth.
const int _galleryPageSize = 20;

class _GalleryViewState extends ConsumerState<GalleryView> {
  final Set<String> _selected = {};
  bool _selecting = false;
  int _visibleCount = _galleryPageSize;

  void _loadMore() {
    setState(() => _visibleCount += _galleryPageSize);
  }

  void _enterSelection(String id) {
    setState(() {
      _selecting = true;
      _selected.add(id);
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
      if (_selected.isEmpty) _selecting = false;
    });
  }

  void _cancel() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _selectAll(List<LocalExportRecord> items) {
    setState(() {
      if (_selected.length == items.length) {
        _selected.clear();
        _selecting = false;
      } else {
        _selected
          ..clear()
          ..addAll(items.map((e) => e.id));
        _selecting = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete $count ${count == 1 ? 'video' : 'videos'}?'),
        content: const Text('This permanently removes them from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(galleryControllerProvider.notifier)
        .removeRecords(_selected.toSet());
    if (mounted) _cancel();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(galleryControllerProvider);

    return SafeArea(
      top: false,
      child: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _GalleryEmpty(),
        data: (items) {
          if (items.isEmpty) return const _GalleryEmpty();
          final visible = items.take(_visibleCount).toList();
          final remaining = items.length - visible.length;
          return Column(
            children: [
              _SelectionBar(
                selecting: _selecting,
                selectedCount: _selected.length,
                totalCount: items.length,
                onStart: () => setState(() => _selecting = true),
                onCancel: _cancel,
                onSelectAll: () => _selectAll(items),
                onDelete: _selected.isEmpty ? null : _deleteSelected,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 640;
                    if (wide) {
                      return _GalleryGrid(
                        items: visible,
                        totalCount: items.length,
                        remaining: remaining,
                        onLoadMore: _loadMore,
                        selecting: _selecting,
                        selected: _selected,
                        onTap: _onTap,
                        onLongPress: _enterSelection,
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.all(StilloraSpacing.sm),
                      children: [
                        for (final record in visible) ...[
                          _GalleryTile(
                            record: record,
                            selecting: _selecting,
                            selected: _selected.contains(record.id),
                            onTap: () => _onTap(record),
                            onLongPress: () => _enterSelection(record.id),
                          ),
                          const SizedBox(height: StilloraSpacing.xs),
                        ],
                        if (remaining > 0)
                          _LoadMoreButton(remaining: remaining, onPressed: _loadMore),
                        const SizedBox(height: 16),
                        const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onTap(LocalExportRecord record) {
    if (_selecting) {
      _toggle(record.id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GalleryVideoScreen(record: record),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
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
                TextButton(onPressed: onCancel, child: const Text('Cancel')),
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
                    selectedCount == totalCount ? 'None' : 'All',
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Delete selected',
                  color: StilloraColors.error,
                ),
              ],
            )
          : Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.checklist_rounded, size: 18),
                label: const Text('Select'),
              ),
            ),
    );
  }
}

/// Responsive poster-card grid used on desktop / wide windows.
class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({
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
                _GalleryCard(
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
              child: _LoadMoreButton(remaining: remaining, onPressed: onLoadMore),
            ),
          const SizedBox(height: 16),
          const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
        ],
      ),
    );
  }
}

/// "Load more" footer shown when the Library has more videos than are currently
/// revealed. Tapping reveals the next page.
class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.remaining, required this.onPressed});

  final int remaining;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: StilloraSpacing.sm),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          label: Text('Load more ($remaining)'),
        ),
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
    required this.record,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  static const _w = 236.0;
  static const _thumbH = 133.0; // 16:9

  final LocalExportRecord record;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final date = record.createdAt;
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return SizedBox(
      width: _w,
      child: Material(
        color: StilloraColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(StilloraRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  VideoThumbnail(
                    path: record.outputPath,
                    width: _w,
                    height: _thumbH,
                    radius: 0,
                  ),
                  if (selecting)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _SelectMark(selected: selected),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(StilloraSpacing.snug),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.preset} · ${record.width}×${record.height}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.durationSeconds}s · $dateLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: StilloraColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.record,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final LocalExportRecord record;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final date = record.createdAt;
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        selected: selected,
        leading: selecting
            ? _SelectMark(selected: selected)
            : VideoThumbnail(
                path: record.outputPath,
                width: 56,
                height: 56,
                radius: StilloraRadius.full,
              ),
        title: Text('${record.preset} · ${record.width}×${record.height}'),
        subtitle: Text('${record.durationSeconds}s · $dateLabel'),
        trailing: selecting
            ? null
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class _SelectMark extends StatelessWidget {
  const _SelectMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? StilloraColors.primary : Colors.black54,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      padding: const EdgeInsets.all(2),
      child: Icon(
        selected ? Icons.check_rounded : Icons.circle_outlined,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

class _GalleryEmpty extends StatelessWidget {
  const _GalleryEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(StilloraSpacing.md),
      children: [
        Text(
          'Local library',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Exports are stored on this phone. Nothing here depends on cloud storage.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StilloraSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Icon(
                  Icons.video_library_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Videos you convert on this phone will appear here. Convert a photo to get started.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
