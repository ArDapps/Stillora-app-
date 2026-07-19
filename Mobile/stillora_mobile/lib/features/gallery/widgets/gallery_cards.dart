import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/widgets/video_thumbnail.dart';
import '../local_export_record.dart';

/// "Load more" footer shown when the Library has more videos than are currently
/// revealed. Tapping reveals the next page.
class GalleryLoadMoreButton extends StatelessWidget {
  const GalleryLoadMoreButton({
    super.key,
    required this.remaining,
    required this.onPressed,
  });

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

class GalleryCard extends StatelessWidget {
  const GalleryCard({
    super.key,
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
                      child: GallerySelectMark(selected: selected),
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

class GalleryTile extends StatelessWidget {
  const GalleryTile({
    super.key,
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
            ? GallerySelectMark(selected: selected)
            : VideoThumbnail(
                path: record.outputPath,
                width: 56,
                height: 56,
                radius: StilloraRadius.full,
              ),
        title: Text('${record.preset} · ${record.width}×${record.height}'),
        subtitle: Text('${record.durationSeconds}s · $dateLabel'),
        trailing: selecting ? null : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class GallerySelectMark extends StatelessWidget {
  const GallerySelectMark({super.key, required this.selected});

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

class GalleryEmpty extends StatelessWidget {
  const GalleryEmpty({super.key});

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
