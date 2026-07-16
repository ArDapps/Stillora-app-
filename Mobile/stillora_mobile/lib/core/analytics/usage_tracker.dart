import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../storage/app_preferences.dart';

/// How often the buffered usage is flushed to the backend. The app never sends
/// live beacons; it caches sessions on-device and uploads them at most this
/// often, so a normal user makes ~2 analytics requests a day instead of one
/// every 30 seconds.
const _flushInterval = Duration(hours: 12);

/// Foreground periods shorter than this are ignored — they're almost always an
/// accidental tap-through, not real usage.
const _minSessionSeconds = 2;

/// Hard cap on buffered sessions so an offline device can't grow the store
/// without bound; oldest entries are dropped first.
const _maxBufferedSessions = 500;

/// Hard cap on screens recorded per session (defensive against a redirect loop).
const _maxScreensPerSession = 100;

final usageTrackerProvider = Provider<UsageTracker>((ref) {
  return UsageTracker(ref);
});

/// Reports app-usage sessions to the shared backend (`/api/track`) so mobile and
/// desktop activity shows up in the admin analytics dashboard next to web —
/// including country (resolved server-side from IP), platform, and time-used.
///
/// A "session" spans one foreground period: it opens when the app starts or
/// returns to the foreground and closes when it's backgrounded. Instead of
/// pinging live, each completed session is measured on-device, buffered to
/// [AppPreferences], and uploaded in a single batch no more than once every
/// [_flushInterval]. All work is fire-and-forget; tracking must never disrupt
/// the app.
class UsageTracker {
  UsageTracker(this._ref);

  final Ref _ref;

  /// Stable id for the current foreground session, regenerated each time a new
  /// session starts so buffered sessions stay distinct.
  String _clientId = _newClientId();

  /// When the current foreground session opened, or null if none is open.
  DateTime? _startedAt;

  /// Screens visited during the current session, in order.
  final List<String> _screens = [];
  String _lastScreen = '';

  /// Opens a new foreground session and, if the flush window has elapsed,
  /// uploads whatever is already buffered.
  Future<void> start() async {
    _clientId = _newClientId();
    _startedAt = DateTime.now();
    _screens.clear();
    _lastScreen = '';
    await _maybeFlush();
  }

  /// Closes the current session: buffers it locally (if it lasted long enough),
  /// then attempts a flush.
  Future<void> end() async {
    final startedAt = _startedAt;
    _startedAt = null;
    if (startedAt != null) {
      final duration = DateTime.now().difference(startedAt).inSeconds;
      if (duration >= _minSessionSeconds) {
        await _bufferSession({
          'clientId': _clientId,
          'startedAt': startedAt.toUtc().toIso8601String(),
          'durationSeconds': duration,
          'platform': _platformName(),
          'screens': List<String>.from(_screens),
        });
      }
    }
    await _maybeFlush();
  }

  /// Records which screen/feature the user opened, attributed to the open
  /// session. De-duplicates consecutive reports of the same screen (the router's
  /// redirect hook can fire more than once for a single navigation). No network.
  Future<void> screen(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _lastScreen) return;
    _lastScreen = trimmed;
    if (_startedAt == null) return;
    if (_screens.length < _maxScreensPerSession) _screens.add(trimmed);
  }

  Future<void> _bufferSession(Map<String, dynamic> session) async {
    try {
      final prefs = _ref.read(appPreferencesProvider);
      final buffer = [...prefs.analyticsBuffer, session];
      final trimmed = buffer.length > _maxBufferedSessions
          ? buffer.sublist(buffer.length - _maxBufferedSessions)
          : buffer;
      await prefs.setAnalyticsBuffer(trimmed);
    } catch (_) {
      // Telemetry must never surface an error to the user.
    }
  }

  /// Uploads the buffer when [_flushInterval] has passed since the last flush.
  /// On a fresh install it just starts the window without sending anything.
  Future<void> _maybeFlush() async {
    try {
      final prefs = _ref.read(appPreferencesProvider);
      final last = prefs.analyticsLastFlushAt;
      if (last == null) {
        await prefs.setAnalyticsLastFlushAt(DateTime.now());
        return;
      }
      if (DateTime.now().difference(last) < _flushInterval) return;

      final buffer = prefs.analyticsBuffer;
      if (buffer.isEmpty) {
        await prefs.setAnalyticsLastFlushAt(DateTime.now());
        return;
      }
      await _flush(prefs, buffer);
    } catch (_) {
      // Never let tracking break the app.
    }
  }

  Future<void> _flush(
    AppPreferences prefs,
    List<Map<String, dynamic>> sent,
  ) async {
    try {
      final token = _ref.read(authControllerProvider).asData?.value?.token;
      await _ref.read(dioProvider).post<void>(
        '/api/track',
        data: {
          'event': 'batch',
          'platform': _platformName(),
          'sessions': sent,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          // A late batch is still worth sending, but don't hang forever.
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      // Drop only what we sent; a session may have been buffered mid-flush.
      final remaining = prefs.analyticsBuffer.skip(sent.length).toList();
      await prefs.setAnalyticsBuffer(remaining);
      await prefs.setAnalyticsLastFlushAt(DateTime.now());
    } catch (_) {
      // Keep the buffer and retry on a later open once the window elapses again.
    }
  }
}

String _platformName() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    _ => 'web',
  };
}

final _random = Random();

String _newClientId() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  final suffix = List.generate(
    8,
    (_) => _random.nextInt(16).toRadixString(16),
  ).join();
  return 'm-$ts-$suffix';
}

/// Invisible widget that drives the [UsageTracker] from the app lifecycle:
/// opens a session on mount / foreground and closes (and buffers) it when the
/// app is backgrounded or disposed. Mount it once near the app root so it stays
/// alive across every route.
class UsageTrackerHost extends ConsumerStatefulWidget {
  const UsageTrackerHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UsageTrackerHost> createState() => _UsageTrackerHostState();
}

class _UsageTrackerHostState extends ConsumerState<UsageTrackerHost>
    with WidgetsBindingObserver {
  bool _sessionOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openSession();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _openSession();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _closeSession();
    }
  }

  void _openSession() {
    if (_sessionOpen) return;
    _sessionOpen = true;
    unawaited(ref.read(usageTrackerProvider).start());
  }

  void _closeSession() {
    if (!_sessionOpen) return;
    _sessionOpen = false;
    unawaited(ref.read(usageTrackerProvider).end());
  }

  @override
  void dispose() {
    _closeSession();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
