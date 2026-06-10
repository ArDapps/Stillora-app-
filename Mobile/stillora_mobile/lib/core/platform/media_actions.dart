import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

/// Outcome of a "Save to Camera Roll" attempt, so the UI can show the right
/// message instead of failing silently.
enum SaveOutcome { saved, missingFile, permissionDenied, failed }

class MediaActions {
  const MediaActions._();

  /// The rectangle the iPad share/save popover should point at. iPadOS requires
  /// a non-empty `sourceRect`; without it the share sheet silently no-ops. We
  /// anchor to the tapped widget when we can, falling back to screen centre.
  static Rect _popoverAnchor(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      final topLeft = box.localToGlobal(Offset.zero);
      return topLeft & box.size;
    }
    final size = MediaQuery.of(context).size;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
  }

  /// Opens the native share sheet for [path]. Verifies the file exists first and
  /// passes an anchored origin so it works on iPad. Returns false if the file is
  /// missing so the caller can surface an error.
  static Future<bool> shareVideo(
    BuildContext context,
    String path, {
    String text = 'Made with Stillora',
  }) async {
    if (!File(path).existsSync()) {
      return false;
    }
    final origin = _popoverAnchor(context);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'video/mp4')],
        text: text,
        sharePositionOrigin: origin,
      ),
    );
    return true;
  }

  /// Saves [path] to the system Camera Roll using the add-only photo permission.
  static Future<SaveOutcome> saveToCameraRoll(String path) async {
    if (!File(path).existsSync()) {
      return SaveOutcome.missingFile;
    }
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: false);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: false);
        if (!granted) {
          return SaveOutcome.permissionDenied;
        }
      }
      await Gal.putVideo(path);
      return SaveOutcome.saved;
    } on GalException catch (error) {
      if (error.type == GalExceptionType.accessDenied) {
        return SaveOutcome.permissionDenied;
      }
      return SaveOutcome.failed;
    } catch (_) {
      return SaveOutcome.failed;
    }
  }
}
