import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillora_mobile/app/app.dart';
import 'package:stillora_mobile/core/storage/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Stillora app boots', (tester) async {
    SharedPreferences.setMockInitialValues({'stillora.onboarding.seen': true});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(AppPreferences(preferences)),
        ],
        child: const StilloraApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Stillora'), findsWidgets);
  });
}
