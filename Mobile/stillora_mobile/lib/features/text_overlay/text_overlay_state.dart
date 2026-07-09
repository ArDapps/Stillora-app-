import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/platform/import_directory.dart';
import '../../core/platform/platform_info.dart';
import '../editor/local_editor_media_store.dart';
import '../editor/video_preset.dart';
import '../export/export_controller.dart' show videoEngineProvider;
import '../gallery/gallery_controller.dart';
import '../gallery/local_export_record.dart';
import 'text_layer_renderer.dart';

const _txtVideoExtensions = {
  'mp4',
  'mov',
  'm4v',
  'webm',
  'avi',
  'mkv',
  '3gp',
  'm2ts',
};

/// Font-size range as a fraction of the frame height (responsive across export
/// resolutions). 0.03 ≈ a caption, 0.16 ≈ a big title.
const minFontScale = 0.02;
const maxFontScale = 0.30;
const defaultFontScale = 0.09;

/// The curated font families offered in the picker. `null` = the platform's
/// default UI font. The preview and the export PNG both render through Flutter's
/// text engine with the same family, so the export always matches the preview
/// even when a family falls back.
const kTextFontFamilies = <(String label, String? family)>[
  ('Default', null),
  ('Sans', 'Helvetica'),
  ('Serif', 'Georgia'),
  ('Slab', 'Times New Roman'),
  ('Mono', 'Courier'),
];

/// Quick-start style presets (bonus): each seeds a new layer's look.
enum TextPreset { title, subtitle, caption, cta }

extension TextPresetX on TextPreset {
  String get label => switch (this) {
        TextPreset.title => 'Title',
        TextPreset.subtitle => 'Subtitle',
        TextPreset.caption => 'Caption',
        TextPreset.cta => 'CTA',
      };

  /// The default text shown when the preset seeds a fresh layer.
  String get seedText => switch (this) {
        TextPreset.title => 'Your Title',
        TextPreset.subtitle => 'Your subtitle here',
        TextPreset.caption => 'caption text',
        TextPreset.cta => 'Tap to learn more',
      };
}

/// One text overlay laid over the base video. [x]/[y] are the layer's normalised
/// **centre** (0..1) so dragging feels natural and the position survives an
/// export resolution change. [fontScale] is the font size as a fraction of the
/// frame height (responsive). [start]/[end] bound when it's visible and
/// [fadeIn]/[fadeOut] dissolve it in/out.
class TextLayer extends Equatable {
  const TextLayer({
    required this.id,
    this.text = 'Your text',
    this.x = 0.5,
    this.y = 0.5,
    this.fontScale = defaultFontScale,
    this.fontFamily,
    this.fontWeight = FontWeight.w700,
    this.color = Colors.white,
    this.backgroundColor,
    this.strokeWidth = 0,
    this.strokeColor = Colors.black,
    this.shadow = false,
    this.align = TextAlign.center,
    this.opacity = 1,
    this.start = 0,
    this.end = 0,
    this.fadeIn = 0.4,
    this.fadeOut = 0.4,
  });

  final String id;
  final String text;
  final double x;
  final double y;
  final double fontScale;
  final String? fontFamily;
  final FontWeight fontWeight;
  final Color color;

  /// Optional filled box behind the text (null = transparent).
  final Color? backgroundColor;

  /// Optional outline. 0 = no stroke.
  final double strokeWidth;
  final Color strokeColor;

  /// Optional soft drop shadow behind the text.
  final bool shadow;

  final TextAlign align;

  /// Constant layer opacity 0..1 (baked into the export); separate from the
  /// time-based [fadeIn]/[fadeOut] ramps.
  final double opacity;

  /// Visible window inside the base video, in seconds.
  final double start;
  final double end;

  /// Fade ramp lengths, in seconds (0 = a hard cut).
  final double fadeIn;
  final double fadeOut;

