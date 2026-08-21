import '../../core/i18n/app_strings.dart';

enum InputMode { paste, file, url }

/// An output canvas size offered for the HTML → MP4 render.
class SizeOption {
  const SizeOption(this.label, this.chip, this.ratio, this.width, this.height);
  final String label;
  final String chip;
  final String ratio;
  final int width;
  final int height;
  double get aspect => width / height;
}

extension SizeOptionMeta on SizeOption {
  /// Translated canvas name; the ratio doubles as the option's id.
  String labelOf(AppStrings s) => switch (ratio) {
    '9:16' => s.loopSizeLabel('vertical'),
    '1:1' => s.loopSizeLabel('square'),
    '16:9' => s.loopSizeLabel('landscape'),
    '4:5' => s.loopSizeLabel('portrait'),
    _ => label,
  };

  /// The chip over the preview — name plus ratio.
  String chipOf(AppStrings s) => '${labelOf(s)} · $ratio';
}

const sizeOptions = [
  SizeOption('Vertical', 'Vertical · 9:16', '9:16', 1080, 1920),
  SizeOption('Square', 'Square · 1:1', '1:1', 1080, 1080),
  SizeOption('Landscape', 'Landscape · 16:9', '16:9', 1920, 1080),
  SizeOption('Portrait', 'Portrait · 4:5', '4:5', 1080, 1350),
];

const fpsChoices = [24, 30, 60];
