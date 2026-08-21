import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_preferences.dart';

/// Where the lifetime-Pro entitlement and the cached remote price live.
///
/// This is deliberately a tiny interface rather than a direct [AppPreferences]
/// read: `appPreferencesProvider` throws until it is overridden at startup, and
/// the Pro status is read by chrome that widget tests build in isolation (the
/// sidebar, every ad slot). Defaulting to an in-memory store keeps those tests
/// working without bootstrapping SharedPreferences.
abstract class ProStore {
  bool get isPro;
  Future<void> setPro(bool value);

  Map<String, dynamic>? get cachedConfig;
  Future<void> setCachedConfig(Map<String, dynamic> value);
}

class InMemoryProStore implements ProStore {
  bool _isPro = false;
  Map<String, dynamic>? _config;

  @override
  bool get isPro => _isPro;

  @override
  Future<void> setPro(bool value) async => _isPro = value;

  @override
  Map<String, dynamic>? get cachedConfig => _config;

  @override
  Future<void> setCachedConfig(Map<String, dynamic> value) async =>
      _config = value;
}

class PreferencesProStore implements ProStore {
  PreferencesProStore(this._preferences);

  final AppPreferences _preferences;

  @override
  bool get isPro => _preferences.isProUnlocked;

  @override
  Future<void> setPro(bool value) => _preferences.setProUnlocked(value);

  @override
  Map<String, dynamic>? get cachedConfig => _preferences.cachedProConfig;

  @override
  Future<void> setCachedConfig(Map<String, dynamic> value) =>
      _preferences.setCachedProConfig(value);
}

/// Overridden in `main.dart` with the SharedPreferences-backed store so the
/// entitlement survives restarts; the in-memory default keeps tests cheap.
final proStoreProvider = Provider<ProStore>((ref) => InMemoryProStore());
