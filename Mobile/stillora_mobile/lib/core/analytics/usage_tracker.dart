import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';

/// How often a foregrounded app pings the backend to keep its session alive.
const _heartbeatInterval = Duration(seconds: 30);

final usageTrackerProvider = Provider<UsageTracker>((ref) {
  return UsageTracker(ref);
});

/// Reports app-usage sessions to the shared backend (`/api/track`) so mobile and
/// desktop activity shows up in the admin analytics dashboard next to web —
/// including country (resolved server-side from IP), platform, and time-used.
///
/// A "session" spans one foreground period: it opens when the app starts or
/// returns to the foreground and closes when it's backgrounded. All calls are
/// fire-and-forget; tracking must never disrupt the app.
class UsageTracker {
  UsageTracker(this._ref);

  final Ref _ref;

  /// Stable id for the current foreground session. Regenerated each time a new
  /// session starts so heartbeats within one session share an id but distinct
  /// sessions stay separate.
  String _clientId = _newClientId();

  Future<void> start() {
    _clientId = _newClientId();
    return _send('start');
  }

  Future<void> heartbeat() => _send('heartbeat');

  Future<void> end() => _send('end');

  String _lastScreen = '';

  /// Reports which screen/feature the user opened, linked to the live session.
  /// De-duplicates consecutive reports of the same screen (the router's redirect
  /// hook can fire more than once for a single navigation).
  Future<void> screen(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _lastScreen) return Future.value();
    _lastScreen = trimmed;
    return _send('screen', screen: trimmed);
  }

  Future<void> _send(String event, {String? screen}) async {
    try {
      final token = _ref.read(authControllerProvider).asData?.value?.token;
      await _ref.read(dioProvider).post<void>(
        '/api/track',
        data: {
          'clientId': _clientId,
          'event': event,
          'platform': _platformName(),
          if (screen != null && screen.isNotEmpty) 'screen': screen,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          // A late beacon is worthless; don't let it pile up on a bad network.
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
    } catch (_) {
      // Telemetry must never surface an error to the user.
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
/// opens a session on mount / foreground, heartbeats every 30s while visible,
/// and closes the session when the app is backgrounded or disposed. Mount it
/// once near the app root so it stays alive across every route.
class UsageTrackerHost extends ConsumerStatefulWidget {
  const UsageTrackerHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UsageTrackerHost> createState() => _UsageTrackerHostState();
}

class _UsageTrackerHostState extends ConsumerState<UsageTrackerHost>
    with WidgetsBindingObserver {
  Timer? _timer;
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
    _timer?.cancel();
    _timer = Timer.periodic(_heartbeatInterval, (_) {
      unawaited(ref.read(usageTrackerProvider).heartbeat());
    });
  }

  void _closeSession() {
    if (!_sessionOpen) return;
    _sessionOpen = false;
    _timer?.cancel();
    _timer = null;
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
