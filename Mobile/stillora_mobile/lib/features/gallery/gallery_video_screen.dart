import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_spacing.dart';
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

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  Future<void> _setUp() async {
    final controller = VideoPlayerController.file(File(widget.record.outputPath));
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

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
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
    final isPlaying = ready && controller.value.isPlaying;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(StilloraSpacing.sm),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: ready ? controller.value.aspectRatio : 9 / 16,
              child: ready
                  ? GestureDetector(
                      onTap: _togglePlayback,
                      child: Stack(
                        alignment: Alignment.center,
                        fit: StackFit.expand,
                        children: [
                          VideoPlayer(controller),
                          if (!isPlaying)
                            const ColoredBox(
                              color: Color(0x55000000),
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          FilledButton.icon(
            onPressed: ready ? _togglePlayback : null,
            icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            label: Text(isPlaying ? 'Pause' : 'Play'),
          ),
          const SizedBox(height: StilloraSpacing.xs),
          OutlinedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Save or Share'),
          ),
        ],
      ),
    );
  }
}
