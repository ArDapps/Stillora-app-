import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/design/stillora_colors.dart';
import '../text_layer.dart';
import '../text_layer_renderer.dart';
import '../text_overlay_state.dart';

/// Plays the base video (muted, looping) and draws every text layer on top,
/// applying each layer's fade at the current playback position so the preview
/// matches the export. The selected layer stays faintly visible even outside
/// its window so it can still be grabbed. Drag a layer to move it; centre-snap
/// guides appear when it lines up with the middle of the frame.
class TextOverlayPreview extends StatefulWidget {
  const TextOverlayPreview({
    super.key,
    required this.st,
    required this.onTransform,
    required this.onSelect,
  });

  final TextOverlayState st;
  final void Function(int index, double x, double y) onTransform;
  final ValueChanged<int> onSelect;

  @override
  State<TextOverlayPreview> createState() => _TextOverlayPreviewState();
}

class _TextOverlayPreviewState extends State<TextOverlayPreview> {
  VideoPlayerController? _base;
  String? _basePath;
  double _positionSeconds = 0;
  bool _snapV = false;
  bool _snapH = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant TextOverlayPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _onTick() {
    final c = _base;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position.inMilliseconds / 1000.0;
    if ((pos - _positionSeconds).abs() >= 0.04) {
      setState(() => _positionSeconds = pos);
    }
  }

  void _sync() {
    if (widget.st.baseVideoPath != _basePath) {
      _base?.removeListener(_onTick);
      _base?.dispose();
      _basePath = widget.st.baseVideoPath;
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
              c.addListener(_onTick);
              c.play();
              if (mounted) setState(() {});
            })
            .catchError((_) {});
      }
    }
  }

  @override
  void dispose() {
    _base?.removeListener(_onTick);
    _base?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final layers = st.layers;
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
            // Centre-snap alignment guides.
            if (_snapV)
              Positioned(
                left: w / 2 - 0.5,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: StilloraColors.secondary),
              ),
            if (_snapH)
              Positioned(
                top: h / 2 - 0.5,
                left: 0,
                right: 0,
                child: Container(height: 1, color: StilloraColors.secondary),
              ),
            for (var i = 0; i < layers.length; i++)
              DraggableText(
                key: ValueKey(layers[i].id),
                layer: layers[i],
                selected: i == st.selected,
                positionSeconds: _positionSeconds,
                frameWidth: w,
                frameHeight: h,
                onTap: () => widget.onSelect(i),
                onMove: (dx, dy) {
                  final rawX = layers[i].x + dx / w;
                  final rawY = layers[i].y + dy / h;
                  final snapV = (rawX - 0.5).abs() < 0.02;
                  final snapH = (rawY - 0.5).abs() < 0.02;
                  if (snapV != _snapV || snapH != _snapH) {
                    setState(() {
                      _snapV = snapV;
                      _snapH = snapH;
                    });
                  }
                  widget.onTransform(i, snapV ? 0.5 : rawX, snapH ? 0.5 : rawY);
                },
                onMoveEnd: () {
                  if (_snapV || _snapH) {
                    setState(() {
                      _snapV = false;
                      _snapH = false;
                    });
                  }
                },
              ),
          ],
        );
      },
    );
  }
}

/// A single text layer positioned by its normalised centre and draggable. Its
/// opacity tracks the fade at [positionSeconds]; the selected layer keeps a
/// faint minimum so it stays grabbable when it's outside its time window.
class DraggableText extends StatelessWidget {
  const DraggableText({
    super.key,
    required this.layer,
    required this.selected,
    required this.positionSeconds,
    required this.frameWidth,
    required this.frameHeight,
    required this.onTap,
    required this.onMove,
    required this.onMoveEnd,
  });

  final TextLayer layer;
  final bool selected;
  final double positionSeconds;
  final double frameWidth;
  final double frameHeight;
  final VoidCallback onTap;
  final void Function(double dx, double dy) onMove;
  final VoidCallback onMoveEnd;

  @override
  Widget build(BuildContext context) {
    final fontSize = layer.fontScale * frameHeight;
    final fadeOpacity = layer.opacityAt(positionSeconds);
    final opacity = fadeOpacity > 0 ? fadeOpacity : (selected ? 0.35 : 0.0);

    final bg = layer.backgroundColor;
    Widget textWidget = Text(
      layer.text.isEmpty ? ' ' : layer.text,
      textAlign: layer.align,
      style: textLayerStyle(layer, fontSize: fontSize),
    );
    if (layer.strokeWidth > 0) {
      // Cheap outline for the preview: a stroked copy stacked under the fill.
      textWidget = Stack(
        children: [
          Text(
            layer.text.isEmpty ? ' ' : layer.text,
            textAlign: layer.align,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: layer.fontWeight,
              fontFamily: layer.fontFamily,
              height: 1.15,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = layer.strokeWidth * fontSize * 0.5
                ..strokeJoin = StrokeJoin.round
                ..color = layer.strokeColor,
            ),
          ),
          textWidget,
        ],
      );
    }
    if (bg != null) {
      textWidget = Container(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.28,
          vertical: fontSize * 0.16,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(fontSize * 0.18),
        ),
        child: textWidget,
      );
    }

    return Positioned(
      left: layer.x * frameWidth,
      top: layer.y * frameHeight,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        // A fully-invisible layer (not selected, outside its window) must not
        // intercept drags meant for the layers beneath it.
        child: IgnorePointer(
          ignoring: opacity <= 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onPanStart: (_) => onTap(),
            onPanUpdate: (d) => onMove(d.delta.dx, d.delta.dy),
            onPanEnd: (_) => onMoveEnd(),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                decoration: selected
                    ? BoxDecoration(
                        border: Border.all(
                          color: StilloraColors.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                padding: const EdgeInsets.all(4),
                child: textWidget,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
