import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../api/api_client.dart';
import '../constants/app_constants.dart';
import 'desktop_google_auth.dart';
import 'session.dart';
import 'token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    googleSignIn: GoogleSignIn.instance,
  );
});

class AuthRepository {
  AuthRepository({
    required Dio dio,
    required TokenStorage tokenStorage,
    required GoogleSignIn googleSignIn,
  }) : _dio = dio,
       _tokenStorage = tokenStorage,
       _googleSignIn = googleSignIn;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final GoogleSignIn _googleSignIn;
  static const _googleProfileScopes = ['openid', 'email', 'profile'];

  Future<AuthSession?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      return null;
    }

    // If this device signed in with Apple, honour a revoked/removed credential
    // by ending the local session instead of restoring a stale one.
    if (await _isAppleCredentialRevoked()) {
      await _tokenStorage.clear();
      return null;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final userJson = response.data?['user'];
      if (userJson is Map<String, dynamic>) {
        return AuthSession(token: token, user: SessionUser.fromJson(userJson));
      }
    } on DioException {
      return null;
    }

    return null;
  }

  Future<AuthSession> signInWithGoogle() async {
    if (Platform.isLinux || Platform.isWindows) {
      return _signInWithGoogleDesktop();
    }

    final clientId = Platform.isMacOS
        ? AppConstants.googleMacosClientId
        : Platform.isIOS
        ? AppConstants.googleIosClientId
        : null;
    try {
      await _googleSignIn.initialize(
        clientId: clientId,
        serverClientId: AppConstants.googleWebClientId,
      );
      final account = await _googleSignIn.authenticate(
        scopeHint: _googleProfileScopes,
      );
      final idToken = account.authentication.idToken;
      final authorization =
          await account.authorizationClient.authorizationForScopes(
            _googleProfileScopes,
          ) ??
          await account.authorizationClient.authorizeScopes(
            _googleProfileScopes,
          );
      final accessToken = authorization.accessToken;
      if ((idToken == null || idToken.isEmpty) && accessToken.isEmpty) {
        throw const AuthFailure('Google sign-in was cancelled.');
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/mobile',
        data: {
          if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
          'accessToken': accessToken,
          'app': 'stillora',
        },
      );
      final data = response.data ?? const <String, dynamic>{};
      final token = data['token'] as String?;
      final userJson = data['user'];
      if (token == null || userJson is! Map<String, dynamic>) {
        throw const AuthFailure('Google sign-in failed.');
      }

      await _tokenStorage.saveToken(token);
      return AuthSession(token: token, user: SessionUser.fromJson(userJson));
    } on AuthFailure {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw AuthFailure(_googleSignInMessage(error));
    } on PlatformException catch (error) {
      throw AuthFailure(error.message ?? 'Google sign-in failed.');
    } on DioException catch (error) {
      throw AuthFailure(
        error.response?.data is Map
            ? (error.response!.data as Map)['error'] as String? ??
                  'Stillora could not verify your Google account.'
            : 'Stillora could not verify your Google account.',
      );
    }
  }

  /// Linux/Windows Google sign-in via the installed-app loopback + PKCE flow,
  /// since `google_sign_in` has no desktop implementation. The resulting Google
  /// tokens go through the same `/api/auth/mobile` exchange as mobile.
  Future<AuthSession> _signInWithGoogleDesktop() async {
    try {
      final desktopAuth = DesktopGoogleAuth(
        clientId: AppConstants.googleDesktopClientId,
        clientSecret: AppConstants.googleDesktopClientSecret,
      );
      final tokens = await desktopAuth.signIn();

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/mobile',
        data: {
          if (tokens.idToken != null && tokens.idToken!.isNotEmpty)
            'idToken': tokens.idToken,
          'accessToken': tokens.accessToken,
          'app': 'stillora',
        },
      );
      final data = response.data ?? const <String, dynamic>{};
      final token = data['token'] as String?;
      final userJson = data['user'];
      if (token == null || userJson is! Map<String, dynamic>) {
        throw const AuthFailure('Google sign-in failed.');
      }

      await _tokenStorage.saveToken(token);
      return AuthSession(token: token, user: SessionUser.fromJson(userJson));
    } on AuthFailure {
      rethrow;
    } on DioException catch (error) {
      throw AuthFailure(
        error.response?.data is Map
            ? (error.response!.data as Map)['error'] as String? ??
                  'Stillora could not verify your Google account.'
            : 'Stillora could not verify your Google account.',
      );
    }
  }

  Future<AuthSession> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS && !Platform.isAndroid) {
      throw const AuthFailure(
        'Sign in with Apple is not supported on this platform yet.',
      );
    }
    if (Platform.isIOS || Platform.isMacOS) {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        throw const AuthFailure(
          'Sign in with Apple requires iOS 13 or later.',
        );
      }
    }

    // A raw nonce is sent to Apple as its SHA-256 hash; the backend compares the
    // raw value against the `nonce` claim in the identity token to block replay.
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
        webAuthenticationOptions: (Platform.isAndroid)
            ? WebAuthenticationOptions(
                clientId: AppConstants.appleServiceId,
                redirectUri: Uri.parse(AppConstants.appleRedirectUri),
              )
            : null,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const AuthFailure('Sign in with Apple failed. Please try again.');
      }

      // Apple sends name/email only on the very first authorization. Cache them
      // and fall back to the cache on later logins so we never send nulls.
      final userId = credential.userIdentifier;
      if (userId != null && userId.isNotEmpty) {
        await _tokenStorage.saveAppleUserId(userId);
      }
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((part) => part != null && part.isNotEmpty).join(' ').trim();
      await _tokenStorage.cacheAppleProfile(
        name: fullName.isEmpty ? null : fullName,
        email: credential.email,
      );

      final cachedName = await _tokenStorage.readAppleName();
      final cachedEmail = await _tokenStorage.readAppleEmail();
      final resolvedName = fullName.isNotEmpty ? fullName : cachedName;
      final resolvedEmail = (credential.email != null &&
              credential.email!.isNotEmpty)
          ? credential.email
          : cachedEmail;

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/mobile',
        data: {
          'provider': 'apple',
          'appleIdToken': identityToken,
          'rawNonce': rawNonce,
          if (credential.authorizationCode.isNotEmpty)
            'appleAuthorizationCode': credential.authorizationCode,
          if (resolvedName != null && resolvedName.isNotEmpty)
            'name': resolvedName,
          if (resolvedEmail != null && resolvedEmail.isNotEmpty)
            'email': resolvedEmail,
          'app': 'stillora',
        },
      );

      final data = response.data ?? const <String, dynamic>{};
      final token = data['token'] as String?;
      final userJson = data['user'];
      if (token == null || userJson is! Map<String, dynamic>) {
        throw const AuthFailure('Sign in with Apple failed.');
      }

      await _tokenStorage.saveToken(token);
      return AuthSession(token: token, user: SessionUser.fromJson(userJson));
    } on AuthFailure {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (error) {
      throw AuthFailure(_appleSignInMessage(error));
    } on SignInWithAppleException {
      throw const AuthFailure('Sign in with Apple failed. Please try again.');
    } on DioException catch (error) {
      throw AuthFailure(_dioMessage(error, fallbackProvider: 'Apple'));
    }
  }

  Future<void> signOut() async {
    await _tokenStorage.clear();
    if (Platform.isLinux || Platform.isWindows) {
      return;
    }
    await _googleSignIn.signOut();
  }

  Future<void> deleteAccount() async {
    final token = await _tokenStorage.readToken();
    try {
      await _dio.delete<void>(
        '/api/auth/delete-account',
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
    } on DioException {
      // Continue with local cleanup even if the server call fails
    }
    // Account deletion wipes the Apple credential cache too.
    await _tokenStorage.clearAll();
    if (!Platform.isLinux && !Platform.isWindows) {
      await _googleSignIn.signOut();
    }
  }

  /// True when this device previously signed in with Apple and that credential
  /// has since been revoked or removed. Never throws — failures mean "unknown",
  /// in which case we keep the session and let `/api/auth/me` decide.
  Future<bool> _isAppleCredentialRevoked() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return false;
    }
    final appleUserId = await _tokenStorage.readAppleUserId();
    if (appleUserId == null || appleUserId.isEmpty) {
      return false;
    }
    try {
      final state = await SignInWithApple.getCredentialState(appleUserId);
      return state == CredentialState.revoked ||
          state == CredentialState.notFound;
    } catch (_) {
      return false;
    }
  }

  String _appleSignInMessage(SignInWithAppleAuthorizationException error) {
    if (error.code == AuthorizationErrorCode.canceled) {
      return 'Sign in with Apple was cancelled.';
    }
    if (error.code == AuthorizationErrorCode.notInteractive ||
        error.code == AuthorizationErrorCode.notHandled) {
      return 'Sign in with Apple is unavailable right now. Please try again.';
    }
    return 'Sign in with Apple failed. Please check your connection and '
        'try again.';
  }

  String _dioMessage(DioException error, {required String fallbackProvider}) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    return 'Stillora could not verify your $fallbackProvider account.';
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _googleSignInMessage(GoogleSignInException error) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return 'Google sign-in was cancelled.';
    }

    final description = error.description;
    if (description != null && description.isNotEmpty) {
      return description;
    }

    if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
        error.code == GoogleSignInExceptionCode.providerConfigurationError) {
      return 'Google sign-in is not configured correctly for this app.';
    }

    return 'Google sign-in failed. Please try again.';
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}
