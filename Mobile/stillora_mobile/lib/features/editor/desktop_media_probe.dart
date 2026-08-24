import 'dart:convert';
import 'dart:io';

/// Reads media durations on Linux/Windows desktop using a bundled or system
/// `ffprobe`. `video_player` has no desktop implementation there, so the editor
/// relies on this to learn an audio/video clip's length and fit the exported
/// video to it. Returns `null` when the duration can't be determined.
class DesktopMediaProbe {
  static String? _ffprobeExecutable;

  static Future<int?> durationSeconds(String path) async {
    final ffprobe = await _resolveFfprobe();
    if (ffprobe == null) {
      return null;
    }
    try {
      final result = await Process.run(ffprobe, [
        '-v',
        'quiet',
        '-print_format',
        'json',
        '-show_format',
        path,
      ]);
      if (result.exitCode != 0) {
        return null;
      }
      final decoded = jsonDecode(result.stdout as String);
      if (decoded is! Map) {
        return null;
      }
      final format = decoded['format'];
      if (format is! Map) {
        return null;
      }
      final raw = format['duration'];
      final seconds = raw is String
          ? double.tryParse(raw)
          : (raw is num ? raw.toDouble() : null);
      if (seconds == null || seconds <= 0) {
        return null;
      }
      return seconds.round();
    } catch (_) {
      return null;
    }
  }

  /// Native pixel size of a video's first video stream, or null when it can't
  /// be read. Used on Linux/Windows where `video_player` has no desktop plugin.
  static Future<({int width, int height})?> dimensions(String path) async {
    final ffprobe = await _resolveFfprobe();
    if (ffprobe == null) {
      return null;
    }
    try {
      final result = await Process.run(ffprobe, [
        '-v',
        'quiet',
        '-print_format',
        'json',
        '-select_streams',
        'v:0',
        '-show_entries',
        'stream=width,height',
        path,
      ]);
      if (result.exitCode != 0) {
        return null;
      }
      final decoded = jsonDecode(result.stdout as String);
      if (decoded is! Map) {
        return null;
      }
      final streams = decoded['streams'];
      if (streams is! List || streams.isEmpty) {
        return null;
      }
      final stream = streams.first;
      if (stream is! Map) {
        return null;
      }
      final w = stream['width'];
      final h = stream['height'];
      if (w is int && h is int && w > 0 && h > 0) {
        return (width: w, height: h);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _resolveFfprobe() async {
    final cached = _ffprobeExecutable;
    if (cached != null) {
      return cached;
    }
    for (final candidate in _candidates()) {
      try {
        final result = await Process.run(candidate, const ['-version']);
        if (result.exitCode == 0) {
          _ffprobeExecutable = candidate;
          return candidate;
        }
      } on ProcessException {
        // Try the next common executable path.
      }
    }
    return null;
  }

  static Iterable<String> _candidates() sync* {
    final executableDir = File(Platform.resolvedExecutable).parent;
    final separator = Platform.pathSeparator;
    if (Platform.isWindows) {
      yield '${executableDir.path}${separator}data${separator}ffprobe.exe';
      yield 'ffprobe.exe';
      yield 'ffprobe';
      return;
    }
    yield '${executableDir.path}${separator}data${separator}ffprobe';
    yield 'ffprobe';
    yield '/usr/bin/ffprobe';
  }
}
