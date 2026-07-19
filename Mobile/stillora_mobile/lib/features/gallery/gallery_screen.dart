import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_spacing.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/section_split_view.dart';
import 'gallery_controller.dart';
import 'gallery_download.dart';
import 'gallery_video_screen.dart';
import 'local_export_record.dart';
import 'widgets/gallery_browser_widgets.dart';
import 'widgets/gallery_cards.dart';

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

  /// Desktop only: the render shown in the right-hand preview pane. On phones a
  /// tap still pushes the full-screen player instead.
  LocalExportRecord? _preview;
  VideoPlayerController? _player;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _showInPane(LocalExportRecord record) async {
    if (_preview?.id == record.id) return;
    final previous = _player;
    setState(() {
      _preview = record;
      _player = null;
    });
    await previous?.dispose();
    final file = File(record.outputPath);
    if (!file.existsSync()) return;
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      return;
    }
    // The pane may have moved on (another card tapped, tab left) while the
    // player was initialising.
    if (!mounted || _preview?.id != record.id) {
      await controller.dispose();
      return;
    }
    await controller.setLooping(true);
    setState(() => _player = controller);
  }

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
        error: (_, _) => const GalleryEmpty(),
        data: (items) {
          if (items.isEmpty) return const GalleryEmpty();
          final visible = items.take(_visibleCount).toList();
          final remaining = items.length - visible.length;
          final browser = Column(
            children: [
              GallerySelectionBar(
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
                      return GalleryGrid(
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
                          GalleryTile(
                            record: record,
                            selecting: _selecting,
                            selected: _selected.contains(record.id),
                            onTap: () => _onTap(record),
                            onLongPress: () => _enterSelection(record.id),
                          ),
                          const SizedBox(height: StilloraSpacing.xs),
                        ],
                        if (remaining > 0)
                          GalleryLoadMoreButton(
                            remaining: remaining,
                            onPressed: _loadMore,
                          ),
                        const SizedBox(height: 16),
                        const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
                      ],
                    );
                  },
                ),
              ),
            ],
          );

          if (!useDesktopLayout(context)) return browser;

          // Desktop: the render grid stays on the left and the selected clip
          // plays in a pinned pane on the right, so browsing never leaves the
          // Library.
          return Padding(
            padding: const EdgeInsets.only(
              right: StilloraSpacing.sm,
              bottom: StilloraSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: browser),
                const SizedBox(width: StilloraSpacing.sm),
                SizedBox(
                  width: 400,
                  child: LivePreviewPanel(
                    caption: _preview == null
                        ? 'Pick a render to play it here'
                        : _preview!.outputPath.split(RegExp(r'[/\\]')).last,
                    actions: _preview == null
                        ? null
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GalleryDownloadButton(record: _preview!),
                              const SizedBox(height: StilloraSpacing.xs),
                              OutlinedButton.icon(
                                onPressed: () => _openFullScreen(_preview!),
                                icon: const Icon(
                                  Icons.open_in_full_rounded,
                                  size: 18,
                                ),
                                label: const Text('Open full screen'),
                              ),
                            ],
                          ),
                    child: GalleryPreview(record: _preview, player: _player),
                  ),
                ),
              ],
            ),
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
    if (useDesktopLayout(context)) {
      _showInPane(record);
      return;
    }
    _openFullScreen(record);
  }

  void _openFullScreen(LocalExportRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GalleryVideoScreen(record: record),
      ),
    );
  }
}
