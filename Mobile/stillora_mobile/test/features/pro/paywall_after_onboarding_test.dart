import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillora_mobile/app/app.dart';
import 'package:stillora_mobile/core/auth/auth_repository.dart';
import 'package:stillora_mobile/core/auth/session.dart';
import 'package:stillora_mobile/core/pro/pro_store.dart';
import 'package:stillora_mobile/core/storage/app_preferences.dart';
import 'package:stillora_mobile/features/pro/paywall_scheduler.dart';

/// The automatic paywall is wired through the real router, so the thing worth
/// testing is the wiring, not the widget: does finishing onboarding actually
/// land a dismissible paywall on top of the app, and does the 48-hour clock
/// start ticking from that moment.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Settling into the Create tab mounts Gallery, which opens a Hive box. In a
  // widget test there is no app-documents directory to open it in.
  late Directory hiveDir;
  setUp(() {
    hiveDir = Directory.systemTemp.createTempSync('stillora_paywall_test');
    Hive.init(hiveDir.path);
  });
  tearDown(() async {
    await Hive.close();
    hiveDir.deleteSync(recursive: true);
  });

  /// The brand glow animates forever, so `pumpAndSettle` never returns — every
  /// wait here is a fixed number of frames, as in the integration tests.
  Future<void> settle(WidgetTester tester, [int frames = 10]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<AppPreferences> pumpApp(
    WidgetTester tester, {
    required Map<String, Object> prefs,
    bool pro = false,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final preferences = AppPreferences(await SharedPreferences.getInstance());
    final store = InMemoryProStore();
    if (pro) await store.setPro(true);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(preferences),
            proStoreProvider.overrideWithValue(store),
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const StilloraApp(),
        ),
      );
      // Real time, not pumped frames: the launch paywall's delay is a real
      // timer started inside this zone, so fake-time pumps afterwards would
      // never fire it. Also lets the remote price refresh settle, so no timer
      // is left pending at teardown.
      await Future<void>.delayed(const Duration(milliseconds: 900));
    });
    await settle(tester, 20);
    return preferences;
  }

  testWidgets('finishing onboarding opens the paywall', (tester) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final preferences = await pumpApp(
      tester,
      prefs: {'stillora.onboarding.seen': false},
    );

    expect(find.text('Skip'), findsOneWidget);
    expect(preferences.proPaywallLastShownAt, isNull);

    await tester.tap(find.text('Skip'));
    await settle(tester, 20);

    expect(
      find.text('Unlock the full power of your private media toolkit.'),
      findsOneWidget,
    );
    // Pushed, not replaced: the free app is still underneath.
    expect(find.byType(BackButton), findsWidgets);
    // The 48-hour clock starts here, so the next reminder is two days out
    // rather than on the next launch.
    expect(preferences.proPaywallLastShownAt, isNotNull);
  });

  testWidgets('a returning Free user inside the window is left alone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpApp(
      tester,
      prefs: {
        'stillora.onboarding.seen': true,
        'stillora.pro.paywallLastShownMs': DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
      },
    );

    expect(
      find.text('Unlock the full power of your private media toolkit.'),
      findsNothing,
    );
  });

  testWidgets('a returning Free user past the window gets the reminder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpApp(
      tester,
      prefs: {
        'stillora.onboarding.seen': true,
        'stillora.pro.paywallLastShownMs': DateTime.now()
            .subtract(proPaywallInterval + const Duration(minutes: 1))
            .millisecondsSinceEpoch,
      },
    );

    expect(
      find.text('Unlock the full power of your private media toolkit.'),
      findsOneWidget,
    );
  });

  testWidgets('a Pro owner is never interrupted, however long it has been', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final preferences = await pumpApp(
      tester,
      pro: true,
      prefs: {
        'stillora.onboarding.seen': true,
        'stillora.pro.paywallLastShownMs': DateTime.now()
            .subtract(const Duration(days: 365))
            .millisecondsSinceEpoch,
      },
    );

    expect(
      find.text('Unlock the full power of your private media toolkit.'),
      findsNothing,
    );
    // And the cooldown was not re-stamped, because nothing was shown.
    expect(
      DateTime.now().difference(preferences.proPaywallLastShownAt!),
      greaterThan(const Duration(days: 300)),
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> signInWithGoogle() {
    throw const AuthFailure('Google sign-in is not available in widget tests.');
  }

  @override
  Future<AuthSession> signInWithApple() {
    throw const AuthFailure('Apple sign-in is not available in widget tests.');
  }

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signOut() async {}
}
