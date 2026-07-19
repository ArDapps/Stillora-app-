part of 'desktop_ffmpeg_video_engine.dart';

// `this.` is required to reach the engine's private fields and the sibling
// extension members that hold the split-out implementation.
// ignore_for_file: unnecessary_this

/// Overlay-compositing exports (reel, watermark burn-in, watermark removal).
/// Bodies moved verbatim out of the engine class; the public `exportReel` /
/// `exportWatermark` / `removeWatermark` overrides delegate straight here.
extension DesktopFfmpegOverlayExports on DesktopFfmpegVideoEngine {
  Future<engine.ExportResult> _exportReelImpl({
    required List<engine.ReelLayerSpec> layers,
    String? audioPath,
    required int width,
    required int height,
    required int durationSeconds,
    String effect = 'none',
    String transition = 'none',
    String mockup = 'none',
  }) async {
    await this._resolveFfmpeg();
    this._cancelled = false;
    final dur = durationSeconds < 1 ? 1 : durationSeconds;
    final exportRoot = await this._exportRoot();
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final outputPath = _join(exportRoot.path, 'stillora-reel-$stamp.mp4');
    final hasAudio = audioPath != null && audioPath.isNotEmpty;

    this._emit(engine.ExportStage.preparingImage, 0.05, 'Preparing reel');

    final args = <String>['-y'];
    // Input 0: black background canvas.
    args.addAll([
      '-f',
      'lavfi',
      '-t',
      '$dur',
      '-i',
      'color=c=black:s=${width}x$height:r=30',
    ]);
    // Inputs 1..N: the layers (z-order).
    for (final layer in layers) {
      if (layer.isImage) {
        args.addAll(['-loop', '1', '-t', '$dur', '-i', layer.path]);
      } else {
        args.addAll(['-stream_loop', '-1', '-t', '$dur', '-i', layer.path]);
      }
    }
    if (hasAudio) {
      args.addAll(['-stream_loop', '-1', '-t', '$dur', '-i', audioPath]);
    }

    // Build the overlay filter graph.
    final filters = <String>[];
    for (var i = 0; i < layers.length; i++) {
      final w = (layers[i].scale * width).round().clamp(2, width * 4);
      filters.add('[${i + 1}:v]scale=w=$w:h=-2:flags=bicubic[s$i]');
    }
    var prev = '[0:v]';
    for (var i = 0; i < layers.length; i++) {
      final x = (layers[i].x * width).round();
      final y = (layers[i].y * height).round();
      final out = '[o$i]';
      // 3D objects (and any layer with a window) are gated to their voice span.
      final start = layers[i].start;
      final end = layers[i].end;
      final enable = (start != null || end != null)
          ? ":enable='between(t,"
                "${(start ?? 0).clamp(0, dur).toStringAsFixed(2)},"
                "${(end ?? dur).clamp(0, dur).toStringAsFixed(2)})'"
          : '';
      filters.add('$prev[s$i]overlay=x=$x:y=$y$enable$out');
      prev = out;
    }

    // Bakeable styles: glow (bloom) and fade transition. Other effects
    // (float/shake/Ken Burns) and transitions (swipe/zoom) stay preview-only.
    if (effect == 'glow') {
      filters.add('${prev}split[gA][gB]');
      filters.add('[gB]gblur=sigma=16[gBb]');
      filters.add('[gA][gBb]blend=all_mode=screen[gl]');
      prev = '[gl]';
    }
    if (transition == 'fade') {
      final fadeOutStart = (dur - 0.6) < 0 ? 0.0 : dur - 0.6;
      filters.add(
        '${prev}fade=t=in:st=0:d=0.5,'
        'fade=t=out:st=${fadeOutStart.toStringAsFixed(2)}:d=0.5[fx]',
      );
      prev = '[fx]';
    }
    filters.add('${prev}format=yuv420p[vout]');

    args.addAll(['-filter_complex', filters.join(';'), '-map', '[vout]']);
    if (hasAudio) {
      args.addAll(['-map', '${layers.length + 1}:a:0', '-c:a', 'aac']);
    }
    args.addAll([
      '-t',
      '$dur',
      '-r',
      '30',
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-movflags',
      '+faststart',
      outputPath,
    ]);

    this._emit(engine.ExportStage.generatingVideo, 0.4, 'Compositing layers');
    await this._runFfmpeg(args);
    this._emit(engine.ExportStage.done, 1, 'Reel export complete');
    return engine.ExportResult(
      outputPath: outputPath,
      width: width,
      height: height,
      durationSeconds: dur,
    );
  }

