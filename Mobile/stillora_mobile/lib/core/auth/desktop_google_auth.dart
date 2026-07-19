import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_repository.dart' show AuthFailure;

/// Tokens returned by the desktop Google OAuth loopback flow.
class DesktopGoogleAuthResult {
  const DesktopGoogleAuthResult({required this.accessToken, this.idToken});

  final String accessToken;
  final String? idToken;
}

/// Google sign-in for Linux/Windows desktop, where the `google_sign_in` plugin
/// has no implementation. Uses Google's recommended installed-app flow:
/// system browser + loopback redirect + PKCE. Requires a Google Cloud
/// "Desktop app" OAuth client (id + secret).
class DesktopGoogleAuth {
  DesktopGoogleAuth({required this.clientId, required this.clientSecret});

  final String clientId;
  final String clientSecret;

  // A dedicated client so the app's base URL / interceptors never touch the
  // calls to Google's endpoints.
  final Dio _google = Dio();

  static const _authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const _scopes = 'openid email profile';

  Future<DesktopGoogleAuthResult> signIn() async {
    if (clientId.isEmpty) {
      throw const AuthFailure(
        'Desktop Google sign-in is not configured. Build with '
        '--dart-define=GOOGLE_DESKTOP_CLIENT_ID=... (and CLIENT_SECRET).',
      );
    }

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${server.port}';
    final verifier = _randomString(64);
    final challenge = _base64Url(sha256.convert(ascii.encode(verifier)).bytes);
    final stateToken = _randomString(24);

    final authUrl = Uri.parse(_authEndpoint).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopes,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'state': stateToken,
        'access_type': 'offline',
        'prompt': 'select_account',
      },
    );

    try {
      final launched = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const AuthFailure('Could not open a browser for Google sign-in.');
      }

      final HttpRequest request;
      try {
        request = await server.first.timeout(const Duration(minutes: 5));
      } on TimeoutException {
        throw const AuthFailure('Google sign-in timed out. Please try again.');
      }

      final params = request.uri.queryParameters;
      final ok = params['error'] == null && params['code'] != null;
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write(_resultHtml(ok));
      await request.response.close();

      if (params['error'] != null) {
        throw AuthFailure(
          params['error'] == 'access_denied'
              ? 'Google sign-in was cancelled.'
              : 'Google sign-in failed (${params['error']}).',
        );
      }
      if (params['state'] != stateToken) {
        throw const AuthFailure('Google sign-in failed (state mismatch).');
      }
      final code = params['code'];
      if (code == null || code.isEmpty) {
        throw const AuthFailure('Google sign-in was cancelled.');
      }

      return _exchangeCode(
        code: code,
        verifier: verifier,
        redirectUri: redirectUri,
      );
    } finally {
      await server.close(force: true);
    }
  }

  Future<DesktopGoogleAuthResult> _exchangeCode({
    required String code,
    required String verifier,
    required String redirectUri,
  }) async {
    try {
      final response = await _google.post<Map<String, dynamic>>(
        _tokenEndpoint,
        data: {
          'client_id': clientId,
          if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
          'code': code,
          'code_verifier': verifier,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final data = response.data ?? const <String, dynamic>{};
      final accessToken = data['access_token'] as String?;
      final idToken = data['id_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw const AuthFailure('Google did not return an access token.');
      }
      return DesktopGoogleAuthResult(
        accessToken: accessToken,
        idToken: idToken,
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final description = data is Map ? data['error_description'] : null;
      throw AuthFailure(
        description is String
            ? 'Google sign-in failed: $description'
            : 'Google sign-in failed. Please try again.',
      );
    }
  }

  static String _randomString(int length) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _base64Url(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _resultHtml(bool ok) {
    final title = ok ? 'Signed in to Stillora' : 'Sign-in failed';
    final body = ok
        ? 'You can close this tab and return to the Stillora app.'
        : 'Something went wrong. Return to Stillora and try again.';
    return '''
<!doctype html><html><head><meta charset="utf-8"><title>$title</title>
<style>body{font-family:system-ui,sans-serif;background:#0c0718;color:#fff;
display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
.card{text-align:center;padding:32px 40px;border-radius:16px;
background:rgba(255,255,255,.05)}h1{font-weight:800;margin:0 0 8px}
p{color:#b6b2c8;margin:0}</style></head>
<body><div class="card"><h1>$title</h1><p>$body</p></div></body></html>''';
  }
}
