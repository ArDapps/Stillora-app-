import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

/// Securely persists the Stillora session token plus the Apple credential cache.
///
/// Apple only returns the user's name and email on the *first* authorization, so
/// we cache them (alongside the stable Apple user identifier) and reuse them on
/// later logins. We never overwrite a cached value with null/empty.
class TokenStorage {
  TokenStorage(this._storage);

  static const _tokenKey = 'stillora.session.token';
  static const _appleUserIdKey = 'stillora.apple.userId';
  static const _appleNameKey = 'stillora.apple.name';
  static const _appleEmailKey = 'stillora.apple.email';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  // ── Apple credential cache ──────────────────────────────────────────────

  Future<String?> readAppleUserId() => _storage.read(key: _appleUserIdKey);

  Future<void> saveAppleUserId(String userId) =>
      _storage.write(key: _appleUserIdKey, value: userId);

  Future<String?> readAppleName() => _storage.read(key: _appleNameKey);

  Future<String?> readAppleEmail() => _storage.read(key: _appleEmailKey);

  /// Stores Apple-provided profile fields, ignoring null/empty values so a
  /// later sign-in (where Apple sends nothing) never clears a saved name/email.
  Future<void> cacheAppleProfile({String? name, String? email}) async {
    if (name != null && name.trim().isNotEmpty) {
      await _storage.write(key: _appleNameKey, value: name.trim());
    }
    if (email != null && email.trim().isNotEmpty) {
      await _storage.write(key: _appleEmailKey, value: email.trim());
    }
  }

  /// Clears the session token but keeps the Apple profile cache so a returning
  /// user still gets their name/email after signing back in.
  Future<void> clear() => _storage.delete(key: _tokenKey);

  /// Wipes everything, including the Apple cache. Used on account deletion.
  Future<void> clearAll() => Future.wait([
    _storage.delete(key: _tokenKey),
    _storage.delete(key: _appleUserIdKey),
    _storage.delete(key: _appleNameKey),
    _storage.delete(key: _appleEmailKey),
  ]);
}