  TextLayer copyWith({
    String? text,
    double? x,
    double? y,
    double? fontScale,
    Object? fontFamily = _noChange,
    FontWeight? fontWeight,
    Color? color,
    Object? backgroundColor = _noChange,
    double? strokeWidth,
    Color? strokeColor,
    bool? shadow,
    TextAlign? align,
    double? opacity,
    double? start,
    double? end,
    double? fadeIn,
    double? fadeOut,
  }) =>
      TextLayer(
        id: id,
        text: text ?? this.text,
        x: (x ?? this.x).clamp(0.0, 1.0),
        y: (y ?? this.y).clamp(0.0, 1.0),
        fontScale:
            (fontScale ?? this.fontScale).clamp(minFontScale, maxFontScale),
        fontFamily: fontFamily == _noChange
            ? this.fontFamily
            : fontFamily as String?,
        fontWeight: fontWeight ?? this.fontWeight,
        color: color ?? this.color,
        backgroundColor: backgroundColor == _noChange
            ? this.backgroundColor
            : backgroundColor as Color?,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        strokeColor: strokeColor ?? this.strokeColor,
        shadow: shadow ?? this.shadow,
        align: align ?? this.align,
        opacity: (opacity ?? this.opacity).clamp(0.0, 1.0),
        start: start ?? this.start,
        end: end ?? this.end,
        fadeIn: fadeIn ?? this.fadeIn,
        fadeOut: fadeOut ?? this.fadeOut,
      );

  bool isVisibleAt(double seconds) => seconds >= start && seconds < end;

  /// The layer's opacity at playback position [seconds], folding the constant
  /// [opacity] with the fade ramps. Used to make the preview match the export.
  double opacityAt(double seconds) {
    if (seconds < start || seconds >= end) return 0;
    final span = end - start;
    final fi = fadeIn.clamp(0.0, span / 2);
    final fo = fadeOut.clamp(0.0, span / 2);
    var a = 1.0;
    if (fi > 0 && seconds < start + fi) a = (seconds - start) / fi;
    if (fo > 0 && seconds > end - fo) {
      a = a < (end - seconds) / fo ? a : (end - seconds) / fo;
    }
    return (a.clamp(0.0, 1.0)) * opacity;
  }

  @override
  List<Object?> get props => [
        id,
        text,
        x,
        y,
        fontScale,
        fontFamily,
        fontWeight,
        color,
        backgroundColor,
        strokeWidth,
        strokeColor,
        shadow,
        align,
        opacity,
        start,
        end,
        fadeIn,
        fadeOut,
      ];
}

