import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/features/store_screenshots/store_target.dart';

/// The spec table is the whole value of this section: a wrong number here is a
/// rejected submission, and nothing else in the app would catch it. These tests
/// pin the sizes the stores actually publish and the invariants that hold
/// across the whole table.
void main() {
  test('every target id is unique — ids are zip folder names', () {
    final ids = storeTargets.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('the required App Store sizes match Apple’s published specs', () {
    // developer.apple.com/help/app-store-connect/reference/screenshot-specifications
    expect(targetById('iphone-6-9').width, 1320);
    expect(targetById('iphone-6-9').height, 2868);
    expect(targetById('iphone-6-5').width, 1284);
    expect(targetById('iphone-6-5').height, 2778);
    expect(targetById('ipad-13').width, 2064);
    expect(targetById('ipad-13').height, 2752);
    expect(targetById('mac-1280').width, 1280);
    expect(targetById('mac-1280').height, 800);
    expect(targetById('watch-ultra-3').width, 422);
    expect(targetById('watch-ultra-3').height, 514);
  });

  test('the 11-inch iPad is 1668×2420, not the older 2388', () {
    // Apple changed this one; the old value is a common stale copy-paste.
    expect(targetById('ipad-11').height, 2420);
  });

  test('Google Play targets stay inside Play’s own bounds', () {
    final play = storeTargets.where((t) => t.store == StoreKind.googlePlay);
    expect(play, isNotEmpty);
    for (final target in play) {
      expect(
        isValidPlaySize(target.width, target.height),
        isTrue,
        reason: '${target.id} is outside 320–3840px or wider than 2:1',
      );
    }
  });

  test('Play rejects sizes outside its bounds', () {
    expect(isValidPlaySize(1080, 1920), isTrue);
    expect(isValidPlaySize(200, 400), isFalse, reason: 'below the 320 floor');
    expect(isValidPlaySize(4000, 2000), isFalse, reason: 'above the 3840 cap');
    expect(isValidPlaySize(400, 1200), isFalse, reason: 'longer than 2:1');
  });

  test('phone and tablet sizes are portrait as published', () {
    for (final target in storeTargets) {
      if (target.family.isNativeLandscape) {
        expect(
          target.width,
          greaterThan(target.height),
          reason: '${target.id} should be quoted landscape',
        );
      } else {
        expect(
          target.height,
          greaterThan(target.width),
          reason: '${target.id} should be quoted portrait',
        );
      }
    }
  });

  group('resolve()', () {
    test('swaps the axes for a landscape request', () {
      final size = targetById('iphone-6-9').resolve(landscape: true);
      expect(size.width, 2868);
      expect(size.height, 1320);
    });

    test('leaves portrait alone when portrait is asked for', () {
      final size = targetById('iphone-6-9').resolve(landscape: false);
      expect(size.width, 1320);
      expect(size.height, 2868);
    });

    test('a landscape-native Mac size is unchanged by a portrait request', () {
      // Mac/TV/Vision have one orientation; App Store Connect would reject a
      // rotated one, so the flag must not touch them.
      final size = targetById('mac-1280').resolve(landscape: false);
      expect(size.width, 1280);
      expect(size.height, 800);
    });

    test('an Apple Watch size is never rotated', () {
      final size = targetById('watch-ultra-3').resolve(landscape: true);
      expect(size.width, 422);
      expect(size.height, 514);
    });
  });

  test('the default selection is submittable and small', () {
    // Defaults should cover the two stores a normal app ships to without
    // silently queueing a TV/Vision render nobody asked for.
    expect(defaultTargetIds, contains('iphone-6-9'));
    expect(defaultTargetIds, contains('ipad-13'));
    expect(defaultTargetIds, contains('play-phone'));
    expect(defaultTargetIds, isNot(contains('appletv-1080')));
    expect(defaultTargetIds, isNot(contains('visionpro-4k')));
    for (final id in defaultTargetIds) {
      expect(targetById(id).required, isTrue);
    }
  });

  test('both stores are represented in the table', () {
    final stores = storeTargets.map((t) => t.store).toSet();
    expect(stores, containsAll(StoreKind.values));
  });

  test('families group in declaration order', () {
    final grouped = targetsByFamily();
    expect(grouped[StoreFamily.iPhone]!.first.id, 'iphone-6-9');
    expect(grouped[StoreFamily.watch], isNotEmpty);
    expect(
      grouped.values.fold<int>(0, (n, list) => n + list.length),
      storeTargets.length,
    );
  });
}
