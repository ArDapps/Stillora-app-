import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;
import 'package:video_player/video_player.dart';

import '../../core/platform/platform_info.dart';
import '../color/color_adjust.dart';
import '../color/color_grade_runner.dart';
import '../editor/editor_state.dart' show MediaKind, mediaKindForPath;
import '../editor/video_preset.dart';
import '../editor/local_editor_media_store.dart';
import '../export/export_controller.dart' show videoEngineProvider;
import '../gallery/gallery_controller.dart';
import '../gallery/local_export_record.dart';

const _wmVideoExtensions = {
  'mp4',
  'mov',
  'm4v',
  'webm',
  'avi',
  'mkv',
  '3gp',
  'm2ts',
};
const _wmImageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
const _wmOverlayExtensions = [..._wmImageExtensions, ..._wmVideoExtensions];

const defaultOverlayScale = 0.3;
const minOverlayScale = 0.05;
const maxOverlayScale = 2.0;

/// A logo / image / video laid over the base video (a watermark). Position is
/// the layer's normalised top-left (0..1); [scale] is its width as a fraction of
/// the frame width. [start]/[end] are the seconds within the base video during
/// which the overlay is visible.
class WatermarkOverlay extends Equatable {
  const WatermarkOverlay({
    required this.path,
    required this.kind,
    this.x = 0.06,
    this.y = 0.06,
    this.scale = defaultOverlayScale,
    this.start = 0,
    this.end = 0,
    this.sourceDurationSeconds,
  });

  factory WatermarkOverlay.fromPath(String path, {double end = 0}) =>
      WatermarkOverlay(
        path: path,
        kind: mediaKindForPath(path),
        end: end,
      );

  final String path;
  final MediaKind kind;
  final double x;
  final double y;
  final double scale;

  /// Visible window inside the base video, in seconds. The overlay is hidden
  /// before [start] and after [end].
  final double start;
  final double end;

  /// Measured length of a video overlay (null for images / not measured yet).
  final int? sourceDurationSeconds;

  bool get isVideo => kind == MediaKind.video;

  String get name {
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    return slash == -1 ? path : path.substring(slash + 1);
  }

  WatermarkOverlay copyWith({
    double? x,
    double? y,
    double? scale,
    double? start,
    double? end,
    int? sourceDurationSeconds,
  }) =>
      WatermarkOverlay(
        path: path,
        kind: kind,
        x: (x ?? this.x).clamp(0.0, 1.0),
        y: (y ?? this.y).clamp(0.0, 1.0),
        scale: (scale ?? this.scale).clamp(minOverlayScale, maxOverlayScale),
        start: start ?? this.start,
        end: end ?? this.end,
        sourceDurationSeconds:
            sourceDurationSeconds ?? this.sourceDurationSeconds,
      );

  /// Whether the overlay should be drawn at base playback position [seconds].
  bool isVisibleAt(double seconds) => seconds >= start && seconds < end;

  @override
  List<Object?> get props =>
      [path, kind, x, y, scale, start, end, sourceDurationSeconds];
}

class WatermarkState extends Equatable {
  const WatermarkState({
    this.baseVideoPath,
    this.baseWidth = 0,
    this.baseHeight = 0,
    this.baseDurationSeconds = 0,
    this.overlays = const [],
    this.selectedOverlay = 0,
    this.color = ColorAdjust.identity,
    this.quality,
  });

  final String? baseVideoPath;
  final int baseWidth;
  final int baseHeight;
  final int baseDurationSeconds;
  final List<WatermarkOverlay> overlays;
  final int selectedOverlay;

  /// Colour grade baked onto the watermarked video (desktop). Neutral default.
  final ColorAdjust color;

  /// Output resolution tier. `null` = Original (keep the source resolution).
  /// Otherwise the short edge is scaled to the tier (720p/1080p/2K/4K), aspect
  /// preserved so nothing is cropped.
  final ExportQuality? quality;

  bool get hasBase => baseVideoPath != null;
  bool get hasOverlays => overlays.isNotEmpty;
  bool get canExport => hasBase && hasOverlays;

  double get aspectRatio => (baseWidth > 0 && baseHeight > 0)
      ? baseWidth / baseHeight
      : 9 / 16;

  /// Output dimensions: the source size for Original, otherwise the source
  /// scaled to the chosen quality tier (short edge → tier, aspect preserved).
  /// The native engine re-derives the exact size from the video's true display
  /// aspect, so this is used for the on-screen estimate/label.
  ({int width, int height}) get outputResolution {
    final w = baseWidth > 0 ? baseWidth : 1080;
    final h = baseHeight > 0 ? baseHeight : 1920;
    final q = quality;
    if (q == null) {
      return (width: w - (w.isOdd ? 1 : 0), height: h - (h.isOdd ? 1 : 0));
    }
    return scaleDimensionsToQuality(w, h, q);
  }

