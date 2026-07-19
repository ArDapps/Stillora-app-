import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/core/widgets/start_over_button.dart';

void main() {
  // "Start over" wipes the user's work, so it must never fire on a stray click:
  // it confirms first, and does nothing if the dialog is cancelled.

  Future<void> pump(
    WidgetTester tester, {
    required VoidCallback onReset,
    bool enabled = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartOverButton(onReset: onReset, enabled: enabled),
        ),
      ),
    );
  }

  testWidgets('resets only after the confirmation is accepted', (tester) async {
    var resets = 0;
    await pump(tester, onReset: () => resets++);

    await tester.tap(find.text('Start over'));
    await tester.pumpAndSettle();

    // Dialog is up; nothing reset yet.
    expect(find.text('Start over?'), findsOneWidget);
    expect(resets, 0);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(resets, 1);
  });

  testWidgets('cancelling the confirmation leaves the inputs alone', (
    tester,
  ) async {
    var resets = 0;
    await pump(tester, onReset: () => resets++);

    await tester.tap(find.text('Start over'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(resets, 0);
    expect(find.text('Start over?'), findsNothing);
  });

  testWidgets('is disabled when there is nothing to reset', (tester) async {
    var resets = 0;
    await pump(tester, onReset: () => resets++, enabled: false);

    await tester.tap(find.text('Start over'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Start over?'), findsNothing);
    expect(resets, 0);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
  });
}
