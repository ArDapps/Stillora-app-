import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

import '../export/export_controller.dart';
import '../gallery/gallery_controller.dart';
import '../gallery/local_export_record.dart';

/// Maximum images in one batch — keeps a single run within reasonable time.
const kLoopMaxImages = 30;

/// Output canvas sizes offered for the batch (one applies to every image).
class LoopSize {
  const LoopSize(this.id, this.label, this.ratio, this.width, this.height);
  final String id;
  final String label;
  final String ratio;
  final int width;
  final int height;
}

const loopSizes = [
  LoopSize('vertical', 'Vertical', '9:16', 1080, 1920),
  LoopSize('square', 'Square', '1:1', 1080, 1080),
  LoopSize('portrait', 'Portrait', '4:5', 1080, 1350),
  LoopSize('landscape', 'Landscape', '16:9', 1920, 1080),
];

enum LoopItemStatus { ready, rendering, done, error }

class LoopItem {
  const LoopItem({
    required this.id,
    required this.path,
    required this.name,
    this.status = LoopItemStatus.ready,
    this.resultPath,
    this.error,
  });

  final String id;
  final String path;
  final String name;
  final LoopItemStatus status;
  final String? resultPath;
  final String? error;

  LoopItem copyWith({
    LoopItemStatus? status,
    String? resultPath,
    String? error,
  }) {
    return LoopItem(
      id: id,
      path: path,
      name: name,
      status: status ?? this.status,
      resultPath: resultPath ?? this.resultPath,
      error: error,
    );
  }
}

class LoopImagesState {
  const LoopImagesState({
    this.items = const [],
    this.sizeId = 'vertical',
    this.durationSeconds = 10,
    this.resizeMode = engine.ResizeMode.fill,
    this.isRunning = false,
  });

  final List<LoopItem> items;
  final String sizeId;
  final int durationSeconds;
  final engine.ResizeMode resizeMode;
  final bool isRunning;

  int get doneCount =>
      items.where((i) => i.status == LoopItemStatus.done).length;

  LoopSize get size =>
      loopSizes.firstWhere((s) => s.id == sizeId, orElse: () => loopSizes.first);

  LoopImagesState copyWith({
    List<LoopItem>? items,
    String? sizeId,
    int? durationSeconds,
    engine.ResizeMode? resizeMode,
    bool? isRunning,
  }) {
    return LoopImagesState(
      items: items ?? this.items,
      sizeId: sizeId ?? this.sizeId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      resizeMode: resizeMode ?? this.resizeMode,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

final loopImagesControllerProvider =
    NotifierProvider<LoopImagesController, LoopImagesState>(
      LoopImagesController.new,
    );

/// Batch "Loop images": every image becomes its OWN MP4 — never merged.
/// Each render reuses the same native/desktop engine as the Create flow and is
/// saved into the Library so it appears alongside normal exports.
class LoopImagesController extends Notifier<LoopImagesState> {
  @override
  LoopImagesState build() => const LoopImagesState();

  void addPaths(Iterable<String> paths) {
    final existing = state.items.map((i) => i.path).toSet();
    final additions = <LoopItem>[];
    for (final path in paths) {
      if (existing.contains(path)) continue;
      existing.add(path);
      additions.add(
        LoopItem(
          id: '${DateTime.now().microsecondsSinceEpoch}-${additions.length}',
          path: path,
          name: path.split(RegExp(r'[/\\]')).last,
        ),
      );
    }
    final next = [...state.items, ...additions];
    state = state.copyWith(
      items: next.length > kLoopMaxImages ? next.sublist(0, kLoopMaxImages) : next,
    );
  }

  void remove(String id) {
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
  }

  void clear() {
    if (state.isRunning) return;
    state = state.copyWith(items: const []);
  }

  void setSize(String id) => state = state.copyWith(sizeId: id);

  void setDuration(int seconds) => state = state.copyWith(durationSeconds: seconds);

  void setResizeMode(engine.ResizeMode mode) =>
      state = state.copyWith(resizeMode: mode);

  void _patch(String id, LoopItem Function(LoopItem) update) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id) update(item) else item,
      ],
    );
  }

  Future<void> convertAll() async {
    if (state.isRunning || state.items.isEmpty) return;
    state = state.copyWith(isRunning: true);

    final videoEngine = ref.read(videoEngineProvider);
    final size = state.size;
    final width = size.width;
    final height = size.height;
    final duration = state.durationSeconds;
    final resize = state.resizeMode;

    // Sequential — the engine is heavy; one render at a time is safest.
    for (final item in [...state.items]) {
      if (item.status == LoopItemStatus.done) continue;
      _patch(item.id, (i) => i.copyWith(status: LoopItemStatus.rendering, error: null));
      try {
        final result = await videoEngine.exportVideo(
          imagePath: item.path,
          durationSeconds: duration,
          width: width,
          height: height,
          resizeMode: resize,
        );
        await ref.read(galleryControllerProvider.notifier).addRecord(
              LocalExportRecord(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                outputPath: result.outputPath,
                preset: size.label,
                width: result.width,
                height: result.height,
                durationSeconds: result.durationSeconds,
                createdAt: DateTime.now(),
              ),
            );
        _patch(
          item.id,
          (i) => i.copyWith(status: LoopItemStatus.done, resultPath: result.outputPath),
        );
      } catch (e) {
        _patch(item.id, (i) => i.copyWith(status: LoopItemStatus.error, error: '$e'));
      }
    }

    state = state.copyWith(isRunning: false);
  }
}
