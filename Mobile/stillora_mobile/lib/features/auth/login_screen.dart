import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/widgets/stillora_mark.dart';
import '../tabs/app_tabs_screen.dart';

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
            const _AmbientGlow(),
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
                        _Reveal(
                          animation: _step(0.0, 0.5),
                          child: const _AnimatedLogo(),
                        ),
                        const SizedBox(height: 22),
                        _Reveal(
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
                        _Reveal(
                          animation: _step(0.2, 0.68),
                          child: Text(
                            'Register to convert. You can explore Stillora '
                            'before signing in.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: StilloraColors.onSurfaceVariant,
                                  height: 1.4,
                                ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _Reveal(
                          animation: _step(0.3, 0.78),
                          child: const _PrivacyNote(),
                        ),
                        const SizedBox(height: 20),
                        _Reveal(
                          animation: _step(0.42, 0.9),
                          child: _GoogleButton(
                            loading: auth.isLoading,
                            onPressed: () => ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle(),
                          ),
                        ),
                        if (auth.hasError) ...[
                          const SizedBox(height: 14),
                          _Reveal(
                            animation: _step(0.5, 1.0),
                            child: _ErrorBanner(message: errorMessage),
                          ),
                        ],
                        const Spacer(flex: 3),
                        _Reveal(
                          animation: _step(0.55, 1.0),
                          child: const _LegalLinks(),
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
                  child: _BackButton(onTap: _goBack),
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
    return 'Google sign-in failed. Please try again.';
  }
}

/// Fades and slides its child up as [animation] runs 0 -> 1.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 22), child: child),
        );
      },
      child: child,
    );
  }
}

/// Soft, slowly breathing radial glows that sit behind the login content.
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: StilloraPulse(
        duration: const Duration(milliseconds: 4200),
        builder: (context, t) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.55),
                radius: 1.1,
                colors: [
                  const Color(0xff8b5cf6).withValues(alpha: 0.20 + t * 0.10),
                  const Color(0xff22d3ee).withValues(alpha: 0.05 + t * 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The brand mark with a pulsing gradient halo behind it.
class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo();

  @override
  Widget build(BuildContext context) {
    return StilloraPulse(
      builder: (context, t) {
        return SizedBox(
          height: 120,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 104 + t * 12,
                  height: 104 + t * 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: stilloraBrandGradient,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff8b5cf6).withValues(
                          alpha: 0.28 + t * 0.28,
                        ),
                        blurRadius: 32 + t * 22,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(0xff22d3ee).withValues(
                          alpha: 0.18 + t * 0.18,
                        ),
                        blurRadius: 44 + t * 24,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xff0b0716),
                  ),
                  alignment: Alignment.center,
                  child: const StilloraMark(size: 58),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The "100% local processing" reassurance pill.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        border: Border.all(color: StilloraColors.glassStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: stilloraBrandGradient,
                borderRadius: BorderRadius.circular(StilloraRadius.xl),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: StilloraSpacing.sm),
            Expanded(
              child: Text(
                '100% local processing. Your files never leave your device.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White Google sign-in button with an animated brand glow.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return StilloraPulse(
      builder: (context, t) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            boxShadow: loading
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xffd946ef).withValues(
                        alpha: 0.22 + t * 0.22,
                      ),
                      blurRadius: 20 + t * 16,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: const Color(0xff22d3ee).withValues(
                        alpha: 0.18 + t * 0.18,
                      ),
                      blurRadius: 26 + t * 18,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            child: InkWell(
              onTap: loading ? null : onPressed,
              borderRadius: BorderRadius.circular(StilloraRadius.full),
              child: SizedBox(
                height: 54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (loading)
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xff4285f4)),
                        ),
                      )
                    else
                      const FaIcon(
                        FontAwesomeIcons.google,
                        size: 19,
                        color: Color(0xff4285f4),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      loading ? 'Signing in…' : 'Continue with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1f1f1f),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StilloraColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        border: Border.all(
          color: StilloraColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: StilloraColors.error,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StilloraColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: StilloraColors.glassStroke),
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 22),
        ),
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: StilloraColors.onSurfaceVariant,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => _open(AppConstants.termsUrl),
          child: Text('Terms', style: style),
        ),
        Text('·', style: style),
        TextButton(
          onPressed: () => _open(AppConstants.privacyUrl),
          child: Text('Privacy', style: style),
        ),
      ],
    );
  }
}
