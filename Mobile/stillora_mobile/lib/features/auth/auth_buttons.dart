import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/design/stillora_colors.dart';

/// Whether Sign in with Apple should be offered on this platform. Apple requires
/// the button on its own platforms; we also surface it on Android via the web
/// flow so a user who created an Apple account can still get back in.
bool get appleSignInSupported =>
    Platform.isIOS || Platform.isMacOS || Platform.isAndroid;

String authErrorMessage(Object? error) {
  if (error is AuthFailure) {
    return error.message;
  }
  return 'Sign-in failed. Please try again.';
}

/// Prominent black "Continue with Apple" button. Per Apple's Human Interface
/// Guidelines it is at least as visible as other sign-in options and uses the
/// approved label and Apple logo.
class StilloraAppleButton extends StatelessWidget {
  const StilloraAppleButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue with Apple',
      enabled: !loading,
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
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
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                else
                  const FaIcon(
                    FontAwesomeIcons.apple,
                    size: 22,
                    color: Colors.white,
                  ),
                const SizedBox(width: 12),
                Text(
                  loading ? 'Signing in…' : 'Continue with Apple',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White "Continue with Google" button matching the Apple button's footprint.
class StilloraGoogleButton extends StatelessWidget {
  const StilloraGoogleButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue with Google',
      enabled: !loading,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
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
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StilloraColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StilloraColors.error.withValues(alpha: 0.4)),
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
