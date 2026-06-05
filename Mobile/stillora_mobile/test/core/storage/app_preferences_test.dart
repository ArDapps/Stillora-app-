import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillora_mobile/core/storage/app_preferences.dart';

void main() {
  test('onboarding completion state persists locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = AppPreferences(await SharedPreferences.getInstance());

    expect(preferences.isOnboardingComplete, isFalse);

    await preferences.setOnboardingComplete(true);

    expect(preferences.isOnboardingComplete, isTrue);
  });
}
