import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/api_client.dart';
import '../constants/app_constants.dart';
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
      throw const AuthFailure(
        'Google sign-in is not supported on Linux or Windows desktop yet.',
      );
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

  Future<void> signOut() async {
    await _tokenStorage.clear();
    if (Platform.isLinux || Platform.isWindows) {
      return;
    }
    await _googleSignIn.signOut();
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
