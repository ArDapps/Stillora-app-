import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
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

class GalleryView extends ConsumerWidget {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(galleryControllerProvider);

    return SafeArea(
      top: false,
      child: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _GalleryEmpty(),
        data: (items) {
          if (items.isEmpty) {
            return const _GalleryEmpty();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(StilloraSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: StilloraSpacing.xs),
            itemBuilder: (context, index) =>
                _GalleryTile(record: items[index]),
          );
        },
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.record});

  final LocalExportRecord record;

  @override
  Widget build(BuildContext context) {
    final date = record.createdAt;
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: VideoThumbnail(
          path: record.outputPath,
          width: 56,
          height: 56,
          radius: StilloraRadius.full,
        ),
        title: Text('${record.preset} · ${record.width}×${record.height}'),
        subtitle: Text('${record.durationSeconds}s · $dateLabel'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GalleryVideoScreen(record: record),
          ),
        ),
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
