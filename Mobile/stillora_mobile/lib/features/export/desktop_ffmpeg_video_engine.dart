import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

import '../editor/editor_state.dart';

class DesktopFfmpegVideoEngine implements engine.StilloraVideoEngine {
  final _progressController =
      StreamController<engine.ExportProgress>.broadcast();

  Process? _currentProcess;
  bool _cancelled = false;
  String? _ffmpegExecutable;

  @override
  Stream<engine.ExportProgress> get progressStream =>
      _progressController.stream;

  @override
  Future<engine.ExportResult> renderHtml({
    String? html,
    String? url,
    required int width,
    required int height,
    required int durationMs,
    int fps = 30,
    String? audioPath,
  }) {
    // HTML rendering needs a WebView, which only the native platform engine
    // provides — ffmpeg can't paint a page. Delegate to it.
    return engine.PlatformStilloraVideoEngine().renderHtml(
      html: html,
      url: url,
      width: width,
      height: height,
      durationMs: durationMs,
      fps: fps,
      audioPath: audioPath,
    );
  }

  @override
  Future<engine.ExportResult> exportVideo({
    required String imagePath,
    List<String> mediaPaths = const [],
    List<String> imagePaths = const [],
    List<int> clipDurations = const [],
    // Desktop segments are always rendered with `-an` (no source audio), so a
    // per-clip volume is a no-op here — clips are silent unless a soundtrack is
    // attached. Accepted to satisfy the shared engine interface.
    List<double> clipVolumes = const [],
    String? audioPath,
    required int durationSeconds,
    required int width,
    required int height,
    engine.ResizeMode resizeMode = engine.ResizeMode.fit,
    engine.VideoEffect effect = engine.VideoEffect.none,
  }) async {
    await _resolveFfmpeg();
    _cancelled = false;

    final exportRoot = await _exportRoot();
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final workDir = Directory(_join(exportRoot.path, 'work-$stamp'));
    await workDir.create(recursive: true);

    final timeline = mediaPaths.isEmpty ? [imagePath] : mediaPaths;
    final durations = _durationsFor(
      timeline.length,
      clipDurations,
      durationSeconds,
    );
    final outputPath = _join(exportRoot.path, 'stillora-$stamp.mp4');

    try {
      _emit(
        engine.ExportStage.preparingImage,
        0.05,
        'Preparing desktop export',
      );
      final segments = <String>[];
      for (var i = 0; i < timeline.length; i++) {
        final segmentPath = _join(workDir.path, 'segment-$i.mp4');
        await _renderSegment(
          sourcePath: timeline[i],
          outputPath: segmentPath,
          durationSeconds: durations[i],
          width: width,
          height: height,
          resizeMode: resizeMode,
        );
        segments.add(segmentPath);
        _emit(
          engine.ExportStage.generatingVideo,
          0.12 + (i + 1) / timeline.length * 0.58,
          'Rendered clip ${i + 1} of ${timeline.length}',
        );
      }

      final silentVideoPath = _join(workDir.path, 'timeline.mp4');
      await _concatSegments(segments, silentVideoPath, workDir);

      if (audioPath == null || audioPath.isEmpty) {
        _emit(engine.ExportStage.savingVideo, 0.9, 'Saving video');
        await File(silentVideoPath).copy(outputPath);
      } else {
        _emit(engine.ExportStage.mergingAudio, 0.78, 'Merging audio');
        await _mergeAudio(
          videoPath: silentVideoPath,
          audioPath: audioPath,
          outputPath: outputPath,
          durationSeconds: durations.fold(0, (sum, value) => sum + value),
        );
      }

      _emit(engine.ExportStage.done, 1, 'Export complete');
      return engine.ExportResult(
        outputPath: outputPath,
        width: width,
        height: height,
        durationSeconds: durations.fold(0, (sum, value) => sum + value),
      );
    } finally {
      await workDir.delete(recursive: true).catchError((_) => workDir);
    }
  }