  Future<engine.ExportResult> _exportWatermarkImpl({
    required String videoPath,
    required List<engine.WatermarkLayerSpec> overlays,
    required int width,
    required int height,
    required int durationSeconds,
    engine.ColorAdjustSpec color = const engine.ColorAdjustSpec(),
  }) async {
    await this._resolveFfmpeg();
    this._cancelled = false;
    final dur = durationSeconds < 1 ? 1 : durationSeconds;
    final exportRoot = await this._exportRoot();
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final outputPath = _join(exportRoot.path, 'stillora-watermark-$stamp.mp4');

    this._emit(engine.ExportStage.preparingImage, 0.05, 'Preparing watermark');

    // Input 0: the base video (full length, its own audio).
    final args = <String>['-y', '-i', videoPath];
    // Inputs 1..N: the overlays, looped to cover their window.
    for (final o in overlays) {
      if (o.isImage) {
        args.addAll(['-loop', '1', '-t', '$dur', '-i', o.path]);
      } else {
        args.addAll(['-stream_loop', '-1', '-t', '$dur', '-i', o.path]);
      }
    }

    final filters = <String>[];
    for (var i = 0; i < overlays.length; i++) {
      var w = (overlays[i].scale * width).round();
      if (w.isOdd) w += 1;
      w = w.clamp(2, width * 4);
      // Ramp the overlay's own alpha in/out over its fade windows so it dissolves
      // rather than popping. The looped image input shares the output timeline
      // (both start at t=0), so the fade start times are the window times.
      final start = overlays[i].start.clamp(0.0, dur.toDouble());
      final end = overlays[i].end.clamp(start, dur.toDouble());
      final span = end - start;
      final fadeIn = overlays[i].fadeIn.clamp(0.0, span / 2);
      final fadeOut = overlays[i].fadeOut.clamp(0.0, span / 2);
      final parts = ['[${i + 1}:v]scale=w=$w:h=-2:flags=bicubic'];
      if (fadeIn > 0 || fadeOut > 0) {
        parts.add('format=yuva420p');
        if (fadeIn > 0) {
          parts.add(
            'fade=t=in:st=${start.toStringAsFixed(2)}:'
            'd=${fadeIn.toStringAsFixed(2)}:alpha=1',
          );
        }
        if (fadeOut > 0) {
          parts.add(
            'fade=t=out:st=${(end - fadeOut).toStringAsFixed(2)}:'
            'd=${fadeOut.toStringAsFixed(2)}:alpha=1',
          );
        }
      }
      filters.add('${parts.join(',')}[s$i]');
    }
    var prev = '[0:v]';
    for (var i = 0; i < overlays.length; i++) {
      final x = (overlays[i].x * width).round();
      final y = (overlays[i].y * height).round();
      final start = overlays[i].start.clamp(0.0, dur.toDouble());
      final end = overlays[i].end.clamp(start, dur.toDouble());
      final out = '[o$i]';
      filters.add(
        "$prev[s$i]overlay=x=$x:y=$y:"
        "enable='between(t,${start.toStringAsFixed(2)},${end.toStringAsFixed(2)})'$out",
      );
      prev = out;
    }
    // Bake the colour grade in the same pass (no-op when neutral) so there's no
    // separate re-encode. Same maths as the CoreImage/GL passes.
    if (!color.isIdentity) {
      filters.add(
        '${prev}colorchannelmixer='
        'rr=${_f(color.rGain)}:gg=${_f(color.gGain)}:bb=${_f(color.bGain)},'
        'eq=contrast=${_f(color.contrast)}:'
        'brightness=${_f(color.brightness)}:'
        'saturation=${_f(color.saturation)}'
        '${color.sharpness > 0 ? ',unsharp=5:5:${_f(color.sharpness * 2.0)}:5:5:0' : ''}'
        '[graded]',
      );
      prev = '[graded]';
    }
    filters.add('${prev}format=yuv420p[vout]');

    args.addAll(['-filter_complex', filters.join(';'), '-map', '[vout]']);
    // Keep the base video's audio when it has any (the `?` makes it optional).
    args.addAll(['-map', '0:a:0?', '-c:a', 'aac']);
    args.addAll([
      '-t',
      '$dur',
      '-r',
      '30',
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-movflags',
      '+faststart',
      outputPath,
    ]);

    this._emit(
      engine.ExportStage.generatingVideo,
      0.4,
      'Compositing watermark',
    );
    await this._runFfmpeg(args);
    this._emit(engine.ExportStage.done, 1, 'Watermark export complete');
    return engine.ExportResult(
      outputPath: outputPath,
      width: width,
      height: height,
      durationSeconds: dur,
    );
  }

