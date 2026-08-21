import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/core/pro/pro_gate.dart';
import 'package:stillora_mobile/core/pro/pro_store.dart';
import 'package:stillora_mobile/features/pro/pro_screen.dart';

/// The upgrade page has to sell the lifetime unlock without ever implying that
/// privacy or basic access is the thing being sold.
void main() {
  Widget harness({bool pro = false, ProFeature reason = ProFeature.proMenu}) {
    final store = InMemoryProStore();
    if (pro) store.setPro(true);
    return ProviderScope(
      overrides: [proStoreProvider.overrideWithValue(store)],
      child: MaterialApp(home: Scaffold(body: ProView(reason: reason))),
    );
  }

  testWidgets('sells a one-time purchase, never a subscription', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // runAsync lets the remote price refresh settle so no timer is left
    // pending at teardown.
    await tester.runAsync(() => tester.pumpWidget(harness()));
    await tester.pump();

    expect(find.text('Stillora Pro'), findsOneWidget);
    expect(
      find.text('Unlock the full power of your private media toolkit.'),
      findsOneWidget,
    );
    expect(find.text('Pay once. Use forever.'), findsOneWidget);
    expect(find.text(r'Unlock Lifetime Pro — $19.99'), findsOneWidget);
    expect(find.text('Restore Purchase'), findsOneWidget);
    expect(find.text('One-time purchase. No subscription.'), findsOneWidget);

    // The comparison makes the shared-vs-paid split explicit.
    expect(find.text('Local Processing'), findsOneWidget);
    expect(find.text('No Stillora Watermark'), findsOneWidget);
    expect(find.text('720p Export'), findsOneWidget);
    expect(find.text('2K / 4K Export'), findsOneWidget);
    expect(find.text('Files stay on this device.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a contextual open explains why the paywall appeared', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // runAsync lets the remote price refresh settle so no timer is left
    // pending at teardown.
    await tester.runAsync(
      () => tester.pumpWidget(harness(reason: ProFeature.higherResolution)),
    );
    await tester.pump();

    expect(
      find.text('Exports above 720p are part of Stillora Pro.'),
      findsOneWidget,
    );
  });

  testWidgets('an owner sees Pro as active, with nothing left to buy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // runAsync lets the remote price refresh settle so no timer is left
    // pending at teardown.
    await tester.runAsync(() => tester.pumpWidget(harness(pro: true)));
    await tester.pump();

    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text(r'Unlock Lifetime Pro — $19.99'), findsNothing);
    expect(find.text('Restore Purchase'), findsNothing);
  });
}
