import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_glow.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/widgets/stillora_mark.dart';

/// Fades and slides its child up as [animation] runs 0 -> 1.
class LoginReveal extends StatelessWidget {
  const LoginReveal({super.key, required this.animation, required this.child});

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
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 22),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Soft, slowly breathing radial glows that sit behind the login content.
class LoginAmbientGlow extends StatelessWidget {
  const LoginAmbientGlow({super.key});

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
                  StilloraColors.accent.withValues(alpha: 0.20 + t * 0.10),
                  StilloraColors.brandCyan.withValues(alpha: 0.05 + t * 0.04),
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
class LoginAnimatedLogo extends StatelessWidget {
  const LoginAnimatedLogo({super.key});

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
                        color: StilloraColors.accent.withValues(
                          alpha: 0.28 + t * 0.28,
                        ),
                        blurRadius: 32 + t * 22,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: StilloraColors.brandCyan.withValues(
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: StilloraColors.surface,
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
class LoginPrivacyNote extends StatelessWidget {
  const LoginPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StilloraColors.onSurface.withValues(alpha: 0.04),
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

class LoginBackButton extends StatelessWidget {
  const LoginBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StilloraColors.onSurface.withValues(alpha: 0.06),
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

class LoginLegalLinks extends StatelessWidget {
  const LoginLegalLinks({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: StilloraColors.onSurfaceVariant);
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
