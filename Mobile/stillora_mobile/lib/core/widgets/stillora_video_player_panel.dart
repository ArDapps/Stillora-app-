import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';

class StilloraVideoPlayerPanel extends StatefulWidget {
  const StilloraVideoPlayerPanel({
    super.key,
    required this.controller,
    this.maxPreviewHeight = 340,
  });

  final VideoPlayerController? controller;
  final double maxPreviewHeight;

  @override
  State<StilloraVideoPlayerPanel> createState() =>
      _StilloraVideoPlayerPanelState();
}

class _StilloraVideoPlayerPanelState extends State<StilloraVideoPlayerPanel> {
  VideoPlayerController? _listenedController;

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(StilloraVideoPlayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detach(oldWidget.controller);
      _attach(widget.controller);
    }
  }

  @override
  void dispose() {
    _detach(_listenedController);
    super.dispose();
  }

  void _attach(VideoPlayerController? controller) {
    if (controller == null) {
      _listenedController = null;
      return;
    }
    _listenedController = controller;
    controller.addListener(_onPlayerChanged);
  }

  void _detach(VideoPlayerController? controller) {
    controller?.removeListener(_onPlayerChanged);
    if (_listenedController == controller) {
      _listenedController = null;
    }
  }

  void _onPlayerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePlayback() async {
    final controller = widget.controller;
    if (!_ready(controller)) {
      return;
    }
    if (controller!.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _seekRelative(Duration offset) async {
    final controller = widget.controller;
    if (!_ready(controller)) {
      return;
    }
    final duration = controller!.value.duration;
    final next = controller.value.position + offset;
    await controller.seekTo(_clampDuration(next, duration));
  }

  Future<void> _seekTo(double milliseconds) async {
    final controller = widget.controller;
    if (!_ready(controller)) {
      return;
    }
    await controller!.seekTo(Duration(milliseconds: milliseconds.round()));
  }

  bool _ready(VideoPlayerController? controller) {
    return controller != null && controller.value.isInitialized;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final ready = _ready(controller);
    final value = controller?.value;
    final duration = ready ? value!.duration : Duration.zero;
    final position = ready
        ? _clampDuration(value!.position, duration)
        : Duration.zero;
    final isPlaying = ready && value!.isPlaying;
    final aspectRatio = ready && value!.aspectRatio > 0
        ? value.aspectRatio
        : 9 / 16;
    final totalMs = duration.inMilliseconds.toDouble().clamp(
      1,
      double.infinity,
    );
    final positionMs = position.inMilliseconds.toDouble().clamp(0, totalMs);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StilloraColors.surfaceContainer.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        border: Border.all(color: StilloraColors.glassStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: widget.maxPreviewHeight,
                  maxWidth: 680,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(StilloraRadius.full),
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: ready
                        ? GestureDetector(
                            onTap: _togglePlayback,
                            child: Stack(
                              alignment: Alignment.center,
                              fit: StackFit.expand,
                              children: [
                                VideoPlayer(controller!),
                                if (!isPlaying)
                                  const ColoredBox(
                                    color: Color(0x55000000),
                                    child: Icon(
                                      Icons.play_circle_fill_rounded,
                                      size: 64,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Container(
                            alignment: Alignment.center,
                            color: StilloraColors.surfaceContainerHighest,
                            child: const CircularProgressIndicator(),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: StilloraSpacing.xs),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Restart',
                  onPressed: ready ? () => _seekTo(0) : null,
                  icon: const Icon(Icons.replay_rounded),
                ),
                IconButton(
                  tooltip: 'Back 5 seconds',
                  onPressed: ready
                      ? () => _seekRelative(const Duration(seconds: -5))
                      : null,
                  icon: const Icon(Icons.replay_5_rounded),
                ),
                IconButton.filled(
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: ready ? _togglePlayback : null,
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Forward 5 seconds',
                  onPressed: ready
                      ? () => _seekRelative(const Duration(seconds: 5))
                      : null,
                  icon: const Icon(Icons.forward_5_rounded),
                ),
                const Spacer(),
                Text(
                  '${_formatTime(position)} / ${_formatTime(duration)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Slider(
              value: positionMs.toDouble(),
              min: 0,
              max: totalMs.toDouble(),
              onChanged: ready ? _seekTo : null,
            ),
          ],
        ),
      ),
    );
  }
}

Duration _clampDuration(Duration value, Duration max) {
  if (value < Duration.zero) {
    return Duration.zero;
  }
  if (value > max) {
    return max;
  }
  return value;
}

String _formatTime(Duration duration) {
  final seconds = duration.inSeconds;
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}
