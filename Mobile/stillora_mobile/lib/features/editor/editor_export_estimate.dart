/// Export size estimation + formatting, shared by every export section.
/// Split out of `editor_state.dart` unchanged.
library;

/// Rough estimate of an exported MP4's size in bytes. Calibrated against real
/// exports: static slideshows compress far below the bitrate cap (low bpp),
/// while moving video footage runs much higher. Actual size also depends on the
/// codec the device uses (HEVC vs H.264). Shared by every export section.
int estimateExportBytes({
  required int width,
  required int height,
  required int durationSeconds,
  required bool hasVideo,
  required bool hasAudio,
  int fps = 30,
}) {
  final bpp = hasVideo ? 0.08 : 0.02;
  final videoBits = width * height * fps * bpp * durationSeconds;
  final audioBits = hasAudio ? 128000 * durationSeconds : 0;
  return ((videoBits + audioBits) / 8).round();
}

/// Human-readable file size (e.g. "1.5 MB", "320 KB", "1.2 GB").
String formatFileSize(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
  if (bytes >= mb) {
    final mbValue = bytes / mb;
    return '${mbValue.toStringAsFixed(mbValue >= 10 ? 0 : 1)} MB';
  }
  return '${(bytes / kb).round()} KB';
}