  Future<engine.ExportResult> _removeWatermarkImpl({
    required String videoPath,
    required List<engine.BlurRegionSpec> regions,
    required int width,
    required int height,
    required int durationSeconds,
  }) async {
    await this._resolveFfmpeg();
    this._cancelled = false;
    final dur = durationSeconds < 1 ? 1 : durationSeconds;
    final exportRoot = await this._exportRoot();
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final outputPath = _join(exportRoot.path, 'stillora-unmark-$stamp.mp4');

    this._emit(engine.ExportStage.preparingImage, 0.05, 'Preparing');

    final args = <String>['-y', '-i', videoPath];
    final filters = <String>[];
    var prev = '[0:v]';

    for (var i = 0; i < regions.length; i++) {
      final r = regions[i];
      // Normalised region → even pixel rect clamped inside the frame (yuv420p
      // needs even crop offsets/sizes for chroma alignment).
      var x = _even((r.x.clamp(0.0, 1.0) * width).round());
      var y = _even((r.y.clamp(0.0, 1.0) * height).round());
      var w = _even((r.w.clamp(0.0, 1.0) * width).round()).clamp(2, width);
      var h = _even((r.h.clamp(0.0, 1.0) * height).round()).clamp(2, height);
      if (x + w > width) x = _even(width - w);
      if (y + h > height) y = _even(height - h);
      if (x < 0) x = 0;
      if (y < 0) y = 0;

      final minSide = w < h ? w : h;
      final maxRadius = (minSide / 2).floor() - 1;
      var radius = (r.strength.clamp(0.05, 1.0) * minSide / 2).round();
      radius = radius.clamp(1, maxRadius < 1 ? 1 : maxRadius);

      final start = r.start.clamp(0.0, dur.toDouble());
      final end = r.end.clamp(start, dur.toDouble());

      final base = '[b$i]';
      final copy = '[c$i]';
      final blurred = '[u$i]';
      final out = '[o$i]';
      // Duplicate the running frame, crop+blur the region on one copy, then
      // paint the blurred patch back over the original at (x,y) during [start,end].
      filters.add('${prev}split=2$base$copy');
      filters.add(
        '$copy'
        'crop=$w:$h:$x:$y,boxblur=$radius:2$blurred',
      );
      filters.add(
        "$base$blurred"
        "overlay=x=$x:y=$y:"
        "enable='between(t,${start.toStringAsFixed(2)},${end.toStringAsFixed(2)})'$out",
      );
      prev = out;
    }

    if (regions.isEmpty) {
      // Nothing to blur — still normalise/re-encode so the caller gets a file.
      filters.add('${prev}null[vpre]');
      prev = '[vpre]';
    }
    filters.add('${prev}format=yuv420p[vout]');

    args.addAll(['-filter_complex', filters.join(';'), '-map', '[vout]']);
    args.addAll(['-map', '0:a:0?', '-c:a', 'aac']);
    args.addAll([
      '-t',
      '$dur',
      '-r',
      '30',
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-movflags',
      '+faststart',
      outputPath,
    ]);

    this._emit(engine.ExportStage.generatingVideo, 0.4, 'Removing watermark');
    await this._runFfmpeg(args);
    this._emit(engine.ExportStage.done, 1, 'Watermark removed');
    return engine.ExportResult(
      outputPath: outputPath,
      width: width,
      height: height,
      durationSeconds: dur,
    );
  }
}