  /// Composites a Reel: a black canvas with every layer scaled to its width
  /// fraction and overlaid at its normalised top-left, shorter videos looped to
  /// [durationSeconds], plus optional audio. Renders the real multi-layer design
  /// (positions/sizes/loop) — animated effects/transitions are not baked in.
  @override
  Future<engine.ExportResult> exportReel({
    required List<engine.ReelLayerSpec> layers,
    String? audioPath,
    required int width,
    required int height,
    required int durationSeconds,
    String effect = 'none',
    String transition = 'none',
    String mockup = 'none',
  }) async {
    await _resolveFfmpeg();
    _cancelled = false;
    final dur = durationSeconds < 1 ? 1 : durationSeconds;
    final exportRoot = await _exportRoot();
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final outputPath = _join(exportRoot.path, 'stillora-reel-$stamp.mp4');
    final hasAudio = audioPath != null && audioPath.isNotEmpty;

    _emit(engine.ExportStage.preparingImage, 0.05, 'Preparing reel');

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

    _emit(engine.ExportStage.generatingVideo, 0.4, 'Compositing layers');
    await _runFfmpeg(args);
    _emit(engine.ExportStage.done, 1, 'Reel export complete');
    return engine.ExportResult(
      outputPath: outputPath,
      width: width,
      height: height,
      durationSeconds: dur,
    );
  }

  /// Burns each overlay onto the base [videoPath] only within its time window
  /// (`enable='between(t,start,end)'`), keeping the base video's own audio.
  /// Output matches the source resolution and duration.
  @override
  Future<engine.ExportResult> exportWatermark({
    required String videoPath,
    required List<engine.WatermarkLayerSpec> overlays,
    required int width,
    required int height,
    required int durationSeconds,
    engine.ColorAdjustSpec color = const engine.ColorAdjustSpec(),
  }) async {
    await _resolveFfmpeg();
    _cancelled = false;
    final dur = durationSeconds < 1 ? 1 : durationSeconds;
    final exportRoot = await _exportRoot();
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final outputPath = _join(exportRoot.path, 'stillora-watermark-$stamp.mp4');

    _emit(engine.ExportStage.preparingImage, 0.05, 'Preparing watermark');

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
      filters.add('[${i + 1}:v]scale=w=$w:h=-2:flags=bicubic[s$i]');
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

    _emit(engine.ExportStage.generatingVideo, 0.4, 'Compositing watermark');
    await _runFfmpeg(args);
    _emit(engine.ExportStage.done, 1, 'Watermark export complete');
    return engine.ExportResult(
      outputPath: outputPath,
      width: width,
      height: height,
      durationSeconds: dur,
    );
  }

