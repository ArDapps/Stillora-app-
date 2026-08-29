import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../platform/platform_info.dart';
import '../storage/app_preferences.dart';

/// Distinct failures reported per app run. A widget that throws on every frame
/// would otherwise flood the endpoint; the dashboard dedupes anyway, but the
/// requests are still wasted.
const _maxReportsPerRun = 20;

final errorReporterProvider = Provider<ErrorReporter>((ref) {
  return ErrorReporter(ref);
});

/// Ships crashes to the backend so they appear on /admin/errors next to server
/// failures, tagged with this device, platform and app version.
///
/// Everything here is best-effort and silent: reporting a crash must never
/// cause one, and must never change what the person sees on screen.
class ErrorReporter {
  ErrorReporter(this._ref);

  final Ref _ref;
  final Set<String> _seen = {};
  int _sent = 0;

  /// Installs the global Flutter and Dart error handlers. Call once at startup,
  /// before `runApp`, inside the same zone the app runs in.
  void install() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      // Keep the default behaviour (red screen in debug, console log) — this
      // only adds the report.
      previousOnError?.call(details);
      unawaited(
        report(
          source: 'flutter/${details.library ?? 'widgets'}',
          error: details.exception,
          stack: details.stack,
        ),
      );
    };

    // Errors that escape the widget tree entirely (async gaps, isolates).
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(report(source: 'flutter/uncaught', error: error, stack: stack));
      return true;
    };
  }

  /// Reports one failure. Safe to call from anywhere, including a `catch`.
  Future<void> report({
    required String source,
    required Object error,
    StackTrace? stack,
    String? screen,
  }) async {
    try {
      if (_sent >= _maxReportsPerRun) return;
      final message = error.toString();
      if (message.isEmpty) return;

      final key = '$source|$message';
      if (!_seen.add(key)) return;
      _sent++;

      final prefs = _ref.read(appPreferencesProvider);
      await _ref
          .read(dioProvider)
          .post<void>(
            '/api/errors',
            data: {
              'source': source,
              'name': error.runtimeType.toString(),
              'message': message,
              'stack': stack?.toString() ?? '',
              'url': screen ?? '',
              'platform': platformName(),
              'deviceId': prefs.deviceId,
            },
            options: Options(
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );
    } catch (_) {
      // A crash reporter that throws is worse than no crash reporter.
    }
  }
}
