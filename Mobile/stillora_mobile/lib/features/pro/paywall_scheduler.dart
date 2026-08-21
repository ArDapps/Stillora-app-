import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_gate.dart';
import '../../core/storage/app_preferences.dart';

/// How long a Free user is left alone between automatic paywalls.
const proPaywallInterval = Duration(hours: 48);

/// Short pause so the screen underneath has painted before the paywall slides
/// over it — the same courtesy the rating prompt gives the review sheet.
const _paywallDelay = Duration(milliseconds: 450);

/// The whole schedule, as a pure function of the two things it depends on.
///
/// Pro users are never due — the entitlement is read live rather than baked
/// into a stored schedule, so someone who upgrades stops being interrupted the
/// moment the purchase lands, with no cooldown left to expire.
///
/// A null [lastShownAt] is due: that is a device which has never been offered
/// Pro automatically, including one updating into this feature.
bool isPaywallDue({
  required bool isPro,
  required DateTime? lastShownAt,
  required DateTime now,
}) {
  if (isPro) return false;
  if (lastShownAt == null) return true;
  return now.difference(lastShownAt) >= proPaywallInterval;
}

/// [isPaywallDue] applied to the live app state.
bool isScheduledPaywallDue(WidgetRef ref) {
  return isPaywallDue(
    isPro: ref.read(isProProvider),
    lastShownAt: ref.read(appPreferencesProvider).proPaywallLastShownAt,
    now: DateTime.now(),
  );
}

/// Opens the paywall once, immediately after the first-run walkthrough.
///
/// This is a *push* onto Create, not a gate: dismissing it lands on the full
/// free toolkit, and nothing shown during onboarding is locked. It also starts
/// the [proPaywallInterval] clock, so the first recurring reminder is a full 48
/// hours out instead of on the next launch.
Future<void> showPaywallAfterOnboarding(GoRouter router, WidgetRef ref) {
  return _open(router, ref, ProFeature.afterOnboarding);
}

/// Opens the paywall if [isScheduledPaywallDue]. Safe to call on every launch
/// and every foreground resume — the stored timestamp does the rate limiting.
Future<void> maybeShowScheduledPaywall(GoRouter router, WidgetRef ref) {
  if (!isScheduledPaywallDue(ref)) return Future<void>.value();
  return _open(router, ref, ProFeature.scheduledReminder);
}

/// Both entry points take a [GoRouter] rather than a [BuildContext] on purpose.
///
/// Every automatic paywall is opened by a screen that is on its way out — the
/// splash and the last onboarding slide both `go()` to Create first — so by the
/// time [_paywallDelay] elapses their context is unmounted and `context.push`
/// would be dropped on the floor. The router is a provider that outlives any
/// one route, so it is always safe to push on.
Future<void> _open(GoRouter router, WidgetRef ref, ProFeature reason) async {
  if (ref.read(isProProvider)) return;
  // Never stack a second copy on a paywall that is already open.
  if (router.state.uri.path == ProLimits.proRoutePath) return;

  // Stamped before showing, never after: a duplicate call — two lifecycle
  // events in the same second, a rebuild mid-delay — must not open two.
  await ref
      .read(appPreferencesProvider)
      .setProPaywallLastShownAt(DateTime.now());

  await Future<void>.delayed(_paywallDelay);
  router.push(ProLimits.proRoutePath, extra: reason);
}
