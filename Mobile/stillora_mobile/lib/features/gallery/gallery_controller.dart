import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_export_record.dart';
import 'local_export_store.dart';

final localExportStoreProvider = FutureProvider<LocalExportStore>((ref) {
  return HiveLocalExportStore.open();
});

final galleryControllerProvider =
    AsyncNotifierProvider<GalleryController, List<LocalExportRecord>>(
      GalleryController.new,
    );

class GalleryController extends AsyncNotifier<List<LocalExportRecord>> {
  @override
  Future<List<LocalExportRecord>> build() => _load();

  Future<List<LocalExportRecord>> _load() async {
    final store = await ref.read(localExportStoreProvider.future);
    final storedRecords = await store.load();
    final records = <LocalExportRecord>[];
    var prunedMissingFiles = false;

    for (final record in storedRecords) {
      // The library stores local paths only. If the file was removed outside
      // Stillora, drop that stale record and write the cleaned list back.
      if (File(record.outputPath).existsSync()) {
        records.add(record);
      } else {
        prunedMissingFiles = true;
      }
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (prunedMissingFiles) {
      await _persist(records);
    }
    return records;
  }

  Future<void> _persist(List<LocalExportRecord> records) async {
    final store = await ref.read(localExportStoreProvider.future);
    await store.saveAll(records);
  }

  Future<void> addRecord(LocalExportRecord record) async {
    final current = state.value ?? await _load();
    final next = [
      record,
      for (final item in current)
        if (item.outputPath != record.outputPath && item.id != record.id) item,
    ];
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> removeRecord(String id) async {
    final current = state.value ?? await _load();
    LocalExportRecord? removed;
    final next = <LocalExportRecord>[];
    for (final record in current) {
      if (record.id == id) {
        removed = record;
      } else {
        next.add(record);
      }
    }
    state = AsyncData(next);
    if (removed != null) {
      try {
        final file = File(removed.outputPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // Ignore filesystem errors when deleting.
      }
    }
    await _persist(next);
  }

  /// Removes several records at once (multi-select delete in the Library).
  Future<void> removeRecords(Set<String> ids) async {
    if (ids.isEmpty) return;
    final current = state.value ?? await _load();
    final removed = <LocalExportRecord>[];
    final next = <LocalExportRecord>[];
    for (final record in current) {
      if (ids.contains(record.id)) {
        removed.add(record);
      } else {
        next.add(record);
      }
    }
    state = AsyncData(next);
    for (final record in removed) {
      try {
        final file = File(record.outputPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // Ignore filesystem errors when deleting.
      }
    }
    await _persist(next);
  }

  Future<void> refresh() async {
    state = AsyncData(await _load());
  }
}
