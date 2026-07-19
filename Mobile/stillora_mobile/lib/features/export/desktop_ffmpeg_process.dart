part of 'desktop_ffmpeg_video_engine.dart';

// `this.` is required to reach the engine's private fields and the sibling
// extension members that hold the split-out implementation.
// ignore_for_file: unnecessary_this

/// Process plumbing for the desktop ffmpeg engine: locating the binary, running
/// it, emitting progress, and the small render/concat/mux building blocks.
/// Split out of the engine class body verbatim; lives in the same library so it
/// still reaches the engine's private fields.
extension DesktopFfmpegProcessOps on DesktopFfmpegVideoEngine {
  Future<String> _runFfmpegCapture(List<String> args) async {
    final process = await Process.start(await this._resolveFfmpeg(), args);
    this._currentProcess = process;
    final stderr = await process.stderr.transform(utf8.decoder).join();
    await process.stdout.drain<void>();
    await process.exitCode;
    this._currentProcess = null;
    return stderr;
  }

  Future<Directory> _exportRoot() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(_join(documents.path, 'Stillora Exports'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> _resolveFfmpeg() async {
    final resolved = this._ffmpegExecutable;
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
          this._ffmpegExecutable = candidate;
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
    return this._runFfmpeg(args);
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
    await this._runFfmpeg([
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
    return this._runFfmpeg([
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
      process = await Process.start(await this._resolveFfmpeg(), args);
      this._currentProcess = process;
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final stdoutFuture = process.stdout.drain<void>();
      final exitCode = await process.exitCode;
      final stderr = await stderrFuture;
      await stdoutFuture;

      if (this._cancelled) {
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
      if (this._currentProcess == process) {
        this._currentProcess = null;
      }
    }
  }

  void _emit(engine.ExportStage stage, double percentage, String message) {
    this._progressController.add(
      engine.ExportProgress(
        stage: stage,
        percentage: percentage.clamp(0, 1),
        message: message,
      ),
    );
  }
}