  @override
  Future<engine.ExportResult> removeSilence({
    required String videoPath,
    required int width,
    required int height,
    double thresholdDb = -35,
    int minSilenceMs = 400,
    int paddingMs = 100,
    int speed = 1,
    bool muteAudio = false,
    String? newAudioPath,
  }) async {
    await _resolveFfmpeg();
    _cancelled = false;
    final exportRoot = await _exportRoot();
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final workDir = Directory(_join(exportRoot.path, 'work-$stamp'));
    await workDir.create(recursive: true);
    final outputPath = _join(exportRoot.path, 'stillora-$stamp.mp4');

    final hasNewAudio =
        newAudioPath != null &&
        newAudioPath.isNotEmpty &&
        File(newAudioPath).existsSync();
    // The cut clip is silent whenever we mute or are swapping in a new track.
    final stripAudio = muteAudio || hasNewAudio;

    try {
      _emit(engine.ExportStage.preparingImage, 0.1, 'Analyzing audio');
      // 1. Detect silence + total duration from ffmpeg stderr.
      final log = await _runFfmpegCapture([
        '-i',
        videoPath,
        '-af',
        'silencedetect=noise=${thresholdDb}dB:d=${(minSilenceMs / 1000).toStringAsFixed(2)}',
        '-f',
        'null',
        '-',
      ]);
      final duration = _parseDuration(log);
      final keep = _keptRangesFromLog(log, duration, paddingMs / 1000.0);

      _emit(engine.ExportStage.generatingVideo, 0.35, 'Cutting silence');
      final filter = _videoFilter(width, height, engine.ResizeMode.fit);
      final segments = <String>[];
      for (var i = 0; i < keep.length; i++) {
        if (_cancelled) {
          throw PlatformException(
            code: 'export_cancelled',
            message: 'Cancelled.',
          );
        }
        final seg = _join(workDir.path, 'seg-$i.mp4');
        await _runFfmpeg([
          '-y',
          '-ss', '${keep[i].$1}',
          '-to', '${keep[i].$2}',
          '-i', videoPath,
          '-vf', filter,
          '-r', '30',
          '-c:v', 'libx264',
          '-pix_fmt', 'yuv420p',
          // Drop audio in the segments when muting / replacing the soundtrack.
          ...stripAudio ? ['-an'] : ['-c:a', 'aac'],
          '-movflags', '+faststart',
          seg,
        ]);
        segments.add(seg);
        _emit(
          engine.ExportStage.generatingVideo,
          0.35 + (i + 1) / keep.length * 0.5,
          'Segment ${i + 1} of ${keep.length}',
        );
      }

      // Destination of the cut (+ optionally sped) clip. With a replacement
      // soundtrack we render it to a temp first, then loop it under the audio.
      final cutFinal = hasNewAudio
          ? _join(workDir.path, 'cut.mp4')
          : outputPath;
      final preSpeedPath = speed > 1
          ? _join(workDir.path, 'concat.mp4')
          : cutFinal;
      if (segments.isEmpty) {
        await File(videoPath).copy(preSpeedPath);
      } else {
        await _concatSegments(segments, preSpeedPath, workDir);
      }

      var kept = keep.fold<double>(0, (s, r) => s + (r.$2 - r.$1));
      if (speed > 1) {
        _emit(engine.ExportStage.savingVideo, 0.9, 'Speeding up ${speed}x');
        await _runFfmpeg([
          '-y',
          '-i', preSpeedPath,
          '-filter_complex',
          // Speed the video; only speed the audio when keeping the original.
          stripAudio
              ? '[0:v]setpts=PTS/$speed[v]'
              : '[0:v]setpts=PTS/$speed[v];[0:a]${_atempoChain(speed)}[a]',
          '-map', '[v]',
          ...stripAudio ? ['-an'] : ['-map', '[a]', '-c:a', 'aac'],
          '-c:v', 'libx264',
          '-pix_fmt', 'yuv420p',
          '-movflags', '+faststart',
          cutFinal,
        ]);
        kept = kept / speed;
      }

      // Replacement soundtrack: loop the (silent) cut clip to the new audio's
      // length and mux the audio in at normal speed.
      if (hasNewAudio) {
        _emit(engine.ExportStage.mergingAudio, 0.92, 'Adding new audio');
        final audioLog = await _runFfmpegCapture([
          '-i',
          newAudioPath,
          '-f',
          'null',
          '-',
        ]);
        final audioDur = _parseDuration(audioLog);
        await _runFfmpeg([
          '-y',
          '-stream_loop',
          '-1',
          '-i',
          cutFinal,
          '-i',
          newAudioPath,
          if (audioDur > 0) ...['-t', audioDur.toStringAsFixed(3)],
          '-map',
          '0:v:0',
          '-map',
          '1:a:0',
          '-c:v',
          'libx264',
          '-pix_fmt',
          'yuv420p',
          '-c:a',
          'aac',
          if (audioDur <= 0) '-shortest',
          '-movflags',
          '+faststart',
          outputPath,
        ]);
        kept = audioDur > 0 ? audioDur : kept;
      }

      _emit(engine.ExportStage.done, 1, 'Done');
      return engine.ExportResult(
        outputPath: outputPath,
        width: width,
        height: height,
        durationSeconds: kept < 1 ? 1 : kept.round(),
      );
    } finally {
      await workDir.delete(recursive: true).catchError((_) => workDir);
    }
  }

