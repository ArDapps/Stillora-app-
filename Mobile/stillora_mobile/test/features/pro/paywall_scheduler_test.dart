import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/core/storage/app_preferences.dart';
import 'package:stillora_mobile/features/pro/paywall_scheduler.dart';

/// The automatic paywall has to earn its interruption: twice a day is spam,
/// and a user who has paid must never see it again.
void main() {
  final now = DateTime(2026, 8, 21, 12);

  test('interval is 48 hours', () {
    expect(proPaywallInterval, const Duration(hours: 48));
  });

  test('due on a device that has never been offered Pro', () {
    expect(isPaywallDue(isPro: false, lastShownAt: null, now: now), isTrue);
  });

  test('never due for a Pro user, however long it has been', () {
    expect(isPaywallDue(isPro: true, lastShownAt: null, now: now), isFalse);
    expect(
      isPaywallDue(
        isPro: true,
        lastShownAt: now.subtract(const Duration(days: 365)),
        now: now,
      ),
      isFalse,
    );
  });

  test('not due inside the 48-hour window', () {
    expect(
      isPaywallDue(
        isPro: false,
        lastShownAt: now.subtract(const Duration(hours: 47, minutes: 59)),
        now: now,
      ),
      isFalse,
    );
  });

  test('due once 48 hours have passed', () {
    expect(
      isPaywallDue(
        isPro: false,
        lastShownAt: now.subtract(const Duration(hours: 48)),
        now: now,
      ),
      isTrue,
    );
  });

  test('a clock that jumped backwards does not fire early', () {
    // A device whose date is moved back leaves a "last shown" in the future.
    // The difference goes negative, which must read as not-due rather than
    // wrapping around into a paywall on every launch.
    expect(
      isPaywallDue(
        isPro: false,
        lastShownAt: now.add(const Duration(days: 30)),
        now: now,
      ),
      isFalse,
    );
  });

  test('the cooldown timestamp round-trips through preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = AppPreferences(await SharedPreferences.getInstance());

    expect(preferences.proPaywallLastShownAt, isNull);

    await preferences.setProPaywallLastShownAt(now);

    expect(preferences.proPaywallLastShownAt, now);
  });
}
