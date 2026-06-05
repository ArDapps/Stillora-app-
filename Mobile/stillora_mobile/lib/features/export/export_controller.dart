import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

import '../editor/editor_state.dart';

final videoEngineProvider = Provider<engine.StilloraVideoEngine>((ref) {
  return engine.PlatformStilloraVideoEngine();
});

final exportControllerProvider =
    AsyncNotifierProvider<ExportController, engine.ExportResult?>(
      ExportController.new,
    );

class ExportController extends AsyncNotifier<engine.ExportResult?> {
  StreamSubscription<engine.ExportProgress>? _subscription;

  @override
  FutureOr<engine.ExportResult?> build() {
    ref.onDispose(() => _subscription?.cancel());
    return null;
  }

  Future<void> start(EditorState editor) async {
    if (!editor.canExport) {
      throw StateError('Select an image before exporting.');
    }

    state = const AsyncLoading();
    final videoEngine = ref.read(videoEngineProvider);
    _subscription = videoEngine.progressStream.listen((event) {});

    state = await AsyncValue.guard(() {
      return videoEngine.exportVideo(
        imagePath: editor.imagePath!,
        audioPath: editor.audioPath,
        durationSeconds: editor.durationSeconds,
        width: editor.preset.width == 0 ? 1080 : editor.preset.width,
        height: editor.preset.height == 0 ? 1080 : editor.preset.height,
        resizeMode: editor.resizeMode == ResizeMode.fit
            ? engine.ResizeMode.fit
            : engine.ResizeMode.fill,
      );
    });
  }

  Future<void> cancel() {
    return ref.read(videoEngineProvider).cancelExport();
  }
}
