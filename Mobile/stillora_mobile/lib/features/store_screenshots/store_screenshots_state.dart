import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../core/platform/import_directory.dart';
import '../convert/convert_state.dart' show convertInputExtensions;
import 'store_target.dart';

/// How a source image is made to fit a store size that is a different shape.
enum ShotFit {
  /// Whole image visible, centred, the remainder filled with [ShotBackground].
  fit,

  /// Scaled to cover and centre-cropped — no bars, but the edges are lost.
  fill,
}

/// Colour behind a `fit` render. Both stores reject an alpha channel, so a
/// letterboxed screenshot has to be flattened onto something opaque; these are
/// the choices that read as deliberate rather than as a bug.
enum ShotBackground { black, white, midnight }

extension ShotBackgroundMeta on ShotBackground {
  /// Opaque ARGB fill.
  ({int r, int g, int b}) get rgb => switch (this) {
    ShotBackground.black => (r: 0, g: 0, b: 0),
    ShotBackground.white => (r: 255, g: 255, b: 255),
    ShotBackground.midnight => (r: 11, g: 11, b: 20),
  };
}

/// Output encoding. Play asks for "JPEG or 24-bit PNG (no alpha)"; Apple
/// accepts .jpg/.jpeg/.png and likewise forbids transparency.
enum ShotFormat { png, jpeg }

extension ShotFormatMeta on ShotFormat {
  String get label => switch (this) {
    ShotFormat.png => 'PNG',
    ShotFormat.jpeg => 'JPEG',
  };
  String get ext => switch (this) {
    ShotFormat.png => 'png',
    ShotFormat.jpeg => 'jpg',
  };
}

class StoreScreenshotsState extends Equatable {
  const StoreScreenshotsState({
    this.paths = const [],
    this.selectedTargetIds = const {},
    this.fit = ShotFit.fit,
    this.background = ShotBackground.midnight,
    this.format = ShotFormat.png,
    this.landscape = false,
    this.isRunning = false,
    this.progress = 0,
    this.total = 0,
  });

  /// Source images, in export order.
  final List<String> paths;

  final Set<String> selectedTargetIds;
  final ShotFit fit;
  final ShotBackground background;
  final ShotFormat format;

  /// Render the families that support it landscape instead of portrait.
  final bool landscape;

  final bool isRunning;
  final int progress;
  final int total;

  bool get hasImages => paths.isNotEmpty;
  bool get hasTargets => selectedTargetIds.isNotEmpty;
  bool get canExport => hasImages && hasTargets && !isRunning;

  List<StoreTarget> get selectedTargets => [
    for (final target in storeTargets)
      if (selectedTargetIds.contains(target.id)) target,
  ];

  /// How many files the zip will hold.
  int get outputCount => paths.length * selectedTargetIds.length;

  /// Which stores the current selection covers, for the summary line.
  Set<StoreKind> get stores => {
    for (final target in selectedTargets) target.store,
  };

  StoreScreenshotsState copyWith({
    List<String>? paths,
    Set<String>? selectedTargetIds,
    ShotFit? fit,
    ShotBackground? background,
    ShotFormat? format,
    bool? landscape,
    bool? isRunning,
    int? progress,
    int? total,
  }) => StoreScreenshotsState(
    paths: paths ?? this.paths,
    selectedTargetIds: selectedTargetIds ?? this.selectedTargetIds,
    fit: fit ?? this.fit,
    background: background ?? this.background,
    format: format ?? this.format,
    landscape: landscape ?? this.landscape,
    isRunning: isRunning ?? this.isRunning,
    progress: progress ?? this.progress,
    total: total ?? this.total,
  );

  @override
  List<Object?> get props => [
    paths,
    selectedTargetIds,
    fit,
    background,
    format,
    landscape,
    isRunning,
    progress,
    total,
  ];
}

/// Where the finished zip ended up, and how much went into it.
class ShotExportResult {
  const ShotExportResult({
    required this.zipPath,
    required this.written,
    required this.failed,
    required this.targets,
  });

  final String zipPath;
  final int written;
  final int failed;
  final int targets;

  bool get isEmpty => written == 0;
  String get fileName => zipPath.split(RegExp(r'[/\\]')).last;
}

final storeScreenshotsControllerProvider =
    NotifierProvider<StoreScreenshotsController, StoreScreenshotsState>(
      StoreScreenshotsController.new,
    );

