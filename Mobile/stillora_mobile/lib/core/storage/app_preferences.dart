import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/app_locale.dart';

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  throw UnimplementedError('AppPreferences must be overridden at startup.');
});

final appPreferencesBootstrapProvider = FutureProvider<AppPreferences>((
  ref,
) async {
  final preferences = await SharedPreferences.getInstance();
  return AppPreferences(preferences);
});

class AppPreferences {
  AppPreferences(this._preferences);

  static const _defaultDurationKey = 'stillora.editor.defaultDuration';
  static const _defaultPresetKey = 'stillora.editor.defaultPreset';
  static const _defaultResizeModeKey = 'stillora.editor.defaultResizeMode';
  static const _hasSeenOnboardingKey = 'stillora.onboarding.seen';
  static const _themeModeKey = 'stillora.appearance.themeMode';
  static const _languageKey = 'stillora.appearance.language';
  static const _ratingLastPromptKey = 'stillora.rating.lastPromptMs';
  static const _ratedAfterFirstExportKey =
      'stillora.rating.requestedAfterFirstExport';

  final SharedPreferences _preferences;

  bool get hasSeenOnboarding =>
      _preferences.getBool(_hasSeenOnboardingKey) ?? false;

  Future<void> setHasSeenOnboarding(bool value) {
    return _preferences.setBool(_hasSeenOnboardingKey, value);
  }

  // ── Appearance ─────────────────────────────────────────────────────────────

  /// Persisted light/dark preference, stored as the [ThemeMode] name so the
  /// value stays readable in the prefs plist. Defaults to following the OS.
  ThemeMode get themeMode {
    final raw = _preferences.getString(_themeModeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode value) =>
      _preferences.setString(_themeModeKey, value.name);

  /// The language the user explicitly picked, or null while Stillora is still
  /// following the OS locale (the state on a fresh install).
  AppLanguage? get language {
    final raw = _preferences.getString(_languageKey);
    if (raw == null) return null;
    return AppLanguage.fromCode(raw);
  }

  Future<void> setLanguage(AppLanguage value) =>
      _preferences.setString(_languageKey, value.code);

  // ── Rating prompt ──────────────────────────────────────────────────────────

  /// Last time the review request was made, used for the 4-day cooldown.
  DateTime? get ratingLastPromptAt {
    final ms = _preferences.getInt(_ratingLastPromptKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setRatingLastPromptAt(DateTime value) {
    return _preferences.setInt(
      _ratingLastPromptKey,
      value.millisecondsSinceEpoch,
    );
  }

  /// Whether the one-time "rate after your first export" prompt has already been
  /// requested on this device. Once true, Stillora never auto-requests again.
  bool get hasRequestedRatingAfterFirstExport =>
      _preferences.getBool(_ratedAfterFirstExportKey) ?? false;

  Future<void> setHasRequestedRatingAfterFirstExport(bool value) {
    return _preferences.setBool(_ratedAfterFirstExportKey, value);
  }

  int get defaultDurationSeconds =>
      _preferences.getInt(_defaultDurationKey) ?? 10;

  Future<void> setDefaultDurationSeconds(int value) {
    return _preferences.setInt(_defaultDurationKey, value);
  }

  String get defaultPresetId =>
      _preferences.getString(_defaultPresetKey) ?? 'reels';

  Future<void> setDefaultPresetId(String value) {
    return _preferences.setString(_defaultPresetKey, value);
  }

  String get defaultResizeMode =>
      _preferences.getString(_defaultResizeModeKey) ?? 'fit';

  Future<void> setDefaultResizeMode(String value) {
    return _preferences.setString(_defaultResizeModeKey, value);
  }

  // ── Editor session (last open work, survives app restarts) ─────────────────

  static const _sessionKey = 'stillora.editor.session.v1';

  /// Returns the raw JSON map saved by [saveEditorSession], or null if nothing
  /// has been saved yet.
  Map<String, dynamic>? get savedEditorSession {
    final raw = _preferences.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveEditorSession(Map<String, dynamic> data) =>
      _preferences.setString(_sessionKey, jsonEncode(data));

  Future<void> clearEditorSession() => _preferences.remove(_sessionKey);

  // ── Reel session (standalone Reel composition, separate from Create) ───────

  static const _reelSessionKey = 'stillora.reel.session.v1';

  Map<String, dynamic>? get savedReelSession {
    final raw = _preferences.getString(_reelSessionKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveReelSession(Map<String, dynamic> data) =>
      _preferences.setString(_reelSessionKey, jsonEncode(data));

  Future<void> clearReelSession() => _preferences.remove(_reelSessionKey);

  // ── Usage analytics (buffered on-device, flushed ~every 12h) ───────────────

  static const _analyticsBufferKey = 'stillora.analytics.buffer.v1';
  static const _analyticsLastFlushKey = 'stillora.analytics.lastFlushMs';

  /// Completed usage sessions waiting to be flushed to the backend. Each entry
  /// is the JSON payload for one session (clientId, startedAt, durationSeconds,
  /// platform, screens).
  List<Map<String, dynamic>> get analyticsBuffer {
    final raw = _preferences.getString(_analyticsBufferKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> setAnalyticsBuffer(List<Map<String, dynamic>> sessions) =>
      _preferences.setString(_analyticsBufferKey, jsonEncode(sessions));

  /// When the buffer was last successfully flushed. Null until the first flush.
  DateTime? get analyticsLastFlushAt {
    final ms = _preferences.getInt(_analyticsLastFlushKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setAnalyticsLastFlushAt(DateTime value) =>
      _preferences.setInt(_analyticsLastFlushKey, value.millisecondsSinceEpoch);
}