  /// Complement of the detected silent intervals over [0, duration], padded and
  /// dropping tiny fragments.
  List<(double, double)> _keptRangesFromLog(
    String log,
    double duration,
    double paddingSec,
  ) {
    final starts = RegExp(
      r'silence_start:\s*([\d.]+)',
    ).allMatches(log).map((m) => double.parse(m.group(1)!)).toList();
    final ends = RegExp(
      r'silence_end:\s*([\d.]+)',
    ).allMatches(log).map((m) => double.parse(m.group(1)!)).toList();
    // Build kept ranges = gaps between silences.
    final kept = <(double, double)>[];
    var cursor = 0.0;
    for (var i = 0; i < starts.length; i++) {
      final sStart = starts[i];
      if (sStart > cursor) kept.add((cursor, sStart));
      cursor = i < ends.length ? ends[i] : duration;
    }
    if (cursor < duration) kept.add((cursor, duration));
    // pad + clamp + drop fragments < 0.1s
    return [
      for (final r in kept)
        if (r.$2 - r.$1 > 0.1)
          (
            (r.$1 - paddingSec).clamp(0, duration),
            (r.$2 + paddingSec).clamp(0, duration),
          ),
    ];
  }

  /// atempo only accepts 0.5..2.0, so chain factors to reach the target speed.
  String _atempoChain(int speed) {
    switch (speed) {
      case 2:
        return 'atempo=2.0';
      case 3:
        return 'atempo=1.5,atempo=2.0';
      case 4:
        return 'atempo=2.0,atempo=2.0';
      default:
        return 'atempo=1.0';
    }
  }

  double _parseDuration(String log) {
    final m = RegExp(r'Duration:\s*(\d+):(\d+):([\d.]+)').firstMatch(log);
    if (m == null) return 0;
    return int.parse(m.group(1)!) * 3600 +
        int.parse(m.group(2)!) * 60 +
        double.parse(m.group(3)!);
  }

  Future<String> _runFfmpegCapture(List<String> args) async {
    final process = await Process.start(await _resolveFfmpeg(), args);
    _currentProcess = process;
    final stderr = await process.stderr.transform(utf8.decoder).join();
    await process.stdout.drain<void>();
    await process.exitCode;
    _currentProcess = null;
    return stderr;
  }

  /// Bakes a colour grade onto [videoPath] in one pass, keeping its audio.
  /// The per-channel gains (`colorchannelmixer`) fold exposure + warmth + tint;
  /// `eq` applies brightness/contrast/saturation; `unsharp` sharpens. This is
  /// the same maths the Flutter live preview and macOS CoreImage pass use, so
  /// the export matches the preview.
  @override
  Future<engine.ExportResult> colorGrade({
    required String videoPath,
    required engine.ColorAdjustSpec adjust,
    required int width,
    required int height,
    required int durationSeconds,
  }) async {
    await _resolveFfmpeg();
    _cancelled = false;
    final exportRoot = await _exportRoot();
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final outputPath = _join(exportRoot.path, 'stillora-color-$stamp.mp4');

    _emit(engine.ExportStage.generatingVideo, 0.3, 'Applying colour grade');

    final filters = <String>[
      'colorchannelmixer='
          'rr=${_f(adjust.rGain)}:gg=${_f(adjust.gGain)}:bb=${_f(adjust.bGain)}',
      'eq=contrast=${_f(adjust.contrast)}:'
          'brightness=${_f(adjust.brightness)}:'
          'saturation=${_f(adjust.saturation)}',
      if (adjust.sharpness > 0)
        'unsharp=5:5:${_f(adjust.sharpness * 2.0)}:5:5:0',
      'format=yuv420p',
    ];

    await _runFfmpeg([
      '-y',
      '-i', videoPath,
      '-vf', filters.join(','),
      '-c:v', 'libx264',
      '-pix_fmt', 'yuv420p',
      // Keep the source audio untouched (optional — `?` tolerates silent video).
      '-c:a', 'copy',
      '-map', '0:v:0',
      '-map', '0:a:0?',
      '-movflags', '+faststart',
      outputPath,
    ]);

    _emit(engine.ExportStage.done, 1, 'Colour grade complete');
    return engine.ExportResult(
      outputPath: outputPath,
      width: width,
      height: height,
      durationSeconds: durationSeconds < 1 ? 1 : durationSeconds,
    );
  }

