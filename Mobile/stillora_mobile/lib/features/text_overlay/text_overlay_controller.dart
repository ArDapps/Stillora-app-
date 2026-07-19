import 'dart:async';
import 'dart:io';

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
import 'text_layer.dart';
import 'text_layer_renderer.dart';
import 'text_overlay_state.dart';

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
    final basePaths = await _mediaStore.materializeMediaPaths([
      state.baseVideoPath!,
    ]);
    if (basePaths.isEmpty) return null;
    final basePath = basePaths.first;
    final res = state.outputResolution;
    final duration = state.baseDurationSeconds <= 0
        ? 5
        : state.baseDurationSeconds;

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
    await ref
        .read(galleryControllerProvider.notifier)
        .addRecord(
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
