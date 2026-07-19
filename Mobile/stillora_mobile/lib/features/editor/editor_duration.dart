/// Duration constants and helpers shared by the editor state, the media items
/// and the duration controls. Split out of `editor_state.dart` unchanged.
library;

const defaultDurationSeconds = 10;
const minDurationSeconds = 1;
const defaultDurationSliderMaxSeconds = 300;

int normalizeDurationSeconds(num seconds) {
  final rounded = seconds.round();
  return rounded < minDurationSeconds ? minDurationSeconds : rounded;
}

/// Sliders are a quick-adjust tool, not a duration limit. Their range grows in
/// five-minute steps whenever a typed value or audio track exceeds the default.
double durationSliderMax(int seconds) {
  final normalized = normalizeDurationSeconds(seconds);
  if (normalized <= defaultDurationSliderMaxSeconds) {
    return defaultDurationSliderMaxSeconds.toDouble();
  }
  return ((normalized + defaultDurationSliderMaxSeconds - 1) ~/
          defaultDurationSliderMaxSeconds) *
      defaultDurationSliderMaxSeconds.toDouble();
}

int durationAdjustmentStep(int seconds) {
  if (seconds >= 600) {
    return 60;
  }
  if (seconds >= 60) {
    return 10;
  }
  return 1;
}