  WatermarkState copyWith({
    String? baseVideoPath,
    bool clearBase = false,
    int? baseWidth,
    int? baseHeight,
    int? baseDurationSeconds,
    List<WatermarkOverlay>? overlays,
    int? selectedOverlay,
    ColorAdjust? color,
    ExportQuality? quality,
    bool clearQuality = false,
  }) =>
      WatermarkState(
        baseVideoPath: clearBase ? null : baseVideoPath ?? this.baseVideoPath,
        baseWidth: clearBase ? 0 : baseWidth ?? this.baseWidth,
        baseHeight: clearBase ? 0 : baseHeight ?? this.baseHeight,
        baseDurationSeconds:
            clearBase ? 0 : baseDurationSeconds ?? this.baseDurationSeconds,
        overlays: clearBase ? const [] : overlays ?? this.overlays,
        selectedOverlay: selectedOverlay ?? this.selectedOverlay,
        color: clearBase ? ColorAdjust.identity : color ?? this.color,
        quality: clearBase || clearQuality ? null : quality ?? this.quality,
      );

  @override
  List<Object?> get props => [
        baseVideoPath,
        baseWidth,
        baseHeight,
        baseDurationSeconds,
        overlays,
        selectedOverlay,
        color,
        quality,
      ];
}

final watermarkControllerProvider =
    NotifierProvider<WatermarkController, WatermarkState>(
  WatermarkController.new,
);

class WatermarkController extends Notifier<WatermarkState> {
  final _mediaStore = LocalEditorMediaStore();

  @override
  WatermarkState build() => const WatermarkState();

  /// Picks a single base video to watermark and measures its size + length.
  Future<void> pickBaseVideo() async {
    final path = await _pickVideoPath();
    if (path == null) return;
    final local = await _mediaStore.materializePath(
      path,
      kind: EditorMediaStoreKind.media,
    );
    if (local == null) return;
    // Reset overlays — they belong to the previous base's timeline.
    state = WatermarkState(baseVideoPath: local);
    final meta = await _readVideoMeta(local);
    if (state.baseVideoPath != local || meta == null) return;
    state = state.copyWith(
      baseWidth: meta.width,
      baseHeight: meta.height,
      baseDurationSeconds: meta.seconds,
    );
  }

  /// Picks one or more logos / images / videos and stacks them on the base.
  Future<void> addOverlays() async {
    if (!state.hasBase) return;
    final paths = await _pickOverlayPaths();
    if (paths.isEmpty) return;
    final existing = {for (final o in state.overlays) o.path};
    final fullWindow = state.baseDurationSeconds.toDouble();
    final additions = <WatermarkOverlay>[];
    for (final path in paths) {
      if (existing.contains(path)) continue;
      additions.add(WatermarkOverlay.fromPath(path, end: fullWindow));
    }
    if (additions.isEmpty) return;
    state = state.copyWith(
      overlays: [...state.overlays, ...additions],
      selectedOverlay: state.overlays.length,
    );
    for (final overlay in additions) {
      if (overlay.isVideo) unawaited(_measureOverlay(overlay.path));
    }
  }

  Future<void> _measureOverlay(String path) async {
    final meta = await _readVideoMeta(path);
    if (meta == null) return;
    final next = [
      for (final o in state.overlays)
        o.path == path ? o.copyWith(sourceDurationSeconds: meta.seconds) : o,
    ];
    state = state.copyWith(overlays: next);
  }

  void selectOverlay(int index) {
    if (index < 0 || index >= state.overlays.length) return;
    state = state.copyWith(selectedOverlay: index);
  }

  void removeOverlay(int index) {
    if (index < 0 || index >= state.overlays.length) return;
    final next = [...state.overlays]..removeAt(index);
    var selected = state.selectedOverlay;
    if (selected >= next.length) selected = next.isEmpty ? 0 : next.length - 1;
    state = state.copyWith(overlays: next, selectedOverlay: selected);
  }

  void setOverlayTransform(int index, double x, double y, double scale) {
    if (index < 0 || index >= state.overlays.length) return;
    final next = [...state.overlays];
    next[index] = next[index].copyWith(x: x, y: y, scale: scale);
    state = state.copyWith(overlays: next);
  }

  /// Sets a single overlay's visible window (seconds within the base video).
  void setOverlayWindow(int index, double start, double end) {
    if (index < 0 || index >= state.overlays.length) return;
    final maxEnd = state.baseDurationSeconds.toDouble();
    final clampedStart = start.clamp(0.0, maxEnd);
    final clampedEnd = end.clamp(clampedStart, maxEnd);
    final next = [...state.overlays];
    next[index] =
        next[index].copyWith(start: clampedStart, end: clampedEnd);
    state = state.copyWith(overlays: next);
  }

