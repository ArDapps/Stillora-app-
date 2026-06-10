import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../core/storage/app_preferences.dart';

/// Short pause so the Export Complete screen is visible before the system rating
/// sheet appears (Apple's guidance: ask after the user has seen the value).
const _ratingDelay = Duration(milliseconds: 1500);

/// Requests the native App Store / Play rating prompt exactly once, after the
/// user's first successful export, on this device.
///
/// Contract (see the feature spec):
/// - Only fires when an export actually succeeded (caller verifies the file).
/// - Never fires on launch, onboarding, auth, or a failed export.
/// - Persists [AppPreferences.hasRequestedRatingAfterFirstExport] so it is never
///   auto-requested again on the same device — even if StoreKit shows nothing.
/// - Works for guests and signed-in users alike (no session check).
///
/// StoreKit ultimately decides whether the dialog is shown; we make no custom
/// fallback prompt and never gate on, or react to, the rating the user gives.
Future<void> maybePromptForReview(WidgetRef ref) async {
  final prefs = ref.read(appPreferencesProvider);

  if (prefs.hasRequestedRatingAfterFirstExport) {
    return;
  }

  // Mark first so a slow/duplicate caller can never double-request.
  await prefs.setHasRequestedRatingAfterFirstExport(true);

  // Let the Export Complete screen settle before asking.
  await Future<void>.delayed(_ratingDelay);

  try {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      // On modern iOS this routes to StoreKit's SKStoreReviewController /
      // AppStore.requestReview(in:) using the active window scene.
      await inAppReview.requestReview();
    }
  } catch (_) {
    // StoreKit unavailable or declined to show — that's fine, never retry.
  }
}
