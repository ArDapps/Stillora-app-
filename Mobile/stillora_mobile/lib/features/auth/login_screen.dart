import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/stillora_mark.dart';
import '../tabs/app_tabs_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key, this.nextPath});

  static const routePath = '/login';

  final String? nextPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final errorMessage = _errorMessage(auth.error);

    ref.listen(authControllerProvider, (_, next) {
      if (next.asData?.value != null) {
        context.go(nextPath ?? AppTabsScreen.routePath);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (context.canPop() || nextPath != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppTabsScreen.routePath);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Back',
                  ),
                ),
              const Spacer(),
              const Center(child: StilloraMark(size: 74)),
              const SizedBox(height: 18),
              Text(
                'Stillora',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Register to convert. You can explore Stillora before signing in.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '100% local processing. Your files never leave your device.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: auth.isLoading
                    ? null
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle(),
                icon: auth.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const FaIcon(FontAwesomeIcons.google, size: 18),
                label: const Text('Continue with Google'),
              ),
              if (auth.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: const [
                  Text(AppConstants.termsUrl),
                  Text(AppConstants.privacyUrl),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is AuthFailure) {
      return error.message;
    }
    return 'Google sign-in failed. Please try again.';
  }
}
