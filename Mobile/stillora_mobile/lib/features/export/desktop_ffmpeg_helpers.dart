part of 'desktop_ffmpeg_video_engine.dart';

// Pure helpers for the desktop ffmpeg engine. Nothing here touches engine
// instance state — these are the same function bodies that used to live as
// private methods on [DesktopFfmpegVideoEngine], moved verbatim.

/// Rounds [value] down to the nearest even integer (min 0) — required for
/// yuv420p crop offsets/sizes.
int _even(int value) => value - (value % 2);

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

/// ffmpeg args that force average-bitrate encoding sized to fit
/// [maxOutputBytes] over [durationSeconds]. Returns an empty list when no cap
/// is requested (or the inputs are unusable), leaving the encoder on its
/// default CRF. Reserves ~128 kbps for audio when it's kept, and floors the
/// video bitrate so a tiny target can't produce an unplayable file.
List<String> _targetBitrateArgs({
  required int? maxOutputBytes,
  required double durationSeconds,
  required bool hasAudio,
}) {
  if (maxOutputBytes == null || maxOutputBytes <= 0 || durationSeconds <= 0) {
    return const [];
  }
  const audioBps = 128000;
  final totalBps = (maxOutputBytes * 8) / durationSeconds;
  var videoBps = (totalBps - (hasAudio ? audioBps : 0)).floor();
  if (videoBps < 100000) videoBps = 100000; // 100 kbps floor
  final maxrate = (videoBps * 1.2).round();
  final bufsize = videoBps * 2;
  return ['-b:v', '$videoBps', '-maxrate', '$maxrate', '-bufsize', '$bufsize'];
}

/// Formats a double for an ffmpeg filter argument (trims to 4 dp, no exponent).
String _f(double value) =>
    value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');

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

List<int> _durationsFor(
  int count,
  List<int> clipDurations,
  int durationSeconds,
) {
  if (clipDurations.length == count) {
    return [
      for (final duration in clipDurations) normalizeDurationSeconds(duration),
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
