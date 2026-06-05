import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_export_record.dart';

final galleryControllerProvider =
    AsyncNotifierProvider<GalleryController, List<LocalExportRecord>>(
      GalleryController.new,
    );

class GalleryController extends AsyncNotifier<List<LocalExportRecord>> {
  static const _storageKey = 'stillora.exports';

  @override
  Future<List<LocalExportRecord>> build() => _load();

  Future<List<LocalExportRecord>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    final records = <LocalExportRecord>[];
    for (final entry in raw) {
      try {
        final record = LocalExportRecord.fromJson(
          jsonDecode(entry) as Map<String, dynamic>,
        );
        // Drop records whose underlying file has been removed.
        if (File(record.outputPath).existsSync()) {
          records.add(record);
        }
      } catch (_) {
        // Skip malformed entries.
      }
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<void> _persist(List<LocalExportRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, [
      for (final record in records) jsonEncode(record.toJson()),
    ]);
  }

  Future<void> addRecord(LocalExportRecord record) async {
    final current = state.value ?? await _load();
    final next = [record, ...current];
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
        File(removed.outputPath).deleteSync();
      } catch (_) {
        // Ignore filesystem errors when deleting.
      }
    }
    await _persist(next);
  }
}
