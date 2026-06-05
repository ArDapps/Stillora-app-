import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/api_client.dart';
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
    await _googleSignIn.initialize();
    final account = await _googleSignIn.authenticate();
    final authorization = await account.authorizationClient
        .authorizationForScopes(const ['openid', 'email', 'profile']);
    final accessToken = authorization?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthFailure('Google sign-in was cancelled.');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/mobile',
      data: {'accessToken': accessToken, 'app': 'stillora'},
    );
    final data = response.data ?? const <String, dynamic>{};
    final token = data['token'] as String?;
    final userJson = data['user'];
    if (token == null || userJson is! Map<String, dynamic>) {
      throw const AuthFailure('Google sign-in failed.');
    }

    await _tokenStorage.saveToken(token);
    return AuthSession(token: token, user: SessionUser.fromJson(userJson));
  }

  Future<void> signOut() async {
    await _tokenStorage.clear();
    await _googleSignIn.signOut();
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}
