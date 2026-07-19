/// The app's three duration formats, kept together so a caller picks one
/// deliberately instead of re-implementing it locally.

/// Verbose label: `45s`, `2m`, `2m 30s`. Used for clip/overlay time windows.
String formatDurationLabel(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '${m}m' : '${m}m ${s}s';
}

/// Compact label that drops to clock form only when there are leftover seconds:
/// `45s`, `2m`, `2:30`. Used by the duration slider.
String formatDurationShort(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '${m}m' : '$m:${s.toString().padLeft(2, '0')}';
}

/// Clock form, growing an hours field when needed: `45s`, `2:30`, `1:05:00`.
/// Used by the editor timeline and export stats.
String formatDurationClock(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  if (hours > 0) {
    final remainingMinutes = minutes % 60;
    return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }
  if (minutes == 0) {
    return '${seconds}s';
  }
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
