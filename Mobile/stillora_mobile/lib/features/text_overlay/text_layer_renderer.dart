import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'text_overlay_state.dart';

/// A text layer rasterised to a transparent PNG, with the pixel box it occupies
/// so the caller can position it in the export frame.
class RenderedTextLayer {
  const RenderedTextLayer({
    required this.path,
    required this.pixelWidth,
    required this.pixelHeight,
  });

  final String path;
  final int pixelWidth;
  final int pixelHeight;
}

/// Builds the [TextStyle] used to draw [layer]'s fill at [fontSize] px. The
/// preview and the export share this so they look identical. [opacityScale]
/// lets the preview reuse the styling while applying fade separately (the
/// export bakes the constant opacity into the PNG instead).
TextStyle textLayerStyle(
  TextLayer layer, {
  required double fontSize,
  double opacityScale = 1,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: layer.fontWeight,
    fontFamily: layer.fontFamily,
    color: layer.color.withValues(alpha: layer.color.a * opacityScale),
    height: 1.15,
    shadows: layer.shadow
        ? [
            Shadow(
              blurRadius: fontSize * 0.14,
              offset: Offset(0, fontSize * 0.06),
              color: Colors.black.withValues(alpha: 0.6 * opacityScale),
            ),
          ]
        : null,
  );
}

/// Renders [layer] to a transparent PNG sized to fit its text at the export
/// resolution (font size = `layer.fontScale * frameHeight`). Returns the file
/// path plus the PNG's pixel dimensions. The constant [TextLayer.opacity] is
/// baked in here; the time-based fade is applied by the export engine.
Future<RenderedTextLayer?> renderTextLayerToPng(
  TextLayer layer, {
  required int frameWidth,
  required int frameHeight,
}) async {
  final text = layer.text;
  if (text.trim().isEmpty) return null;

  final fontSize = (layer.fontScale * frameHeight).clamp(4.0, frameHeight * 1.0);
  final op = layer.opacity.clamp(0.0, 1.0);

  final fillStyle = textLayerStyle(layer, fontSize: fontSize, opacityScale: op);

  TextPainter painter(TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: layer.align,
        textDirection: TextDirection.ltr,
        maxLines: null,
      )..layout(maxWidth: frameWidth.toDouble());

  final fill = painter(fillStyle);

  // Padding must cover the stroke, the shadow spill, and the background box so
  // nothing is clipped. Kept symmetric so the layer's centre stays put.
  final strokePad = layer.strokeWidth * fontSize * 0.5;
  final shadowPad = layer.shadow ? fontSize * 0.24 : 0.0;
  final bgPad = layer.backgroundColor != null ? fontSize * 0.28 : 0.0;
  final pad = (strokePad + shadowPad).clamp(0.0, fontSize * 2) + bgPad;

  final contentW = fill.width;
  final contentH = fill.height;
  final canvasW = (contentW + pad * 2).ceil();
  final canvasH = (contentH + pad * 2).ceil();
  if (canvasW <= 0 || canvasH <= 0) return null;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final origin = Offset(pad, pad);

  // 1) Background box behind the text.
  final bg = layer.backgroundColor;
  if (bg != null) {
    final rect = Rect.fromLTWH(
      origin.dx - bgPad,
      origin.dy - bgPad,
      contentW + bgPad * 2,
      contentH + bgPad * 2,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(fontSize * 0.18),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = bg.withValues(alpha: bg.a * op),
    );
  }

  // 2) Stroke/outline under the fill (drawn as text with a stroke paint).
  if (layer.strokeWidth > 0) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = layer.strokeWidth * fontSize * 0.5
      ..strokeJoin = StrokeJoin.round
      ..color = layer.strokeColor.withValues(alpha: layer.strokeColor.a * op);
    final strokePainter = painter(
      TextStyle(
        fontSize: fontSize,
        fontWeight: layer.fontWeight,
        fontFamily: layer.fontFamily,
        height: 1.15,
        foreground: strokePaint,
      ),
    );
    strokePainter.paint(canvas, origin);
  }

  // 3) The fill text on top.
  fill.paint(canvas, origin);

  final picture = recorder.endRecording();
  final image = await picture.toImage(canvasW, canvasH);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  if (bytes == null) return null;

  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/stillora_text_${layer.id}_'
    '${DateTime.now().microsecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

  return RenderedTextLayer(
    path: file.path,
    pixelWidth: canvasW,
    pixelHeight: canvasH,
  );
}
