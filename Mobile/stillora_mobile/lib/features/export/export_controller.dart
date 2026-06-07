import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/platform/platform_info.dart';
import '../editor/editor_state.dart';
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
  @override
  FutureOr<engine.ExportResult?> build() => null;

  Future<void> start(EditorState editor) async {
    if (!editor.canExport) {
      throw StateError('Select media before exporting.');
    }

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
      return videoEngine.exportVideo(
        imagePath: exportEditor.imagePath!,
        mediaPaths: exportEditor.mediaPaths,
        imagePaths: exportEditor.imagePaths,
        clipDurations: exportEditor.clipDurations,
        audioPath: exportEditor.audioPath,
        durationSeconds: exportEditor.totalDurationSeconds,
        width: exportEditor.preset.width == 0
            ? 1080
            : exportEditor.preset.width,
        height: exportEditor.preset.height == 0
            ? 1080
            : exportEditor.preset.height,
        resizeMode: exportEditor.resizeMode == ResizeMode.fit
            ? engine.ResizeMode.fit
            : engine.ResizeMode.fill,
      );
    });

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
      await ref.read(dioProvider).post<void>(
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
    try {
      await ref.read(videoEngineProvider).cancelExport();
    } on MissingPluginException {
      // Native engine not implemented on this platform yet — nothing to cancel.
    } catch (_) {
      // Never let a cancellation failure block the user from leaving.
    }
  }
}