const _noChange = Object();

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
  }) =>
      TextOverlayState(
        baseVideoPath: clearBase ? null : baseVideoPath ?? this.baseVideoPath,
        baseWidth: clearBase ? 0 : baseWidth ?? this.baseWidth,
        baseHeight: clearBase ? 0 : baseHeight ?? this.baseHeight,
        baseDurationSeconds:
            clearBase ? 0 : baseDurationSeconds ?? this.baseDurationSeconds,
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

final textOverlayControllerProvider =
    NotifierProvider<TextOverlayController, TextOverlayState>(
  TextOverlayController.new,
);

class TextOverlayController extends Notifier<TextOverlayState> {
  final _mediaStore = LocalEditorMediaStore();
  var _idSeed = 0;

  @override
  TextOverlayState build() => const TextOverlayState();

  String _nextId() => 't${_idSeed++}';

  Future<void> pickBaseVideo() async {
    final path = await _pickVideoPath();
    if (path == null) return;
    final local = await _mediaStore.materializePath(
      path,
      kind: EditorMediaStoreKind.media,
    );
    if (local == null) return;
    state = TextOverlayState(baseVideoPath: local);
    final meta = await _readVideoMeta(local);
    if (state.baseVideoPath != local || meta == null) return;
    state = state.copyWith(
      baseWidth: meta.width,
      baseHeight: meta.height,
      baseDurationSeconds: meta.seconds,
    );
  }

  /// Adds a new text layer, optionally seeded from a [preset]. It spans the
  /// whole clip by default and is centred on the frame.
  void addText([TextPreset? preset]) {
    if (!state.hasBase) return;
    final full = state.baseDurationSeconds.toDouble();
    final layer = _seedLayer(preset, full);
    state = state.copyWith(
      layers: [...state.layers, layer],
      selected: state.layers.length,
    );
  }

  TextLayer _seedLayer(TextPreset? preset, double fullWindow) {
    final id = _nextId();
    switch (preset) {
      case TextPreset.title:
        return TextLayer(
          id: id,
          text: preset!.seedText,
          y: 0.28,
          fontScale: 0.13,
          fontWeight: FontWeight.w900,
          shadow: true,
          end: fullWindow,
        );
      case TextPreset.subtitle:
        return TextLayer(
          id: id,
          text: preset!.seedText,
          y: 0.44,
          fontScale: 0.07,
          fontWeight: FontWeight.w600,
          shadow: true,
          end: fullWindow,
        );
      case TextPreset.caption:
        return TextLayer(
          id: id,
          text: preset!.seedText,
          y: 0.86,
          fontScale: 0.045,
          fontWeight: FontWeight.w500,
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          end: fullWindow,
        );
      case TextPreset.cta:
        return TextLayer(
          id: id,
          text: preset!.seedText,
          y: 0.8,
          fontScale: 0.06,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          backgroundColor: StilloraColors.accent,
          end: fullWindow,
        );
      case null:
        return TextLayer(id: id, end: fullWindow);
    }
  }

  void select(int index) {
    if (index < 0 || index >= state.layers.length) return;
    state = state.copyWith(selected: index);
  }

  void updateLayer(int index, TextLayer Function(TextLayer) transform) {
    if (index < 0 || index >= state.layers.length) return;
    final next = [...state.layers];
    next[index] = transform(next[index]);
    state = state.copyWith(layers: next);
  }

  void setTransform(int index, double x, double y) =>
      updateLayer(index, (l) => l.copyWith(x: x, y: y));

  void setWindow(int index, double start, double end) {
    final maxEnd = state.baseDurationSeconds.toDouble();
    final s = start.clamp(0.0, maxEnd);
    final e = end.clamp(s, maxEnd);
    updateLayer(index, (l) => l.copyWith(start: s, end: e));
  }

  void removeLayer(int index) {
    if (index < 0 || index >= state.layers.length) return;
    final next = [...state.layers]..removeAt(index);
    var sel = state.selected;
    if (sel >= next.length) sel = next.isEmpty ? 0 : next.length - 1;
    state = state.copyWith(layers: next, selected: sel);
  }

  /// Duplicates a layer (bonus), nudged slightly so it's visible under the copy.
  void duplicateLayer(int index) {
    if (index < 0 || index >= state.layers.length) return;
    final src = state.layers[index];
    final copy = src.copyWith(x: src.x + 0.04, y: src.y + 0.04);
    final dup = TextLayer(
      id: _nextId(),
      text: copy.text,
      x: copy.x,
      y: copy.y,
      fontScale: copy.fontScale,
      fontFamily: copy.fontFamily,
      fontWeight: copy.fontWeight,
      color: copy.color,
      backgroundColor: copy.backgroundColor,
      strokeWidth: copy.strokeWidth,
      strokeColor: copy.strokeColor,
      shadow: copy.shadow,
      align: copy.align,
      opacity: copy.opacity,
      start: copy.start,
      end: copy.end,
      fadeIn: copy.fadeIn,
      fadeOut: copy.fadeOut,
    );
    final next = [...state.layers]..insert(index + 1, dup);
    state = state.copyWith(layers: next, selected: index + 1);
  }

  /// Reorders layers (z-order — later layers draw on top).
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.layers.length) return;
    var target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (target < 0 || target >= state.layers.length) return;
    final next = [...state.layers];
    next.insert(target, next.removeAt(oldIndex));
    state = state.copyWith(layers: next, selected: target);
  }

  void setQuality(ExportQuality? quality) => state = quality == null
      ? state.copyWith(clearQuality: true)
      : state.copyWith(quality: quality);

  Future<void> cancel() async {
    try {
      await ref.read(videoEngineProvider).cancelExport();
    } catch (_) {}
  }

  void reset() => state = const TextOverlayState();

  /// Renders every text layer to a transparent PNG at the export resolution,
  /// then burns them onto the base video through the time-gated watermark
  /// pipeline (each with its own fade), keeping the base video's audio.
  Future<engine.ExportResult?> export() async {
    if (!state.canExport) return null;
    final basePaths =
        await _mediaStore.materializeMediaPaths([state.baseVideoPath!]);
    if (basePaths.isEmpty) return null;
    final basePath = basePaths.first;
    final res = state.outputResolution;
    final duration =
        state.baseDurationSeconds <= 0 ? 5 : state.baseDurationSeconds;

    // Render each layer to a PNG sized to the export frame, then map its
    // measured pixel box back to the pipeline's top-left + width-fraction form.
    final specs = <engine.WatermarkLayerSpec>[];
    for (final layer in state.layers) {
      if (layer.text.trim().isEmpty) continue;
      final png = await renderTextLayerToPng(
        layer,
        frameWidth: res.width,
        frameHeight: res.height,
      );
      if (png == null) continue;
      final widthFrac = png.pixelWidth / res.width;
      final heightFrac = png.pixelHeight / res.height;
      specs.add(
        engine.WatermarkLayerSpec(
          path: png.path,
          isImage: true,
          x: layer.x - widthFrac / 2,
          y: layer.y - heightFrac / 2,
          scale: widthFrac,
          start: layer.start,
          end: layer.end <= 0 ? duration.toDouble() : layer.end,
          fadeIn: layer.fadeIn,
          fadeOut: layer.fadeOut,
        ),
      );
    }
    if (specs.isEmpty) return null;

    final videoEngine = ref.read(videoEngineProvider);
    debugPrint(
      '[TextOverlay] export base=${state.baseVideoPath} '
      'layers=${specs.length} ${res.width}x${res.height} '
      'engine=${videoEngine.runtimeType}',
    );

    final result = await videoEngine.exportWatermark(
      videoPath: basePath,
      overlays: specs,
      width: res.width,
      height: res.height,
      durationSeconds: duration,
    );

    final now = DateTime.now();
    await ref.read(galleryControllerProvider.notifier).addRecord(
          LocalExportRecord(
            id: now.microsecondsSinceEpoch.toString(),
            outputPath: result.outputPath,
            preset: 'Text',
            width: result.width,
            height: result.height,
            durationSeconds: result.durationSeconds,
            createdAt: now,
          ),
        );
    return result;
  }

  Future<String?> _pickVideoPath() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final result = await pickImportFiles(
        type: FileType.custom,
        allowedExtensions: _txtVideoExtensions.toList(),
      );
      return result?.files.single.path;
    }
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    return file?.path;
  }

  Future<({int width, int height, int seconds})?> _readVideoMeta(
    String path,
  ) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final size = controller.value.size;
      final duration = controller.value.duration;
      if (size.width <= 0 || size.height <= 0) return null;
      final secs = (duration.inMilliseconds / 1000).round();
      return (
        width: size.width.round(),
        height: size.height.round(),
        seconds: secs < 1 ? 1 : secs,
      );
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }
}

/// True where the platform engine can burn text overlays into the file today:
/// macOS + iOS native (`exportWatermark` via a Core Animation overlay) and
/// FFmpeg desktop (Windows/Linux). Only Android still lacks a text compositor.
bool get textOverlayExportSupported =>
    useFfmpegDesktopExport || isApplePlatform;
