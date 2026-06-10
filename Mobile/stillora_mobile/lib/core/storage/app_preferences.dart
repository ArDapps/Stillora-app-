import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _ratingLastPromptKey = 'stillora.rating.lastPromptMs';
  static const _ratedAfterFirstExportKey =
      'stillora.rating.requestedAfterFirstExport';

  final SharedPreferences _preferences;

  bool get hasSeenOnboarding =>
      _preferences.getBool(_hasSeenOnboardingKey) ?? false;

  Future<void> setHasSeenOnboarding(bool value) {
    return _preferences.setBool(_hasSeenOnboardingKey, value);
  }

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
}
