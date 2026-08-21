import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/pro/paywall_scheduler.dart';
import 'router.dart';

/// Invisible widget that re-checks the [proPaywallInterval] whenever the app
/// returns to the foreground. Mount it once near the app root, alongside
/// `UsageTrackerHost`.
///
/// Cold launches are covered by `SplashScreen`; this is what makes "every 48
/// hours" true for a session that never restarts — a phone that only ever gets
/// backgrounded, or a Mac window left open for days.
class ProPaywallScheduleHost extends ConsumerStatefulWidget {
  const ProPaywallScheduleHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProPaywallScheduleHost> createState() =>
      _ProPaywallScheduleHostState();
}

class _ProPaywallScheduleHostState extends ConsumerState<ProPaywallScheduleHost>
    with WidgetsBindingObserver {
  /// Deliberately not checked on mount: the app is still on the splash screen
  /// at that point, and `SplashScreen` does a `go()` that would wipe a pushed
  /// paywall off the stack.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(maybeShowScheduledPaywall(ref.read(routerProvider), ref));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
