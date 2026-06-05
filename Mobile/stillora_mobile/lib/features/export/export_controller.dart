import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

import '../editor/editor_state.dart';
import '../gallery/gallery_controller.dart';
import '../gallery/local_export_record.dart';

final videoEngineProvider = Provider<engine.StilloraVideoEngine>((ref) {
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
      throw StateError('Select an image before exporting.');
    }

    state = const AsyncLoading();
    final videoEngine = ref.read(videoEngineProvider);

    // NOTE: export progress is delivered over an EventChannel
    // (`stillora_video_engine/progress`). Subscribing to it activates the
    // channel, which raises a MissingPluginException via the framework zone
    // until the native engine implements it. Re-add the subscription here once
    // the iOS/Android engine is in place.

    state = await AsyncValue.guard(() {
      return videoEngine.exportVideo(
        imagePath: editor.imagePath!,
        imagePaths: editor.imagePaths,
        audioPath: editor.audioPath,
        durationSeconds: editor.durationSeconds,
        width: editor.preset.width == 0 ? 1080 : editor.preset.width,
        height: editor.preset.height == 0 ? 1080 : editor.preset.height,
        resizeMode: editor.resizeMode == ResizeMode.fit
            ? engine.ResizeMode.fit
            : engine.ResizeMode.fill,
      );
    });

    final result = state.value;
    if (result != null) {
      await ref
          .read(galleryControllerProvider.notifier)
          .addRecord(
            LocalExportRecord(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              outputPath: result.outputPath,
              preset: editor.preset.label,
              width: result.width,
              height: result.height,
              durationSeconds: result.durationSeconds,
              createdAt: DateTime.now(),
            ),
          );
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
