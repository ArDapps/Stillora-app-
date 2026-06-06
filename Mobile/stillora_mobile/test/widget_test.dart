import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillora_mobile/app/app.dart';
import 'package:stillora_mobile/core/auth/auth_repository.dart';
import 'package:stillora_mobile/core/auth/session.dart';
import 'package:stillora_mobile/core/storage/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Stillora app boots', (tester) async {
    SharedPreferences.setMockInitialValues({'stillora.onboarding.seen': false});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(AppPreferences(preferences)),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const StilloraApp(),
      ),
    );
    expect(find.text('Stillora'), findsWidgets);
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
  Future<void> signOut() async {}
}
