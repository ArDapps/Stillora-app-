import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/widgets/stillora_video_player_panel.dart';
import 'gallery_controller.dart';
import 'local_export_record.dart';

class GalleryVideoScreen extends ConsumerStatefulWidget {
  const GalleryVideoScreen({super.key, required this.record});

  final LocalExportRecord record;

  @override
  ConsumerState<GalleryVideoScreen> createState() => _GalleryVideoScreenState();
}

class _GalleryVideoScreenState extends ConsumerState<GalleryVideoScreen> {
  VideoPlayerController? _controller;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  Future<void> _setUp() async {
    final controller = VideoPlayerController.file(
      File(widget.record.outputPath),
    );
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
    } catch (_) {
      // Fall back to a static frame if playback fails.
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(widget.record.outputPath, mimeType: 'video/mp4')],
        text: 'Made with Stillora',
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete local video?'),
          content: const Text(
            'This removes the video from your Stillora library and deletes the local file from this phone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted || _deleting) {
      return;
    }

    setState(() => _deleting = true);
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.pause();
      await controller.dispose();
    }

    await ref
        .read(galleryControllerProvider.notifier)
        .removeRecord(widget.record.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _deleting ? null : _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(StilloraSpacing.sm),
        children: [
          Text(
            '${widget.record.preset} · ${widget.record.width}×${widget.record.height}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.record.durationSeconds}s · Saved locally',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          StilloraVideoPlayerPanel(controller: controller),
          const SizedBox(height: StilloraSpacing.xs),
          OutlinedButton.icon(
            onPressed: ready ? _share : null,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Save or Share'),
          ),
        ],
      ),
    );
  }
}
