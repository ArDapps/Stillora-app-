import 'dart:io';

import 'package:video_player/video_player.dart';

import 'desktop_media_probe.dart';
import 'editor_duration.dart';

// Reads a media file's length. Moved verbatim out of `EditorController`
// (`_readMediaDurationSeconds`); it never touched controller state.

Future<int?> readMediaDurationSeconds(String path) async {
  // `video_player` has no Linux/Windows desktop implementation, so probing it
  // there throws and the editor never learns the audio length. Use ffprobe on
  // those platforms so "fit video to audio" works on desktop too.
  if (Platform.isLinux || Platform.isWindows) {
    return DesktopMediaProbe.durationSeconds(path);
  }
  final controller = VideoPlayerController.file(File(path));
  try {
    await controller.initialize();
    final duration = controller.value.duration;
    if (duration <= Duration.zero) {
      return null;
    }
    return normalizeDurationSeconds(duration.inMilliseconds / 1000);
  } catch (_) {
    return null;
  } finally {
    await controller.dispose();
  }
}
