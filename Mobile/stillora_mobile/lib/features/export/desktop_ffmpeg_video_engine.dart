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
  Future<engine.ExportResult> exportVideo({
    required String imagePath,
    List<String> mediaPaths = const [],
    List<String> imagePaths = const [],
    List<int> clipDurations = const [],
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
              '/opt/homebrew/bin/ffmpeg',
              '/usr/local/bin/ffmpeg',
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
          'Desktop export requires FFmpeg, but Stillora could not find the bundled FFmpeg tool.',
    );
  }

  Iterable<String> _bundledFfmpegCandidates() sync* {
    final executable = File(Platform.resolvedExecutable);
    final executableDir = executable.parent;

    if (Platform.isMacOS) {
      // Stillora.app/Contents/MacOS/Stillora -> Stillora.app/Contents/Resources/ffmpeg
      final contentsDir = executableDir.parent;
      yield _join(_join(contentsDir.path, 'Resources'), 'ffmpeg');
      return;
    }

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
