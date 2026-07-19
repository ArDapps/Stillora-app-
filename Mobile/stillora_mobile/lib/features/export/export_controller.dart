import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/platform/platform_info.dart';
import '../color/color_grade_runner.dart';
import '../editor/editor_state.dart';
import '../editor/video_styles.dart';
import '../gallery/gallery_controller.dart';
import '../gallery/local_export_record.dart';
import 'desktop_ffmpeg_video_engine.dart';

final videoEngineProvider = Provider<engine.StilloraVideoEngine>((ref) {
  if (useFfmpegDesktopExport) {
    return DesktopFfmpegVideoEngine();
  }
  return engine.PlatformStilloraVideoEngine();
});

final exportControllerProvider =
    AsyncNotifierProvider<ExportController, engine.ExportResult?>(
      ExportController.new,
    );

class ExportController extends AsyncNotifier<engine.ExportResult?> {
  bool _cancelled = false;

  @override
  FutureOr<engine.ExportResult?> build() => null;

  Future<void> start(EditorState editor) async {
    if (!editor.canExport) {
      throw StateError('Select media before exporting.');
    }

    _cancelled = false;
    state = const AsyncLoading();
    final videoEngine = ref.read(videoEngineProvider);
    EditorState? preparedEditor;

    // NOTE: export progress is delivered over an EventChannel
    // (`stillora_video_engine/progress`). Subscribing to it activates the
    // channel, which raises a MissingPluginException via the framework zone
    // until the native engine implements it. Re-add the subscription here once
    // the iOS/Android engine is in place.

    state = await AsyncValue.guard(() async {
      final exportEditor = await ref
          .read(editorControllerProvider.notifier)
          .prepareForExport();
      preparedEditor = exportEditor;
      final base = await videoEngine.exportVideo(
        imagePath: exportEditor.imagePath!,
        mediaPaths: exportEditor.mediaPaths,
        imagePaths: exportEditor.imagePaths,
        clipDurations: exportEditor.clipDurations,
        clipVolumes: exportEditor.clipVolumes,
        audioPath: exportEditor.audioPath,
        durationSeconds: exportEditor.totalDurationSeconds,
        // Aspect ratio comes from the preset; pixel size from the chosen
        // quality (720p / 1080p / 2K / 4K) so users can trade file size for
        // sharpness.
        width: exportEditor.outputResolution.width,
        height: exportEditor.outputResolution.height,
        resizeMode: exportEditor.resizeMode == ResizeMode.fit
            ? engine.ResizeMode.fit
            : engine.ResizeMode.fill,
      );

      // When a style is set, run a second pass that bakes the glow/fade onto the
      // finished video (the base output becomes a single full-frame layer).
      // Skipped gracefully where the platform engine can't composite.
      final styled =
          exportEditor.effect != ClipEffect.none ||
          exportEditor.transition != FrameTransition.none;
      var produced = base;
      if (styled) {
        try {
          final result = await videoEngine.exportReel(
            layers: [
              engine.ReelLayerSpec(
                path: base.outputPath,
                isImage: false,
                x: 0,
                y: 0,
                scale: 1.0,
              ),
            ],
            audioPath: base.outputPath,
            width: base.width,
            height: base.height,
            durationSeconds: base.durationSeconds,
            effect: exportEditor.effect.name,
            transition: exportEditor.transition.name,
          );
          try {
            File(base.outputPath).deleteSync();
          } catch (_) {}
          produced = result;
        } on MissingPluginException {
          produced = base;
        }
      }
      // Final pass: bake the colour grade (no-op when neutral / unsupported).
      return applyColorGrade(
        videoEngine: videoEngine,
        base: produced,
        color: exportEditor.color,
      );
    });

    // A user-initiated cancel resolves to a benign idle state, not an error.
    if (_cancelled) {
      state = const AsyncData(null);
      return;
    }

    final result = state.value;
    if (result != null) {
      final exportEditor = preparedEditor ?? editor;
      await ref
          .read(galleryControllerProvider.notifier)
          .addRecord(
            LocalExportRecord(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              outputPath: result.outputPath,
              preset: exportEditor.preset.label,
              width: result.width,
              height: result.height,
              durationSeconds: result.durationSeconds,
              createdAt: DateTime.now(),
            ),
          );
      // Report the local export to the backend so it shows in the admin
      // dashboard alongside web activity. Telemetry only — never block export.
      unawaited(_reportExport(exportEditor, result));
    }
  }

  /// Tells the shared backend an export completed so every app's activity is
  /// reflected in the admin dashboard. Native apps export on-device and never
  /// hit `/api/exports`, so this is the only signal the server gets.
  Future<void> _reportExport(
    EditorState editor,
    engine.ExportResult result,
  ) async {
    try {
      final token = ref.read(authControllerProvider).asData?.value?.token;
      if (token == null) {
        return;
      }
      await ref
          .read(dioProvider)
          .post<void>(
            '/api/exports/record',
            data: {
              'presetId': editor.preset.id,
              'duration': result.durationSeconds,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
    } catch (_) {
      // Telemetry must never disrupt the export flow.
    }
  }

  Future<void> cancel() async {
    _cancelled = true;
    try {
      await ref.read(videoEngineProvider).cancelExport();
    } on MissingPluginException {
      // Native engine not implemented on this platform yet — nothing to cancel.
    } catch (_) {
      // Never let a cancellation failure block the user from leaving.
    }
  }
}
