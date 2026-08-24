import 'dart:io';
import 'dart:ui' as ui;

import 'package:video_player/video_player.dart';

import 'desktop_media_probe.dart';
import 'editor_media_item.dart';

/// Reads a media file's native pixel size, mirroring [readMediaDurationSeconds]:
/// images decode directly; videos use `video_player` where it has a plugin
/// (iOS/macOS/Android) and `ffprobe` on Linux/Windows where it does not.
///
/// Returns null when the size can't be determined, so callers keep the item's
/// existing (0×0 → "unknown") dimensions rather than guessing.
Future<({int width, int height})?> readMediaDimensions(String path) async {
  if (mediaKindForPath(path) == MediaKind.image) {
    return _imageDimensions(path);
  }
  if (Platform.isLinux || Platform.isWindows) {
    return DesktopMediaProbe.dimensions(path);
  }
  final controller = VideoPlayerController.file(File(path));
  try {
    await controller.initialize();
    final size = controller.value.size;
    final w = size.width.round();
    final h = size.height.round();
    if (w <= 0 || h <= 0) {
      return null;
    }
    return (width: w, height: h);
  } catch (_) {
    return null;
  } finally {
    await controller.dispose();
  }
}

/// Decodes just enough of an image to read its pixel size, then releases it.
Future<({int width, int height})?> _imageDimensions(String path) async {
  ui.Image? image;
  try {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    image = frame.image;
    final w = image.width;
    final h = image.height;
    if (w <= 0 || h <= 0) {
      return null;
    }
    return (width: w, height: h);
  } catch (_) {
    return null;
  } finally {
    image?.dispose();
  }
}
