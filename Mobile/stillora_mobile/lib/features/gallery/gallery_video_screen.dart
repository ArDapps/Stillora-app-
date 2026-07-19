import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/platform/media_actions.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/stillora_video_player_panel.dart';
import 'gallery_controller.dart';
import 'gallery_download.dart';
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

  bool _saving = false;

  void _snack(String message, {bool offerSettings = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: offerSettings
            ? SnackBarAction(label: 'Settings', onPressed: openAppSettings)
            : null,
      ),
    );
  }

  Future<void> _share() async {
    final ok = await MediaActions.shareVideo(context, widget.record.outputPath);
    if (!ok) {
      _snack('That video is no longer available.');
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Shared with the Library's per-video download button so both routes
      // save identically.
      await downloadRecord(context, widget.record);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            // Desktop saves via a "Save As" dialog — there is no Camera Roll.
            label: Text(
              _saving
                  ? 'Saving…'
                  : isDesktopPlatform
                  ? 'Download'
                  : 'Save to Camera Roll',
            ),
          ),
          const SizedBox(height: StilloraSpacing.xs),
          OutlinedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
