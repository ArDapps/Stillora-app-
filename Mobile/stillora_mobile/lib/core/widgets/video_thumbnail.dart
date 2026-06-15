import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../design/stillora_colors.dart';

/// Renders the FIRST FRAME of a local video file as a poster image, so lists of
/// exported MP4s are visually distinguishable. Uses video_player (works on
/// macOS, iOS and Android), initialises lazily and disposes on unmount.
class VideoThumbnail extends StatefulWidget {
  const VideoThumbnail({
    super.key,
    required this.path,
    this.width = 56,
    this.height = 56,
    this.radius = 12,
    this.showPlayIcon = true,
  });

  final String path;
  final double width;
  final double height;
  final double radius;
  final bool showPlayIcon;

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final file = File(widget.path);
    if (!file.existsSync()) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      await controller.seekTo(Duration.zero);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: StilloraColors.surfaceContainerHighest,
              ),
            ),
            if (_ready && controller != null)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else
              Center(
                child: _failed
                    ? const Icon(Icons.movie_outlined,
                        color: StilloraColors.onSurfaceVariant, size: 22)
                    : const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            if (widget.showPlayIcon && _ready)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 26,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
