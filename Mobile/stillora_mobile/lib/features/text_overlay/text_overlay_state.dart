import 'package:equatable/equatable.dart';

import '../editor/video_preset.dart';
import 'text_layer.dart';

class TextOverlayState extends Equatable {
  const TextOverlayState({
    this.baseVideoPath,
    this.baseWidth = 0,
    this.baseHeight = 0,
    this.baseDurationSeconds = 0,
    this.layers = const [],
    this.selected = 0,
    this.quality,
  });

  final String? baseVideoPath;
  final int baseWidth;
  final int baseHeight;
  final int baseDurationSeconds;
  final List<TextLayer> layers;
  final int selected;

  /// Output resolution tier. `null` = keep the source resolution.
  final ExportQuality? quality;

  bool get hasBase => baseVideoPath != null;
  bool get hasLayers => layers.isNotEmpty;
  bool get canExport => hasBase && hasLayers;

  TextLayer? get selectedLayer =>
      (selected >= 0 && selected < layers.length) ? layers[selected] : null;

  double get aspectRatio =>
      (baseWidth > 0 && baseHeight > 0) ? baseWidth / baseHeight : 9 / 16;

  /// Output dimensions: the source size for Original, otherwise the source
  /// scaled to the chosen quality tier (short edge → tier, aspect preserved).
  ({int width, int height}) get outputResolution {
    final w = baseWidth > 0 ? baseWidth : 1080;
    final h = baseHeight > 0 ? baseHeight : 1920;
    final q = quality;
    if (q == null) {
      return (width: w - (w.isOdd ? 1 : 0), height: h - (h.isOdd ? 1 : 0));
    }
    return scaleDimensionsToQuality(w, h, q);
  }

  TextOverlayState copyWith({
    String? baseVideoPath,
    bool clearBase = false,
    int? baseWidth,
    int? baseHeight,
    int? baseDurationSeconds,
    List<TextLayer>? layers,
    int? selected,
    ExportQuality? quality,
    bool clearQuality = false,
  }) => TextOverlayState(
    baseVideoPath: clearBase ? null : baseVideoPath ?? this.baseVideoPath,
    baseWidth: clearBase ? 0 : baseWidth ?? this.baseWidth,
    baseHeight: clearBase ? 0 : baseHeight ?? this.baseHeight,
    baseDurationSeconds: clearBase
        ? 0
        : baseDurationSeconds ?? this.baseDurationSeconds,
    layers: clearBase ? const [] : layers ?? this.layers,
    selected: selected ?? this.selected,
    quality: clearBase || clearQuality ? null : quality ?? this.quality,
  );

  @override
  List<Object?> get props => [
    baseVideoPath,
    baseWidth,
    baseHeight,
    baseDurationSeconds,
    layers,
    selected,
    quality,
  ];
}
