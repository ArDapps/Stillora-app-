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

  final SharedPreferences _preferences;

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
}
