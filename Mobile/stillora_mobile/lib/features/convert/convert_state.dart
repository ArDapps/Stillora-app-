import 'dart:io';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../core/platform/platform_info.dart';

/// Formats the converter can output to.
enum ConvertFormat { jpeg, png }

extension ConvertFormatMeta on ConvertFormat {
  String get label => switch (this) {
    ConvertFormat.jpeg => 'JPEG',
    ConvertFormat.png => 'PNG',
  };
  String get ext => switch (this) {
    ConvertFormat.jpeg => 'jpg',
    ConvertFormat.png => 'png',
  };
}

/// Input image extensions the picker accepts (HEIC/HEIF included — they decode
/// via the OS codecs on macOS/iOS/Android).
const convertInputExtensions = <String>[
  'heic',
  'heif',
  'jpg',
  'jpeg',
  'png',
  'webp',
  'bmp',
  'tif',
  'tiff',
  'gif',
];

class ConvertState extends Equatable {
  const ConvertState({
    this.paths = const [],
    this.format = ConvertFormat.jpeg,
    this.outputDir,
    this.outputDirName,
  });

  final List<String> paths;
  final ConvertFormat format;

  /// Chosen export folder. When null, converted files go to the default
  /// location (Photos on mobile, Downloads/Stillora Converted on desktop).
  final String? outputDir;
  final String? outputDirName;

  bool get hasImages => paths.isNotEmpty;
  bool get hasOutputDir => outputDir != null;

  ConvertState copyWith({
    List<String>? paths,
    ConvertFormat? format,
    String? outputDir,
    String? outputDirName,
    bool clearOutputDir = false,
  }) => ConvertState(
    paths: paths ?? this.paths,
    format: format ?? this.format,
    outputDir: clearOutputDir ? null : outputDir ?? this.outputDir,
    outputDirName: clearOutputDir ? null : outputDirName ?? this.outputDirName,
  );

  @override
  List<Object?> get props => [paths, format, outputDir, outputDirName];
}

/// Outcome of a batch conversion.
class ConvertResult {
  const ConvertResult({
    required this.converted,
    required this.failed,
    required this.destination,
  });
  final int converted;
  final int failed;

  /// Human-readable location ('Photos' on mobile, a folder path on desktop).
  final String destination;
}

final convertControllerProvider =
    NotifierProvider<ConvertController, ConvertState>(ConvertController.new);

class ConvertController extends Notifier<ConvertState> {
  static const _jpegQuality = 90;

  @override
  ConvertState build() => const ConvertState();

  void setFormat(ConvertFormat format) =>
      state = state.copyWith(format: format);

  /// Lets the user choose an export folder. If the platform can't provide one
  /// (or the user cancels), the default location is kept.
  Future<void> pickOutputFolder() async {
    final dir = await pickImportDirectory();
    if (dir == null || dir.isEmpty) return;
    final name = dir.split(RegExp(r'[/\\]')).last;
    state = state.copyWith(
      outputDir: dir,
      outputDirName: name.isEmpty ? dir : name,
    );
  }

  void clearOutputFolder() => state = state.copyWith(clearOutputDir: true);

  Future<void> pickImages() async {
    final result = await pickImportFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: convertInputExtensions,
    );
    if (result == null) return;
    final picked = [
      for (final f in result.files)
        if (f.path != null) f.path!,
    ];
    if (picked.isEmpty) return;
    final existing = state.paths.toSet();
    final next = [
      ...state.paths,
      ...picked.where((p) => !existing.contains(p)),
    ];
    state = state.copyWith(paths: next);
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.paths.length) return;
    final next = [...state.paths]..removeAt(index);
    state = state.copyWith(paths: next);
  }

  void clear() => state = const ConvertState();

  /// Desktop output folder. Prefers ~/Downloads (needs the sandbox
  /// `files.downloads.read-write` entitlement on macOS); falls back to the app's
  /// always-writable documents dir if Downloads is blocked, so a locked-down
  /// sandbox never turns into a "path failed" export error.
  Future<Directory> _desktopOutputDir() async {
    Future<Directory> under(Directory base) async {
      final dir = Directory(
        '${base.path}${Platform.pathSeparator}Stillora Converted',
      );
      await dir.create(recursive: true);
      return dir;
    }

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return await under(downloads);
    } catch (_) {
      // Downloads not accessible in this sandbox — fall through.
    }
    return under(await getApplicationDocumentsDirectory());
  }

  /// Converts every picked image to the chosen format. Decoding goes through the
  /// OS image codecs ([ui.instantiateImageCodec]) so HEIC/HEIF work on Apple &
  /// Android; encoding uses the `image` package. Results are saved to the Photos
  /// gallery on mobile and to a "Stillora Converted" folder on desktop.
  Future<ConvertResult> run() async {
    final paths = state.paths;
    if (paths.isEmpty) {
      return const ConvertResult(converted: 0, failed: 0, destination: '');
    }
    final onDesktop = isDesktopPlatform;
    final customDir = state.outputDir;
    // Save to the OS Photos gallery only for the mobile default (no custom
    // folder). A chosen folder is written to directly on every platform.
    final toPhotos = customDir == null && !onDesktop;
    late Directory outDir;
    if (customDir != null) {
      outDir = Directory(customDir);
      try {
        await outDir.create(recursive: true);
      } catch (_) {
        // Chosen folder unavailable (e.g. revoked access) — fall back.
        outDir = onDesktop
            ? await _desktopOutputDir()
            : await getTemporaryDirectory();
      }
    } else if (onDesktop) {
      outDir = await _desktopOutputDir();
    } else {
      outDir = await getTemporaryDirectory();
    }
    if (toPhotos) {
      try {
        await Gal.requestAccess(toAlbum: true);
      } catch (_) {
        // Fall through; putImage will surface any access error per file.
      }
    }

    final format = state.format;
    var ok = 0;
    var failed = 0;
    for (final path in paths) {
      try {
        final bytes = await File(path).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;
        final rgba = await uiImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final w = uiImage.width;
        final h = uiImage.height;
        uiImage.dispose();
        if (rgba == null) {
          failed++;
          continue;
        }
        final image = img.Image.fromBytes(
          width: w,
          height: h,
          bytes: rgba.buffer,
          numChannels: 4,
        );
        final encoded = format == ConvertFormat.jpeg
            ? img.encodeJpg(image, quality: _jpegQuality)
            : img.encodePng(image);

        final base = path.split(RegExp(r'[/\\]')).last;
        final dot = base.lastIndexOf('.');
        final stem = dot == -1 ? base : base.substring(0, dot);
        final safe = stem.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
        final outPath =
            '${outDir.path}${Platform.pathSeparator}${safe}_'
            '${DateTime.now().microsecondsSinceEpoch}.${format.ext}';
        await File(outPath).writeAsBytes(encoded, flush: true);

        if (toPhotos) {
          await Gal.putImage(outPath);
        }
        ok++;
      } catch (_) {
        failed++;
      }
    }

    return ConvertResult(
      converted: ok,
      failed: failed,
      destination: customDir ?? (onDesktop ? outDir.path : 'Photos'),
    );
  }
}
