import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_glow.dart';
import '../../../core/design/stillora_spacing.dart';
import '../auth_buttons.dart';

/// Black "Continue with Apple" button with the same animated brand glow as the
/// Google button so both options read as equally prominent.
class LoginAppleButton extends StatelessWidget {
  const LoginAppleButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return StilloraPulse(
      builder: (context, t) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: loading
                ? null
                : [
                    BoxShadow(
                      color: StilloraColors.accent.withValues(
                        alpha: 0.20 + t * 0.20,
                      ),
                      blurRadius: 20 + t * 16,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: StilloraColors.brandCyan.withValues(
                        alpha: 0.16 + t * 0.16,
                      ),
                      blurRadius: 26 + t * 18,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: StilloraAppleButton(loading: loading, onPressed: onPressed),
        );
      },
    );
  }
}

/// White Google sign-in button with an animated brand glow.
class LoginGoogleButton extends StatelessWidget {
  const LoginGoogleButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

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
                      color: StilloraColors.brandMagenta.withValues(
                        alpha: 0.22 + t * 0.22,
                      ),
                      blurRadius: 20 + t * 16,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: StilloraColors.brandCyan.withValues(
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

class LoginErrorBanner extends StatelessWidget {
  const LoginErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StilloraColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        border: Border.all(color: StilloraColors.error.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: StilloraColors.error,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: StilloraColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
