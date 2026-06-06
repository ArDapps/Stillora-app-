import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_export_record.dart';

const localExportHiveBoxName = 'stillora_library_exports';

abstract interface class LocalExportStore {
  Future<List<LocalExportRecord>> load();
  Future<void> saveAll(List<LocalExportRecord> records);
}

class HiveLocalExportStore implements LocalExportStore {
  HiveLocalExportStore._(this._box);

  static const _legacyStorageKey = 'stillora.exports';

  final Box<Object?> _box;

  static Future<HiveLocalExportStore> open() async {
    final box = await Hive.openBox<Object?>(localExportHiveBoxName);
    final store = HiveLocalExportStore._(box);
    await store._migrateLegacySharedPreferences();
    return store;
  }

  @override
  Future<List<LocalExportRecord>> load() async {
    final records = <LocalExportRecord>[];
    var prunedMalformedEntries = false;

    for (final value in _box.values) {
      try {
        final json = _jsonFromValue(value);
        if (json == null) {
          prunedMalformedEntries = true;
          continue;
        }
        records.add(LocalExportRecord.fromJson(json));
      } catch (_) {
        prunedMalformedEntries = true;
      }
    }

    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (prunedMalformedEntries) {
      await saveAll(records);
    }
    return records;
  }

  @override
  Future<void> saveAll(List<LocalExportRecord> records) async {
    await _box.clear();
    await _box.putAll({
      for (final record in records) record.id: _jsonForStorage(record),
    });
  }

  Future<void> _migrateLegacySharedPreferences() async {
    if (_box.isNotEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_legacyStorageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final records = <LocalExportRecord>[];
    for (final entry in raw) {
      try {
        records.add(
          LocalExportRecord.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } catch (_) {
        // Skip malformed legacy entries.
      }
    }

    if (records.isNotEmpty) {
      await saveAll(records);
    }
    await prefs.remove(_legacyStorageKey);
  }

  Map<String, dynamic> _jsonForStorage(LocalExportRecord record) {
    return Map<String, dynamic>.from(record.toJson())
      ..removeWhere((_, value) => value == null);
  }

  Map<String, dynamic>? _jsonFromValue(Object? value) {
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
      return null;
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }
}
