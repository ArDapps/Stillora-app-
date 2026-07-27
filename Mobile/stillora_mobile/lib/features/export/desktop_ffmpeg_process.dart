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

  /// True when the media file carries at least one audio stream. Uses ffmpeg
  /// itself (no separate ffprobe binary is bundled): `ffmpeg -i FILE` with no
  /// output writes the stream layout to stderr and exits non-zero, which
  /// `_runFfmpegCapture` tolerates.
  Future<bool> _hasAudioStream(String path) async {
    final log = await this._runFfmpegCapture(['-hide_banner', '-i', path]);
    return log.contains(RegExp(r'Stream #\d+:\d+.*: Audio:'));
  }

  /// Renders one timeline clip to [outputPath].
  ///
  /// When [keepAudio] is false the segment is silent (`-an`) — used when an
  /// external soundtrack replaces everything. When true, every segment is given
  /// exactly one stereo AAC track so the concat demuxer sees a uniform layout:
  /// a video clip contributes its own audio scaled by [volume] (or silence when
  /// muted / it has none), and an image contributes silence.
  Future<void> _renderSegment({
    required String sourcePath,
    required String outputPath,
    required int durationSeconds,
    required int width,
    required int height,
    required engine.ResizeMode resizeMode,
    bool keepAudio = false,
    double volume = 1.0,
  }) async {
    final isImage = mediaKindForPath(sourcePath) == MediaKind.image;
    final filter = _videoFilter(width, height, resizeMode);

    // A clip keeps its own sound only when it is a video, is not muted, and
    // actually has an audio track; otherwise it gets a silent stereo track so
    // concat still lines up.
    final useSourceAudio =
        keepAudio &&
        !isImage &&
        volume > 0 &&
        await this._hasAudioStream(sourcePath);

    final args = <String>['-y'];
    if (isImage) {
      args.addAll(['-loop', '1', '-t', '$durationSeconds', '-i', sourcePath]);
    } else {
      args.addAll([
        '-stream_loop',
        '-1',
        '-i',
        sourcePath,
        '-t',
        '$durationSeconds',
      ]);
    }
    // Silent filler input when this segment supplies no source audio of its own.
    if (keepAudio && !useSourceAudio) {
      args.addAll([
        '-f',
        'lavfi',
        '-t',
        '$durationSeconds',
        '-i',
        'anullsrc=channel_layout=stereo:sample_rate=44100',
      ]);
    }
    args.addAll(['-vf', filter, '-r', '30']);
    if (keepAudio) {
      args.addAll(['-map', '0:v:0']);
      if (useSourceAudio) {
        args.addAll(['-map', '0:a:0']);
        if (volume < 1.0) args.addAll(['-af', 'volume=${_f(volume)}']);
      } else {
        args.addAll(['-map', '1:a:0']);
      }
      args.addAll(['-c:a', 'aac', '-ar', '44100', '-ac', '2', '-shortest']);
    } else {
      args.add('-an');
    }
    args.addAll([
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-movflags',
      '+faststart',
      outputPath,
    ]);
    await this._runFfmpeg(args);
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
