import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import 'import_directory.dart';

/// Outcome of a save attempt, so the UI can show the right message instead of
/// failing silently. `cancelled` is when the user dismissed a save dialog.
enum SaveOutcome { saved, missingFile, permissionDenied, failed, cancelled }

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

  /// Opens the native share sheet for an audio file at [path] (e.g. an MP3).
  /// On mobile this is also how a user saves it — the sheet offers "Save to
  /// Files". Returns false if the file is missing so the caller can warn.
  static Future<bool> shareAudio(
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
        files: [XFile(path, mimeType: 'audio/mpeg')],
        text: text,
        sharePositionOrigin: origin,
      ),
    );
    return true;
  }

  /// Opens the native share sheet for a PDF at [path]. On mobile this is also
  /// how the user files it away — the sheet offers "Save to Files" / "Save to
  /// Drive". Returns false if the file is missing so the caller can warn.
  static Future<bool> sharePdf(
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
        files: [XFile(path, mimeType: 'application/pdf')],
        text: text,
        sharePositionOrigin: origin,
      ),
    );
    return true;
  }

  /// Desktop save: open a native "Save As" dialog and write the PDF to the
  /// chosen location. Returns [SaveOutcome.cancelled] when the user dismisses
  /// the dialog so the caller can stay silent.
  static Future<SaveOutcome> savePdfToFile(
    String path, {
    String suggestedName = 'stillora.pdf',
    String? dialogTitle,
  }) async {
    final source = File(path);
    if (!source.existsSync()) {
      return SaveOutcome.missingFile;
    }
    try {
      final bytes = await source.readAsBytes();
      final destination = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? 'Save PDF',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: bytes,
        initialDirectory: await lastImportDirectory(),
      );
      await rememberImportPath(destination);
      if (destination == null) {
        return SaveOutcome.cancelled;
      }
      // Some platforms write the bytes themselves; others only return the path.
      final out = File(destination);
      if (!out.existsSync() || await out.length() != bytes.length) {
        await out.writeAsBytes(bytes, flush: true);
      }
      return SaveOutcome.saved;
    } catch (_) {
      return SaveOutcome.failed;
    }
  }

  /// Opens the native share sheet for a zip at [path]. On a phone this is how
  /// the user gets the archive off the device — the sheet offers "Save to
  /// Files", AirDrop and Mail. Returns false if the file is missing.
  static Future<bool> shareZip(
    BuildContext context,
    String path, {
    String text = 'Store screenshots from Stillora',
  }) async {
    if (!File(path).existsSync()) {
      return false;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/zip')],
        text: text,
        sharePositionOrigin: _popoverAnchor(context),
      ),
    );
    return true;
  }

  /// Desktop save: open a native "Save As" dialog and write the zip to the
  /// chosen location. [SaveOutcome.cancelled] when the dialog is dismissed.
  static Future<SaveOutcome> saveZipToFile(
    String path, {
    String suggestedName = 'stillora-store-screenshots.zip',
    String? dialogTitle,
  }) async {
    final source = File(path);
    if (!source.existsSync()) {
      return SaveOutcome.missingFile;
    }
    try {
      final bytes = await source.readAsBytes();
      final destination = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? 'Save zip',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        bytes: bytes,
        initialDirectory: await lastImportDirectory(),
      );
      await rememberImportPath(destination);
      if (destination == null) {
        return SaveOutcome.cancelled;
      }
      // Some platforms write the bytes themselves; others only return the path.
      final out = File(destination);
      if (!out.existsSync() || await out.length() != bytes.length) {
        await out.writeAsBytes(bytes, flush: true);
      }
      return SaveOutcome.saved;
    } catch (_) {
      return SaveOutcome.failed;
    }
  }

  /// Desktop save: open a native "Save As" dialog and write the MP3 to the
  /// chosen location. Returns [SaveOutcome.cancelled] when the user dismisses
  /// the dialog so the caller can stay silent.
  static Future<SaveOutcome> saveAudioToFile(
    String path, {
    String? dialogTitle,
    String suggestedName = 'stillora.mp3',
  }) async {
    final source = File(path);
    if (!source.existsSync()) {
      return SaveOutcome.missingFile;
    }
    try {
      final bytes = await source.readAsBytes();
      final destination = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? 'Save audio',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: const ['mp3'],
        bytes: bytes,
        initialDirectory: await lastImportDirectory(),
      );
      await rememberImportPath(destination);
      if (destination == null) {
        return SaveOutcome.cancelled;
      }
      final out = File(destination);
      if (!out.existsSync() || await out.length() != bytes.length) {
        await out.writeAsBytes(bytes, flush: true);
      }
      return SaveOutcome.saved;
    } catch (_) {
      return SaveOutcome.failed;
    }
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

  /// Desktop save: there is no camera roll, so open a native "Save As" dialog
  /// and write the video to the chosen location. Returns [SaveOutcome.cancelled]
  /// when the user dismisses the dialog so the caller can stay silent.
  static Future<SaveOutcome> saveVideoToFile(
    String path, {
    String suggestedName = 'stillora.mp4',
    String? dialogTitle,
  }) async {
    final source = File(path);
    if (!source.existsSync()) {
      return SaveOutcome.missingFile;
    }
    try {
      final bytes = await source.readAsBytes();
      final destination = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? 'Save video',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: const ['mp4'],
        bytes: bytes,
        initialDirectory: await lastImportDirectory(),
      );
      // Reopen future pickers where the user last saved.
      await rememberImportPath(destination);
      if (destination == null) {
        return SaveOutcome.cancelled;
      }
      // Some platforms write the bytes themselves; others only return the path.
      final out = File(destination);
      if (!out.existsSync() || await out.length() != bytes.length) {
        await out.writeAsBytes(bytes, flush: true);
      }
      return SaveOutcome.saved;
    } catch (_) {
      return SaveOutcome.failed;
    }
  }
}
