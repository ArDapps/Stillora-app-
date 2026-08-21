import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import 'auth_buttons.dart';

/// Shows the "Unlock Voice Narration" registration modal. Returns `true` when the
/// user signed in and tapped "Start Recording", so the caller can open the
/// recorder immediately. Returns `false`/`null` when dismissed.
Future<bool?> showRegistrationSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: StilloraColors.surfaceContainerLow,
    showDragHandle: true,
    builder: (_) => const RegistrationSheet(),
  );
}

class RegistrationSheet extends ConsumerStatefulWidget {
  const RegistrationSheet({super.key});

  @override
  ConsumerState<RegistrationSheet> createState() => _RegistrationSheetState();
}

class _RegistrationSheetState extends ConsumerState<RegistrationSheet> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final signedIn = auth.asData?.value != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        StilloraSpacing.md,
        StilloraSpacing.xs,
        StilloraSpacing.md,
        StilloraSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: signedIn
            ? _unlockedContent(context)
            : _lockedContent(context, auth),
      ),
    );
  }

  List<Widget> _lockedContent(BuildContext context, AsyncValue auth) {
    final loading = auth.isLoading;
    return [
      _Header(
        icon: Icons.mic_rounded,
        title: context.strings.authUnlockNarration,
        subtitle: context.strings.authUnlockNarrationBody,
      ),
      const SizedBox(height: StilloraSpacing.md),
      if (appleSignInSupported) ...[
        StilloraAppleButton(
          loading: loading,
          onPressed: () =>
              ref.read(authControllerProvider.notifier).signInWithApple(),
        ),
        const SizedBox(height: StilloraSpacing.sm),
      ],
      StilloraGoogleButton(
        loading: loading,
        onPressed: () =>
            ref.read(authControllerProvider.notifier).signInWithGoogle(),
      ),
      if (auth.hasError) ...[
        const SizedBox(height: StilloraSpacing.sm),
        AuthErrorBanner(message: authErrorMessage(context.strings, auth.error)),
      ],
      const SizedBox(height: StilloraSpacing.xs),
      TextButton(
        onPressed: loading ? null : () => Navigator.of(context).pop(false),
        child: Text(context.strings.authNotNow),
      ),
    ];
  }

  List<Widget> _unlockedContent(BuildContext context) {
    return [
      _Header(
        icon: Icons.check_circle_rounded,
        title: context.strings.authNarrationUnlocked,
        subtitle: context.strings.authNarrationUnlockedBody,
      ),
      const SizedBox(height: StilloraSpacing.md),
      FilledButton.icon(
        onPressed: () => Navigator.of(context).pop(true),
        icon: const Icon(Icons.mic_rounded),
        label: Text(context.strings.authStartRecording),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: stilloraBrandGradient,
            borderRadius: BorderRadius.circular(StilloraRadius.xl),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: StilloraSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: StilloraColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