class StoreScreenshotsController extends Notifier<StoreScreenshotsState> {
  static const _jpegQuality = 92;

  @override
  StoreScreenshotsState build() =>
      StoreScreenshotsState(selectedTargetIds: {...defaultTargetIds});

  void setFit(ShotFit fit) => state = state.copyWith(fit: fit);
  void setBackground(ShotBackground bg) =>
      state = state.copyWith(background: bg);
  void setFormat(ShotFormat format) => state = state.copyWith(format: format);
  void setLandscape(bool landscape) =>
      state = state.copyWith(landscape: landscape);

  void toggleTarget(String id) {
    final next = {...state.selectedTargetIds};
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(selectedTargetIds: next);
  }

  /// Selects or clears every size in one family, so "all of iPhone" is one tap
  /// rather than six.
  void toggleFamily(StoreFamily family) {
    final ids = [
      for (final target in storeTargets)
        if (target.family == family) target.id,
    ];
    final next = {...state.selectedTargetIds};
    final allOn = ids.every(next.contains);
    if (allOn) {
      next.removeAll(ids);
    } else {
      next.addAll(ids);
    }
    state = state.copyWith(selectedTargetIds: next);
  }

  void selectRequiredOnly() =>
      state = state.copyWith(selectedTargetIds: {...defaultTargetIds});

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
    state = state.copyWith(
      paths: [...state.paths, ...picked.where((p) => !existing.contains(p))],
    );
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.paths.length) return;
    state = state.copyWith(paths: [...state.paths]..removeAt(index));
  }

  /// Export order is the listing order, so the queue is reorderable.
  void move(int from, int to) {
    if (from < 0 || from >= state.paths.length) return;
    final next = [...state.paths];
    final item = next.removeAt(from);
    next.insert(to.clamp(0, next.length), item);
    state = state.copyWith(paths: next);
  }

  void clearImages() => state = state.copyWith(paths: const []);

  void reset() =>
      state = StoreScreenshotsState(selectedTargetIds: {...defaultTargetIds});

  /// Decodes through the OS codecs so HEIC/HEIF from an iPhone work the same
  /// way they do in the Reformat Image section.
  Future<img.Image?> _decode(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;
      final rgba = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      final w = uiImage.width;
      final h = uiImage.height;
      uiImage.dispose();
      if (rgba == null) return null;
      return img.Image.fromBytes(
        width: w,
        height: h,
        bytes: rgba.buffer,
        numChannels: 4,
      );
    } catch (_) {
      return null;
    }
  }

  /// Renders [source] into a [width]×[height] canvas.
  ///
  /// The canvas starts as an opaque fill and the scaled image is composited
  /// onto it, so the result never carries transparency — both stores reject an
  /// alpha channel outright.
  static img.Image renderTo(
    img.Image source,
    int width,
    int height, {
    required ShotFit fit,
    required ShotBackground background,
  }) {
    final rgb = background.rgb;
    final canvas = img.Image(width: width, height: height, numChannels: 3);
    img.fill(canvas, color: img.ColorRgb8(rgb.r, rgb.g, rgb.b));

    final byWidth = width / source.width;
    final byHeight = height / source.height;
    // Contain takes the smaller scale (whole image fits, bars remain); cover
    // takes the larger (frame is filled, overflow is cropped away).
    final scale = fit == ShotFit.fit
        ? (byWidth < byHeight ? byWidth : byHeight)
        : (byWidth > byHeight ? byWidth : byHeight);

    final drawW = (source.width * scale).round().clamp(1, 1 << 20);
    final drawH = (source.height * scale).round().clamp(1, 1 << 20);
    var scaled = img.copyResize(
      source,
      width: drawW,
      height: drawH,
      interpolation: img.Interpolation.cubic,
    );

    // A cover render is larger than the canvas on at least one axis. Crop it to
    // the frame first: compositing at a negative offset leaves the background
    // showing through instead of clipping, which would put bars on a "fill"
    // export — the one thing fill exists to avoid.
    if (scaled.width > width || scaled.height > height) {
      scaled = img.copyCrop(
        scaled,
        x: ((scaled.width - width) / 2).round().clamp(0, scaled.width - 1),
        y: ((scaled.height - height) / 2).round().clamp(0, scaled.height - 1),
        width: scaled.width < width ? scaled.width : width,
        height: scaled.height < height ? scaled.height : height,
      );
    }

    img.compositeImage(
      canvas,
      scaled,
      dstX: ((width - scaled.width) / 2).round(),
      dstY: ((height - scaled.height) / 2).round(),
    );
    return canvas;
  }

  List<int> _encode(img.Image image, ShotFormat format) =>
      format == ShotFormat.jpeg
      ? img.encodeJpg(image, quality: _jpegQuality)
      : // numChannels 3 on the canvas keeps this a 24-bit PNG, which is what
        // Google Play asks for by name.
        img.encodePng(image);

  /// Renders every picked image at every selected size and packs the lot into
  /// one zip, laid out `<Store>/<size>/01-name.png` so the folders map onto
  /// the upload slots in App Store Connect and Play Console.
  ///
  /// Returns null when there is nothing to do.
  Future<ShotExportResult?> exportZip() async {
    final current = state;
    if (!current.canExport) return null;

    final targets = current.selectedTargets;
    final total = current.paths.length * targets.length;
    state = state.copyWith(isRunning: true, progress: 0, total: total);

    final archive = Archive();
    var written = 0;
    var failed = 0;

    try {
      for (var i = 0; i < current.paths.length; i++) {
        final path = current.paths[i];
        final source = await _decode(path);
        if (source == null) {
          failed += targets.length;
          state = state.copyWith(progress: state.progress + targets.length);
          continue;
        }

        final base = path.split(RegExp(r'[/\\]')).last;
        final dot = base.lastIndexOf('.');
        final stem = dot == -1 ? base : base.substring(0, dot);
        final safe = stem
            .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
            .replaceAll(RegExp(r'^_+|_+$'), '');
        final index = (i + 1).toString().padLeft(2, '0');

        for (final target in targets) {
          try {
            final size = target.resolve(landscape: current.landscape);
            final rendered = renderTo(
              source,
              size.width,
              size.height,
              fit: current.fit,
              background: current.background,
            );
            final bytes = _encode(rendered, current.format);
            final name =
                '${target.store.folder}/${target.id}/'
                '$index-${safe.isEmpty ? 'screenshot' : safe}.'
                '${current.format.ext}';
            archive.addFile(ArchiveFile(name, bytes.length, bytes));
            written++;
          } catch (_) {
            failed++;
          }
          state = state.copyWith(progress: state.progress + 1);
        }
      }

      if (written == 0) {
        return ShotExportResult(
          zipPath: '',
          written: 0,
          failed: failed,
          targets: targets.length,
        );
      }

      // A short manifest costs nothing and turns a folder of numbered files
      // into something the user can check against the store's own list.
      archive.addFile(_manifest(current, targets));

      final zipBytes = ZipEncoder().encode(archive);
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final zipPath =
          '${dir.path}${Platform.pathSeparator}stillora-store-screenshots-'
          '$stamp.zip';
      await File(zipPath).writeAsBytes(zipBytes, flush: true);

      return ShotExportResult(
        zipPath: zipPath,
        written: written,
        failed: failed,
        targets: targets.length,
      );
    } finally {
      state = state.copyWith(isRunning: false, progress: 0, total: 0);
    }
  }

  ArchiveFile _manifest(
    StoreScreenshotsState current,
    List<StoreTarget> targets,
  ) {
    final buffer = StringBuffer()
      ..writeln('Stillora — store screenshots')
      ..writeln('Generated ${DateTime.now().toIso8601String()}')
      ..writeln('')
      ..writeln('Source images : ${current.paths.length}')
      ..writeln('Sizes         : ${targets.length}')
      ..writeln('Fit           : ${current.fit.name}')
      ..writeln('Format        : ${current.format.label} (no alpha channel)')
      ..writeln(
        'Orientation   : ${current.landscape ? 'landscape' : 'portrait'}',
      )
      ..writeln('');
    for (final target in targets) {
      final size = target.resolve(landscape: current.landscape);
      buffer.writeln(
        '${target.store.folder}/${target.id}  '
        '${size.width}x${size.height}  ${target.label}'
        '${target.required ? '  (required)' : ''}',
      );
    }
    final bytes = buffer.toString().codeUnits;
    return ArchiveFile('README.txt', bytes.length, bytes);
  }
}
