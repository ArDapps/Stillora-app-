// `this.` is required to reach the engine's private fields and the sibling
// extension members that hold the split-out implementation.
// ignore_for_file: unnecessary_this

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

import '../editor/editor_state.dart';

part 'desktop_ffmpeg_helpers.dart';
part 'desktop_ffmpeg_overlay_exports.dart';
part 'desktop_ffmpeg_process.dart';
part 'desktop_ffmpeg_timeline_exports.dart';

class DesktopFfmpegVideoEngine implements engine.StilloraVideoEngine {
  final _progressController =
      StreamController<engine.ExportProgress>.broadcast();

  Process? _currentProcess;
  bool _cancelled = false;
  String? _ffmpegExecutable;

  @override
  Stream<engine.ExportProgress> get progressStream =>
      _progressController.stream;

  @override
  Future<engine.ExportResult> renderHtml({
    String? html,
    String? url,
    required int width,
    required int height,
    required int durationMs,
    int fps = 30,
    String? audioPath,
  }) {
    // HTML rendering needs a WebView, which only the native platform engine
    // provides — ffmpeg can't paint a page. Delegate to it.
    return engine.PlatformStilloraVideoEngine().renderHtml(
      html: html,
      url: url,
      width: width,
      height: height,
      durationMs: durationMs,
      fps: fps,
      audioPath: audioPath,
    );
  }

  @override
  Future<engine.ExportResult> exportVideo({
    required String imagePath,
    List<String> mediaPaths = const [],
    List<String> imagePaths = const [],
    List<int> clipDurations = const [],
    // Per-clip source-audio volume (0 = mute). Honoured when no external
    // soundtrack is attached: each video clip keeps its own sound scaled by
    // this. A soundtrack still replaces everything.
    List<double> clipVolumes = const [],
    String? audioPath,
    required int durationSeconds,
    required int width,
    required int height,
    engine.ResizeMode resizeMode = engine.ResizeMode.fit,
    engine.VideoEffect effect = engine.VideoEffect.none,
  }) {
    return this._exportVideoImpl(
      imagePath: imagePath,
      mediaPaths: mediaPaths,
      imagePaths: imagePaths,
      clipDurations: clipDurations,
      clipVolumes: clipVolumes,
      audioPath: audioPath,
      durationSeconds: durationSeconds,
      width: width,
      height: height,
      resizeMode: resizeMode,
      effect: effect,
    );
  }

  /// Composites a Reel: a black canvas with every layer scaled to its width
  /// fraction and overlaid at its normalised top-left, shorter videos looped to
  /// [durationSeconds], plus optional audio. Renders the real multi-layer design
  /// (positions/sizes/loop) — animated effects/transitions are not baked in.
  @override
  Future<engine.ExportResult> exportReel({
    required List<engine.ReelLayerSpec> layers,
    String? audioPath,
    required int width,
    required int height,
    required int durationSeconds,
    String effect = 'none',
    String transition = 'none',
    String mockup = 'none',
  }) {
    return this._exportReelImpl(
      layers: layers,
      audioPath: audioPath,
      width: width,
      height: height,
      durationSeconds: durationSeconds,
      effect: effect,
      transition: transition,
      mockup: mockup,
    );
  }

  /// Burns each overlay onto the base [videoPath] only within its time window
  /// (`enable='between(t,start,end)'`), keeping the base video's own audio.
  /// Output matches the source resolution and duration.
  @override
  Future<engine.ExportResult> exportWatermark({
    required String videoPath,
    required List<engine.WatermarkLayerSpec> overlays,
    required int width,
    required int height,
    required int durationSeconds,
    engine.ColorAdjustSpec color = const engine.ColorAdjustSpec(),
  }) {
    return this._exportWatermarkImpl(
      videoPath: videoPath,
      overlays: overlays,
      width: width,
      height: height,
      durationSeconds: durationSeconds,
      color: color,
    );
  }

  /// Blurs out each rectangular [regions] entry (crop → boxblur → overlay back),
  /// time-gated with `enable='between(t,start,end)'`, keeping the base audio.
  /// Used to hide burned-in watermarks (e.g. TikTok's moving logo).
  @override
  Future<engine.ExportResult> removeWatermark({
    required String videoPath,
    required List<engine.BlurRegionSpec> regions,
    required int width,
    required int height,
    required int durationSeconds,
  }) {
    return this._removeWatermarkImpl(
      videoPath: videoPath,
      regions: regions,
      width: width,
      height: height,
      durationSeconds: durationSeconds,
    );
  }

  @override
  Future<engine.ExportResult> removeSilence({
    required String videoPath,
    required int width,
    required int height,
    double thresholdDb = -35,
    int minSilenceMs = 400,
    int paddingMs = 100,
    int speed = 1,
    bool muteAudio = false,
    String? newAudioPath,
    int? maxOutputBytes,
  }) {
    return this._removeSilenceImpl(
      videoPath: videoPath,
      width: width,
      height: height,
      thresholdDb: thresholdDb,
      minSilenceMs: minSilenceMs,
      paddingMs: paddingMs,
      speed: speed,
      muteAudio: muteAudio,
      newAudioPath: newAudioPath,
      maxOutputBytes: maxOutputBytes,
    );
  }

  /// Bakes a colour grade onto [videoPath] in one pass, keeping its audio.
  /// The per-channel gains (`colorchannelmixer`) fold exposure + warmth + tint;
  /// `eq` applies brightness/contrast/saturation; `unsharp` sharpens. This is
  /// the same maths the Flutter live preview and macOS CoreImage pass use, so
  /// the export matches the preview.
  @override
  Future<engine.ExportResult> colorGrade({
    required String videoPath,
    required engine.ColorAdjustSpec adjust,
    required int width,
    required int height,
    required int durationSeconds,
  }) {
    return this._colorGradeImpl(
      videoPath: videoPath,
      adjust: adjust,
      width: width,
      height: height,
      durationSeconds: durationSeconds,
    );
  }

  @override
  Future<void> cancelExport() async {
    _cancelled = true;
    _currentProcess?.kill(ProcessSignal.sigterm);
  }

  @override
  Future<void> clearTemporaryFiles() async {
    final exportRoot = await this._exportRoot();
    if (!exportRoot.existsSync()) {
      return;
    }
    for (final entity in exportRoot.listSync()) {
      if (entity is Directory && entity.path.contains('work-')) {
        await entity.delete(recursive: true).catchError((_) => entity);
      }
    }
  }
}
