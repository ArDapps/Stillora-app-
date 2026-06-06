import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum EditorMediaStoreKind { media, audio }

class LocalEditorMediaStore {
  LocalEditorMediaStore({Directory? baseDirectory})
    : _baseDirectory = baseDirectory;

  final Directory? _baseDirectory;

  Future<List<String>> materializeMediaPaths(List<String> paths) async {
    final copied = <String>[];
    for (final path in paths) {
      final copy = await materializePath(
        path,
        kind: EditorMediaStoreKind.media,
      );
      if (copy != null) {
        copied.add(copy);
      }
    }
    return copied;
  }

  Future<String?> materializeAudioPath(String? path) {
    if (path == null) {
      return Future.value();
    }
    return materializePath(path, kind: EditorMediaStoreKind.audio);
  }

  Future<String?> materializePath(
    String path, {
    required EditorMediaStoreKind kind,
  }) async {
    final source = File(path);
    if (!await source.exists()) {
      return null;
    }

    final root = await _rootDirectory();
    if (_isInsideDirectory(source.path, root.path)) {
      return source.path;
    }

    final folder = Directory(
      _joinPath(
        root.path,
        kind == EditorMediaStoreKind.audio ? 'audio' : 'media',
      ),
    );
    await folder.create(recursive: true);

    final originalName = _baseName(source.path);
    final extension = _extension(originalName);
    final nameWithoutExtension = extension.isEmpty
        ? originalName
        : originalName.substring(0, originalName.length - extension.length);
    final safeName = _safeFileName(nameWithoutExtension).isEmpty
        ? 'source'
        : _safeFileName(nameWithoutExtension);
    final target = File(
      _joinPath(
        folder.path,
        '${DateTime.now().microsecondsSinceEpoch}_$safeName$extension',
      ),
    );

    return (await source.copy(target.path)).path;
  }

  Future<Directory> _rootDirectory() async {
    final base = _baseDirectory ?? await getApplicationSupportDirectory();
    final root = Directory(_joinPath(base.path, 'Stillora Source Media'));
    await root.create(recursive: true);
    return root;
  }
}

bool _isInsideDirectory(String path, String directory) {
  final normalizedPath = _normalizePath(path);
  final normalizedDirectory = _normalizePath(directory);
  return normalizedPath == normalizedDirectory ||
      normalizedPath.startsWith('$normalizedDirectory/');
}

String _joinPath(String directory, String fileName) {
  if (directory.endsWith('/') || directory.endsWith(r'\')) {
    return '$directory$fileName';
  }
  return '$directory${Platform.pathSeparator}$fileName';
}

String _baseName(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final slash = normalized.lastIndexOf('/');
  return slash == -1 ? normalized : normalized.substring(slash + 1);
}

String _extension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot == -1 ? '' : fileName.substring(dot);
}

String _normalizePath(String path) {
  final replaced = path.replaceAll(r'\', '/');
  return replaced.endsWith('/') && replaced.length > 1
      ? replaced.substring(0, replaced.length - 1)
      : replaced;
}

String _safeFileName(String fileName) {
  return fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
}
