import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/app_preferences.dart';

/// Minimum gap between two review requests.
const _ratingCooldown = Duration(days: 4);

/// Requests the native store review after a successful export, at most once
/// per [_ratingCooldown] window. The OS (App Store / Play) decides whether the
/// dialog is actually shown and applies its own rate limits on top; if the user
/// rates, it stops appearing on its own.
///
/// On platforms without a native review dialog (Linux/Windows) it falls back to
/// opening [AppConstants.reviewUrl]. Safe to call on every export-success screen.
Future<void> maybePromptForReview(WidgetRef ref) async {
  final prefs = ref.read(appPreferencesProvider);

  final last = prefs.ratingLastPromptAt;
  final now = DateTime.now();
  if (last != null && now.difference(last) < _ratingCooldown) return;

  await prefs.setRatingLastPromptAt(now);

  try {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      return;
    }
  } catch (_) {
    // Plugin not registered on this platform — fall back to the URL below.
  }

  await launchUrl(
    Uri.parse(AppConstants.reviewUrl),
    mode: LaunchMode.externalApplication,
  );
}