  /// Formats a double for an ffmpeg filter argument (trims to 4 dp, no exponent).
  String _f(double value) =>
      value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');

  @override
  Future<void> cancelExport() async {
    _cancelled = true;
    _currentProcess?.kill(ProcessSignal.sigterm);
  }

  @override
  Future<void> clearTemporaryFiles() async {
    final exportRoot = await _exportRoot();
    if (!exportRoot.existsSync()) {
      return;
    }
    for (final entity in exportRoot.listSync()) {
      if (entity is Directory && entity.path.contains('work-')) {
        await entity.delete(recursive: true).catchError((_) => entity);
      }
    }
  }

  Future<Directory> _exportRoot() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(_join(documents.path, 'Stillora Exports'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> _resolveFfmpeg() async {
    final resolved = _ffmpegExecutable;
    if (resolved != null) {
      return resolved;
    }

    final candidates = [
      ..._bundledFfmpegCandidates(),
      ...Platform.isWindows
          ? const ['ffmpeg.exe', 'ffmpeg']
          : const [
              'ffmpeg',
              '/opt/homebrew/bin/ffmpeg', // Apple-silicon Homebrew
              '/usr/local/bin/ffmpeg', // Intel Homebrew
              '/usr/bin/ffmpeg',
            ],
    ];

    for (final candidate in candidates) {
      try {
        final result = await Process.run(candidate, const ['-version']);
        if (result.exitCode == 0) {
          _ffmpegExecutable = candidate;
          return candidate;
        }
      } on ProcessException {
        // Try the next common executable path.
      }
    }

    throw PlatformException(
      code: 'ffmpeg_missing',
      message:
          'Windows and Linux desktop export require FFmpeg, but Stillora could not find the bundled FFmpeg tool or a PATH install.',
    );
  }

  Iterable<String> _bundledFfmpegCandidates() sync* {
    final executable = File(Platform.resolvedExecutable);
    final executableDir = executable.parent;

    if (Platform.isWindows) {
      yield _join(_join(executableDir.path, 'data'), 'ffmpeg.exe');
      return;
    }

    if (Platform.isLinux) {
      yield _join(_join(executableDir.path, 'data'), 'ffmpeg');
    }
  }

  Future<void> _renderSegment({
    required String sourcePath,
    required String outputPath,
    required int durationSeconds,
    required int width,
    required int height,
    required engine.ResizeMode resizeMode,
  }) {
    final mediaKind = mediaKindForPath(sourcePath);
    final filter = _videoFilter(width, height, resizeMode);
    final args = mediaKind == MediaKind.image
        ? [
            '-y',
            '-loop',
            '1',
            '-t',
            '$durationSeconds',
            '-i',
            sourcePath,
            '-vf',
            filter,
            '-r',
            '30',
            '-an',
            '-c:v',
            'libx264',
            '-pix_fmt',
            'yuv420p',
            '-movflags',
            '+faststart',
            outputPath,
          ]
        : [
            '-y',
            '-stream_loop',
            '-1',
            '-i',
            sourcePath,
            '-t',
            '$durationSeconds',
            '-vf',
            filter,
            '-r',
            '30',
            '-an',
            '-c:v',
            'libx264',
            '-pix_fmt',
            'yuv420p',
            '-movflags',
            '+faststart',
            outputPath,
          ];
    return _runFfmpeg(args);
  }

  Future<void> _concatSegments(
    List<String> segments,
    String outputPath,
    Directory workDir,
  ) async {
    if (segments.length == 1) {
      await File(segments.single).copy(outputPath);
      return;
    }

    final listPath = _join(workDir.path, 'segments.txt');
    final listFile = File(listPath);
    await listFile.writeAsString(
      segments.map((path) => "file '${_escapeConcatPath(path)}'").join('\n'),
    );
    await _runFfmpeg([
      '-y',
      '-f',
      'concat',
      '-safe',
      '0',
      '-i',
      listPath,
      '-c',
      'copy',
      outputPath,
    ]);
  }

  Future<void> _mergeAudio({
    required String videoPath,
    required String audioPath,
    required String outputPath,
    required int durationSeconds,
  }) {
    return _runFfmpeg([
      '-y',
      '-i',
      videoPath,
      '-stream_loop',
      '-1',
      '-i',
      audioPath,
      '-t',
      '$durationSeconds',
      '-map',
      '0:v:0',
      '-map',
      '1:a:0',
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-shortest',
      '-movflags',
      '+faststart',
      outputPath,
    ]);
  }

  Future<void> _runFfmpeg(List<String> args) async {
    Process? process;
    try {
      process = await Process.start(await _resolveFfmpeg(), args);
      _currentProcess = process;
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final stdoutFuture = process.stdout.drain<void>();
      final exitCode = await process.exitCode;
      final stderr = await stderrFuture;
      await stdoutFuture;

      if (_cancelled) {
        throw PlatformException(
          code: 'export_cancelled',
          message: 'Desktop export was cancelled.',
        );
      }
      if (exitCode != 0) {
        throw PlatformException(
          code: 'ffmpeg_failed',
          message: _lastFfmpegMessage(stderr),
        );
      }
    } on ProcessException catch (error) {
      throw PlatformException(code: 'ffmpeg_failed', message: error.message);
    } finally {
      if (_currentProcess == process) {
        _currentProcess = null;
      }
    }
  }

  List<int> _durationsFor(
    int count,
    List<int> clipDurations,
    int durationSeconds,
  ) {
    if (clipDurations.length == count) {
      return [
        for (final duration in clipDurations)
          normalizeDurationSeconds(duration),
      ];
    }
    if (count <= 1) {
      return [normalizeDurationSeconds(durationSeconds)];
    }
    final base = normalizeDurationSeconds(durationSeconds) ~/ count;
    final remainder = normalizeDurationSeconds(durationSeconds) - base * count;
    return [
      for (var i = 0; i < count; i++)
        normalizeDurationSeconds(base + (i < remainder ? 1 : 0)),
    ];
  }

  String _videoFilter(int width, int height, engine.ResizeMode resizeMode) {
    if (resizeMode == engine.ResizeMode.fill) {
      return 'scale=w=$width:h=$height:force_original_aspect_ratio=increase,'
          'crop=$width:$height,setsar=1';
    }
    return 'scale=w=$width:h=$height:force_original_aspect_ratio=decrease,'
        'pad=$width:$height:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1';
  }

  String _join(String directory, String child) {
    final separator = Platform.pathSeparator;
    return directory.endsWith(separator)
        ? '$directory$child'
        : '$directory$separator$child';
  }

  String _escapeConcatPath(String path) {
    return path.replaceAll(r'\', r'\\').replaceAll("'", r"'\''");
  }

  String _lastFfmpegMessage(String stderr) {
    final lines = stderr
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return 'FFmpeg could not complete the export.';
    }
    return lines.skip(lines.length > 4 ? lines.length - 4 : 0).join('\n');
  }

  void _emit(engine.ExportStage stage, double percentage, String message) {
    _progressController.add(
      engine.ExportProgress(
        stage: stage,
        percentage: percentage.clamp(0, 1),
        message: message,
      ),
    );
  }
}
