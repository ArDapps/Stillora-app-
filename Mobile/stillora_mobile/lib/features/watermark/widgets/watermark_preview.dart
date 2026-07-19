import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/design/stillora_colors.dart';
import '../watermark_state.dart';

/// Plays the base video looping (muted) and overlays each layer on top. An
/// overlay is shown at full opacity while inside its time window and dimmed
/// outside it, so the timing is visible yet every layer stays editable.
class WatermarkPreview extends StatefulWidget {
  const WatermarkPreview({
    required this.wm,
    required this.onTransform,
    required this.onSelect,
  });

  final WatermarkState wm;
  final void Function(int index, double x, double y, double scale) onTransform;
  final ValueChanged<int> onSelect;

  @override
  State<WatermarkPreview> createState() => _WatermarkPreviewState();
}

class _WatermarkPreviewState extends State<WatermarkPreview> {
  VideoPlayerController? _base;
  String? _basePath;
  final Map<String, VideoPlayerController> _overlays = {};
  double _positionSeconds = 0;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant WatermarkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _onBaseTick() {
    final c = _base;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position.inMilliseconds / 1000.0;
    if ((pos - _positionSeconds).abs() >= 0.05) {
      setState(() => _positionSeconds = pos);
    }
  }

  void _sync() {
    // Base video.
    if (widget.wm.baseVideoPath != _basePath) {
      _base?.removeListener(_onBaseTick);
      _base?.dispose();
      _basePath = widget.wm.baseVideoPath;
      _base = null;
      _positionSeconds = 0;
      final path = _basePath;
      if (path != null) {
        final c = VideoPlayerController.file(File(path));
        _base = c;
        c
            .initialize()
            .then((_) {
              c.setLooping(true);
              c.setVolume(0);
              c.addListener(_onBaseTick);
              c.play();
              if (mounted) setState(() {});
            })
            .catchError((_) {});
      }
    }

    // Overlay videos.
    final wanted = {
      for (final o in widget.wm.overlays)
        if (o.isVideo) o.path,
    };
    for (final path in wanted) {
      if (_overlays.containsKey(path)) continue;
      final c = VideoPlayerController.file(File(path));
      _overlays[path] = c;
      c
          .initialize()
          .then((_) {
            c.setLooping(true);
            c.setVolume(0);
            c.play();
            if (mounted) setState(() {});
          })
          .catchError((_) {});
    }
    final stale = _overlays.keys
        .where((p) => !wanted.contains(p))
        .toList(growable: false);
    for (final path in stale) {
      _overlays.remove(path)?.dispose();
    }
  }

  @override
  void dispose() {
    _base?.removeListener(_onBaseTick);
    _base?.dispose();
    for (final c in _overlays.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wm = widget.wm;
    final overlays = wm.overlays;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            if (_base?.value.isInitialized ?? false)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _base!.value.size.width,
                    height: _base!.value.size.height,
                    child: VideoPlayer(_base!),
                  ),
                ),
              ),
            for (var i = 0; i < overlays.length; i++)
              Positioned(
                left: overlays[i].x * w,
                top: overlays[i].y * h,
                width: overlays[i].scale * w,
                child: OverlayBox(
                  key: ValueKey(overlays[i].path),
                  overlay: overlays[i],
                  controller: _overlays[overlays[i].path],
                  selected: i == wm.selectedOverlay,
                  visible: overlays[i].isVisibleAt(_positionSeconds),
                  frameWidth: w,
                  frameHeight: h,
                  onTap: () => widget.onSelect(i),
                  onUpdate: (x, y, scale) => widget.onTransform(i, x, y, scale),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A draggable + resizable overlay box. Drag anywhere to move; pinch or drag the
/// corner handle to resize. Dimmed when outside its time window.
class OverlayBox extends StatefulWidget {
  const OverlayBox({
    super.key,
    required this.overlay,
    required this.controller,
    required this.selected,
    required this.visible,
    required this.frameWidth,
    required this.frameHeight,
    required this.onTap,
    required this.onUpdate,
  });

  final WatermarkOverlay overlay;
  final VideoPlayerController? controller;
  final bool selected;
  final bool visible;
  final double frameWidth;
  final double frameHeight;
  final VoidCallback onTap;
  final void Function(double x, double y, double scale) onUpdate;

  @override
  State<OverlayBox> createState() => _OverlayBoxState();
}

class _OverlayBoxState extends State<OverlayBox> {
  double _startScale = 1;

  @override
  Widget build(BuildContext context) {
    final overlay = widget.overlay;
    final Widget media;
    if (overlay.isVideo) {
      final c = widget.controller;
      media = (c != null && c.value.isInitialized)
          ? AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))
          : const AspectRatio(
              aspectRatio: 1,
              child: ColoredBox(color: Colors.black26),
            );
    } else {
      media = Image.file(File(overlay.path), fit: BoxFit.contain);
    }

    // Outside its window the overlay is dimmed; the selected one stays a little
    // more visible so it can still be grabbed and positioned.
    final opacity = widget.visible
        ? 1.0
        : widget.selected
        ? 0.45
        : 0.18;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onScaleStart: (_) {
        widget.onTap();
        _startScale = widget.overlay.scale;
      },
      onScaleUpdate: (details) {
        final x =
            widget.overlay.x + details.focalPointDelta.dx / widget.frameWidth;
        final y =
            widget.overlay.y + details.focalPointDelta.dy / widget.frameHeight;
        final scale = _startScale * details.scale;
        widget.onUpdate(x, y, scale);
      },
      child: Opacity(
        opacity: opacity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.selected
                      ? StilloraColors.primary
                      : Colors.white,
                  width: widget.selected ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRect(child: media),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  final scale =
                      widget.overlay.scale + d.delta.dx / widget.frameWidth;
                  widget.onUpdate(widget.overlay.x, widget.overlay.y, scale);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: StilloraColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
