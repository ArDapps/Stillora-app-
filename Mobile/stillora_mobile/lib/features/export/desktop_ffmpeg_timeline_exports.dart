part of 'desktop_ffmpeg_video_engine.dart';

// `this.` is required to reach the engine's private fields and the sibling
// extension members that hold the split-out implementation.
// ignore_for_file: unnecessary_this

/// Timeline-style exports (clip render + concat, silence removal / speed-up,
/// colour grade). Bodies moved verbatim out of the engine class; the public
/// overrides delegate straight here.
extension DesktopFfmpegTimelineExports on DesktopFfmpegVideoEngine {
  Future<engine.ExportResult> _exportVideoImpl({
    required String imagePath,
    List<String> mediaPaths = const [],
    List<String> imagePaths = const [],
    List<int> clipDurations = const [],
    List<double> clipVolumes = const [],
    String? audioPath,
    required int durationSeconds,
    required int width,
    required int height,
    engine.ResizeMode resizeMode = engine.ResizeMode.fit,
    engine.VideoEffect effect = engine.VideoEffect.none,
  }) async {
    await this._resolveFfmpeg();
    this._cancelled = false;

    final exportRoot = await this._exportRoot();
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
      this._emit(
        engine.ExportStage.preparingImage,
        0.05,
        'Preparing desktop export',
      );
      final segments = <String>[];
      for (var i = 0; i < timeline.length; i++) {
        final segmentPath = _join(workDir.path, 'segment-$i.mp4');
        await this._renderSegment(
          sourcePath: timeline[i],
          outputPath: segmentPath,
          durationSeconds: durations[i],
          width: width,
          height: height,
          resizeMode: resizeMode,
        );
        segments.add(segmentPath);
        this._emit(
          engine.ExportStage.generatingVideo,
          0.12 + (i + 1) / timeline.length * 0.58,
          'Rendered clip ${i + 1} of ${timeline.length}',
        );
      }

      final silentVideoPath = _join(workDir.path, 'timeline.mp4');
      await this._concatSegments(segments, silentVideoPath, workDir);

      if (audioPath == null || audioPath.isEmpty) {
        this._emit(engine.ExportStage.savingVideo, 0.9, 'Saving video');
        await File(silentVideoPath).copy(outputPath);
      } else {
        this._emit(engine.ExportStage.mergingAudio, 0.78, 'Merging audio');
        await this._mergeAudio(
          videoPath: silentVideoPath,
          audioPath: audioPath,
          outputPath: outputPath,
          durationSeconds: durations.fold(0, (sum, value) => sum + value),
        );
      }

      this._emit(engine.ExportStage.done, 1, 'Export complete');
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

  Future<engine.ExportResult> _removeSilenceImpl({
    required String videoPath,
    required int width,
    required int height,
    double thresholdDb = -35,
    int minSilenceMs = 400,
    int paddingMs = 100,
    int speed = 1,
    bool muteAudio = false,
    String? newAudioPath,
    int? maxOutputBytes,
  }) async {
    await this._resolveFfmpeg();
    this._cancelled = false;
    final exportRoot = await this._exportRoot();
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
      this._emit(engine.ExportStage.preparingImage, 0.1, 'Analyzing audio');
      // 1. Detect silence + total duration from ffmpeg stderr.
      final log = await this._runFfmpegCapture([
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

      this._emit(engine.ExportStage.generatingVideo, 0.35, 'Cutting silence');
      final filter = _videoFilter(width, height, engine.ResizeMode.fit);
      // When the caller caps the file size (the Compress section), switch the
      // encoder from its default CRF to average-bitrate mode targeting that
      // budget, so the output lands under [maxOutputBytes]. Empty otherwise, so
      // silence/speed exports keep their default quality.
      final bitrateArgs = _targetBitrateArgs(
        maxOutputBytes: maxOutputBytes,
        durationSeconds: duration,
        hasAudio: !stripAudio,
      );
      final segments = <String>[];
      for (var i = 0; i < keep.length; i++) {
        if (this._cancelled) {
          throw PlatformException(
            code: 'export_cancelled',
            message: 'Cancelled.',
          );
        }
        final seg = _join(workDir.path, 'seg-$i.mp4');
        await this._runFfmpeg([
          '-y',
          '-ss', '${keep[i].$1}',
          '-to', '${keep[i].$2}',
          '-i', videoPath,
          '-vf', filter,
          '-r', '30',
          '-c:v', 'libx264',
          ...bitrateArgs,
          '-pix_fmt', 'yuv420p',
          // Drop audio in the segments when muting / replacing the soundtrack.
          ...stripAudio ? ['-an'] : ['-c:a', 'aac'],
          '-movflags', '+faststart',
          seg,
        ]);
        segments.add(seg);
        this._emit(
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
        await this._concatSegments(segments, preSpeedPath, workDir);
      }

      var kept = keep.fold<double>(0, (s, r) => s + (r.$2 - r.$1));
      if (speed > 1) {
        this._emit(
          engine.ExportStage.savingVideo,
          0.9,
          'Speeding up ${speed}x',
        );
        await this._runFfmpeg([
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
        this._emit(engine.ExportStage.mergingAudio, 0.92, 'Adding new audio');
        final audioLog = await this._runFfmpegCapture([
          '-i',
          newAudioPath,
          '-f',
          'null',
          '-',
        ]);
        final audioDur = _parseDuration(audioLog);
        await this._runFfmpeg([
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

      this._emit(engine.ExportStage.done, 1, 'Done');
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

  Future<engine.ExportResult> _colorGradeImpl({
    required String videoPath,
    required engine.ColorAdjustSpec adjust,
    required int width,
    required int height,
    required int durationSeconds,
  }) async {
    await this._resolveFfmpeg();
    this._cancelled = false;
    final exportRoot = await this._exportRoot();
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final outputPath = _join(exportRoot.path, 'stillora-color-$stamp.mp4');

    this._emit(
      engine.ExportStage.generatingVideo,
      0.3,
      'Applying colour grade',
    );

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

    await this._runFfmpeg([
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

    this._emit(engine.ExportStage.done, 1, 'Colour grade complete');
    return engine.ExportResult(
      outputPath: outputPath,
      width: width,
      height: height,
      durationSeconds: durationSeconds < 1 ? 1 : durationSeconds,
    );
  }
}
