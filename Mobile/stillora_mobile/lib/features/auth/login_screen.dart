import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/design/stillora_colors.dart';
import '../tabs/app_tabs_screen.dart';
import 'auth_buttons.dart';
import 'widgets/login_buttons.dart';
import 'widgets/login_decorations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.nextPath});

  static const routePath = '/login';

  final String? nextPath;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// A staggered slice of the entrance timeline.
  Animation<double> _step(double start, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  );

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppTabsScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final errorMessage = _errorMessage(auth.error);

    ref.listen(authControllerProvider, (_, next) {
      if (next.asData?.value != null) {
        context.go(widget.nextPath ?? AppTabsScreen.routePath);
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff140a2b), Color(0xff0a0718), Color(0xff030309)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient brand glow behind the content.
            const LoginAmbientGlow(),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),
                        LoginReveal(
                          animation: _step(0.0, 0.5),
                          child: const LoginAnimatedLogo(),
                        ),
                        const SizedBox(height: 22),
                        LoginReveal(
                          animation: _step(0.12, 0.6),
                          child: Text(
                            'Stillora',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        LoginReveal(
                          animation: _step(0.2, 0.68),
                          child: Text(
                            context.strings.authLoginPitch,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: StilloraColors.onSurfaceVariant,
                                  height: 1.4,
                                ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        LoginReveal(
                          animation: _step(0.3, 0.78),
                          child: const LoginPrivacyNote(),
                        ),
                        const SizedBox(height: 20),
                        if (appleSignInSupported) ...[
                          LoginReveal(
                            animation: _step(0.38, 0.86),
                            child: LoginAppleButton(
                              loading: auth.isLoading,
                              onPressed: () => ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithApple(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        LoginReveal(
                          animation: _step(0.42, 0.9),
                          child: LoginGoogleButton(
                            loading: auth.isLoading,
                            onPressed: () => ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle(),
                          ),
                        ),
                        if (auth.hasError) ...[
                          const SizedBox(height: 14),
                          LoginReveal(
                            animation: _step(0.5, 1.0),
                            child: LoginErrorBanner(message: errorMessage),
                          ),
                        ],
                        const Spacer(flex: 3),
                        LoginReveal(
                          animation: _step(0.55, 1.0),
                          child: const LoginLegalLinks(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Always-visible back control.
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: LoginBackButton(onTap: _goBack),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is AuthFailure) {
      return error.message;
    }
    return context.strings.authFailed;
  }
}
