import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillora_mobile/core/storage/app_preferences.dart';

void main() {
  test('default video duration persists locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = AppPreferences(await SharedPreferences.getInstance());

    expect(preferences.defaultDurationSeconds, 10);

    await preferences.setDefaultDurationSeconds(30);

    expect(preferences.defaultDurationSeconds, 30);
  });

  test('first-export rating flag defaults to false and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = AppPreferences(await SharedPreferences.getInstance());

    expect(preferences.hasRequestedRatingAfterFirstExport, isFalse);

    await preferences.setHasRequestedRatingAfterFirstExport(true);

    expect(preferences.hasRequestedRatingAfterFirstExport, isTrue);
  });
}
