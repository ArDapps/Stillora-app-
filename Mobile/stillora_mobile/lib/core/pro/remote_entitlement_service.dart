import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';

/// What the Stillora server says about this account's Pro.
///
/// [unknown] is the important one. It is not "free" — it means the question
/// could not be answered (offline, 5xx, signed out), and the caller must leave
/// whatever entitlement it already had alone. Collapsing it into "not Pro"
/// would take the app away from someone who paid for it the moment their train
/// went into a tunnel.
enum RemoteEntitlement { pro, notPro, revoked, unknown }

@immutable
class RemoteProStatus {
  const RemoteProStatus(this.entitlement, {this.source});

  final RemoteEntitlement entitlement;

  /// 'apple' | 'google' | 'admin', when the server granted one.
  final String? source;

  bool get isPro => entitlement == RemoteEntitlement.pro;
}

/// Talks to `/api/pro/*` so a lifetime unlock follows the Stillora **account**
/// rather than a store account.
///
/// This is the only way Pro can work at all on Linux and Windows, which have no
/// store, and the only way a buyer who owns Pro on iPhone can be Pro on their
/// Android tablet — Apple and Google never tell each other anything.
class RemoteEntitlementService {
  RemoteEntitlementService(this._dio, this._token);

  final Dio _dio;

  /// Read at call time, not construction: someone may sign in after launch.
  final String? Function() _token;

  static String get _platform {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isAndroid) return 'android';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {
      // Platform throws on unsupported targets; the server treats '' as unknown.
    }
    return '';
  }

  Options? _authed() {
    final token = _token();
    if (token == null || token.isEmpty) return null;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// Asks the server what this account owns. Never throws.
  Future<RemoteProStatus> fetch() async {
    final options = _authed();
    if (options == null) {
      return const RemoteProStatus(RemoteEntitlement.unknown);
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/pro/entitlement',
        options: options,
      );
      final data = response.data;
      if (response.statusCode != 200 || data == null) {
        return const RemoteProStatus(RemoteEntitlement.unknown);
      }
      if (data['isPro'] == true) {
        return RemoteProStatus(
          RemoteEntitlement.pro,
          source: data['source'] as String?,
        );
      }
      // Not Pro *and* the server says a grant was explicitly taken back. This
      // is the single case where the app is allowed to turn Pro off.
      if (data['revoked'] == true) {
        return const RemoteProStatus(RemoteEntitlement.revoked);
      }
      return const RemoteProStatus(RemoteEntitlement.notPro);
    } on DioException {
      return const RemoteProStatus(RemoteEntitlement.unknown);
    } catch (_) {
      return const RemoteProStatus(RemoteEntitlement.unknown);
    }
  }

  /// Attaches a store purchase to the signed-in account so the user's other
  /// platforms can see it. Safe to call repeatedly — the server upserts.
  ///
  /// Returns false when it could not be recorded (signed out, offline); the
  /// caller simply tries again next launch rather than treating it as an error
  /// worth showing anyone. The purchase is already valid on this device.
  Future<bool> redeem({
    required String source,
    required String productId,
    required String storeToken,
  }) async {
    final options = _authed();
    if (options == null) return false;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/pro/redeem',
        data: {
          'source': source,
          'productId': productId,
          'storeToken': storeToken,
          'platform': _platform,
        },
        options: options,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

final remoteEntitlementServiceProvider = Provider<RemoteEntitlementService>((ref) {
  return RemoteEntitlementService(
    ref.watch(dioProvider),
    () => ref.read(authControllerProvider).value?.token,
  );
});