  /// Brings an overlay forward (drawn on top of later ones).
  void reorderOverlays(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.overlays.length) return;
    var target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (target < 0 || target >= state.overlays.length) return;
    final next = [...state.overlays];
    final moved = next.removeAt(oldIndex);
    next.insert(target, moved);
    state = state.copyWith(overlays: next, selectedOverlay: target);
  }

  void setColor(ColorAdjust color) => state = state.copyWith(color: color);

  /// Sets the output resolution tier. `null` = Original (keep source size).
  void setQuality(ExportQuality? quality) => state = quality == null
      ? state.copyWith(clearQuality: true)
      : state.copyWith(quality: quality);

  /// Aborts an in-flight export (and any colour-grade pass). The engine throws a
  /// cancellation error that [export]'s caller treats as a benign stop.
  Future<void> cancel() async {
    try {
      await ref.read(videoEngineProvider).cancelExport();
    } catch (_) {
      // Never let a cancel failure block the user.
    }
  }

  void reset() => state = const WatermarkState();

  /// Composites the base video with every overlay and saves it to the Library.
  ///
  /// Prefers the dedicated time-gated [engine.StilloraVideoEngine.exportWatermark]
  /// (each overlay shown only within its window, base audio kept) — implemented
  /// on FFmpeg desktop (Windows/Linux). Where that isn't implemented yet (macOS
  /// native), falls back to the reel compositor, which burns overlays in at
  /// their position/size but ignores the per-overlay timing. Throws on platforms
  /// without any overlay compositing (iOS/Android) so the UI can message it.
  Future<engine.ExportResult?> export() async {
    if (!state.canExport) return null;
    final basePaths =
        await _mediaStore.materializeMediaPaths([state.baseVideoPath!]);
    final overlayPaths = await _mediaStore
        .materializeMediaPaths(state.overlays.map((o) => o.path).toList());
    if (basePaths.isEmpty || overlayPaths.length != state.overlays.length) {
      return null;
    }
    final basePath = basePaths.first;
    final res = state.outputResolution;
    final duration =
        state.baseDurationSeconds <= 0 ? 5 : state.baseDurationSeconds;
    final videoEngine = ref.read(videoEngineProvider);

    debugPrint(
      '[Watermark] export base=${state.baseVideoPath} '
      'overlays=${state.overlays.length} ${res.width}x${res.height} '
      'engine=${videoEngine.runtimeType}',
    );

    engine.ExportResult result;
    try {
      // Colour grade is baked into this same pass (so every frame — including
      // the first second — is graded, and there's no second re-encode).
      result = await videoEngine.exportWatermark(
        videoPath: basePath,
        overlays: [
          for (var i = 0; i < state.overlays.length; i++)
            engine.WatermarkLayerSpec(
              path: overlayPaths[i],
              isImage: !state.overlays[i].isVideo,
              x: state.overlays[i].x,
              y: state.overlays[i].y,
              scale: state.overlays[i].scale,
              start: state.overlays[i].start,
              end: state.overlays[i].end,
            ),
        ],
        width: res.width,
        height: res.height,
        durationSeconds: duration,
        color: state.color.toSpec(),
      );
    } on MissingPluginException {
      // No native time-gated watermark yet — fall back to the reel compositor
      // (position/size only, overlays shown for the whole clip).
      debugPrint('[Watermark] export: FELL BACK to exportReel (no exportWatermark)');
      result = await videoEngine.exportReel(
        layers: [
          engine.ReelLayerSpec(
            path: basePath,
            isImage: false,
            x: 0,
            y: 0,
            scale: 1.0,
          ),
          for (var i = 0; i < state.overlays.length; i++)
            engine.ReelLayerSpec(
              path: overlayPaths[i],
              isImage: !state.overlays[i].isVideo,
              x: state.overlays[i].x,
              y: state.overlays[i].y,
              scale: state.overlays[i].scale,
            ),
        ],
        audioPath: basePath, // preserve the source video's audio
        width: res.width,
        height: res.height,
        durationSeconds: duration,
        effect: 'none',
        transition: 'none',
      );
      // The reel fallback can't bake colour, so grade it as a second pass here.
      result = await applyColorGrade(
        videoEngine: videoEngine,
        base: result,
        color: state.color,
      );
    }

    final now = DateTime.now();
    await ref.read(galleryControllerProvider.notifier).addRecord(
          LocalExportRecord(
            id: now.microsecondsSinceEpoch.toString(),
            outputPath: result.outputPath,
            preset: 'Watermark',
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
        allowedExtensions: _wmVideoExtensions.toList(),
      );
      return result?.files.single.path;
    }
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    return file?.path;
  }

  Future<List<String>> _pickOverlayPaths() async {
    final raw = await _pickRawOverlayPaths();
    return _mediaStore.materializeMediaPaths(raw);
  }

  Future<List<String>> _pickRawOverlayPaths() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final result = await pickImportFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _wmOverlayExtensions,
      );
      return [
        for (final file in result?.files ?? const <PlatformFile>[])
          if (file.path != null) file.path!,
      ];
    }
    final picker = ImagePicker();
    final files = await picker.pickMultipleMedia();
    return [for (final file in files) file.path];
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

/// True where the platform engine can bake overlay layers into the file today
/// (macOS native + FFmpeg desktop). iOS/Android lack overlay compositing.
bool get watermarkExportSupported =>
    useFfmpegDesktopExport ||
    (isApplePlatform && isDesktopPlatform); // macOS native exportReel
