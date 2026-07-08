import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the folder of the last file/media the user imported (or saved to)
/// so every file picker in the app — across all sections — reopens at the most
/// recent location instead of jumping back to a default folder each time.
const _lastImportDirKey = 'stillora.import.lastDir';

/// The last-used import folder, or null when there isn't a usable one. A stale
/// path (folder since deleted/moved) is ignored so the native dialog doesn't
/// error on desktop.
Future<String?> lastImportDirectory() async {
  final prefs = await SharedPreferences.getInstance();
  final dir = prefs.getString(_lastImportDirKey);
  if (dir == null || dir.isEmpty) return null;
  return Directory(dir).existsSync() ? dir : null;
}

/// Persists [directory] as the most recent import location.
Future<void> rememberImportDirectory(String? directory) async {
  if (directory == null || directory.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastImportDirKey, directory);
}

/// Persists the parent folder of [filePath] as the most recent import location.
Future<void> rememberImportPath(String? filePath) async {
  if (filePath == null || filePath.isEmpty) return;
  await rememberImportDirectory(File(filePath).parent.path);
}

String? _firstPath(FilePickerResult? result) {
  if (result == null || result.files.isEmpty) return null;
  return result.files.first.path;
}

/// [FilePicker.pickFiles] that opens in [lastImportDirectory] and records the
/// folder of whatever gets picked. Drop-in for `FilePicker.platform.pickFiles`.
Future<FilePickerResult?> pickImportFiles({
  FileType type = FileType.any,
  List<String>? allowedExtensions,
  bool allowMultiple = false,
  bool withData = false,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: type,
    allowedExtensions: allowedExtensions,
    allowMultiple: allowMultiple,
    withData: withData,
    initialDirectory: await lastImportDirectory(),
  );
  await rememberImportPath(_firstPath(result));
  return result;
}

/// [FilePicker.getDirectoryPath] that opens in — and records — the last folder.
Future<String?> pickImportDirectory() async {
  final dir = await FilePicker.platform.getDirectoryPath(
    initialDirectory: await lastImportDirectory(),
  );
  await rememberImportDirectory(dir);
  return dir;
}
