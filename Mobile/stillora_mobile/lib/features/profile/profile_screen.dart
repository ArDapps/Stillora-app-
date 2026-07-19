import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/stillora_mark.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const routePath = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Info')),
      body: const ProfileView(),
    );
  }
}

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ProfileFrame(
      child: ListView(
        padding: const EdgeInsets.all(StilloraSpacing.md),
        children: [
          const SizedBox(height: StilloraSpacing.md),
          const Center(child: StilloraMark(size: 64)),
          const SizedBox(height: StilloraSpacing.sm),
          Text(
            'Stillora',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'No account needed — every video is made locally on your device.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: StilloraSpacing.lg),
          const _PolicyLinks(),
          const SizedBox(height: 16),
          const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
        ],
      ),
    );
  }
}

/// Centers the profile content and caps its width so it reads as a tidy panel
/// on wide desktop windows instead of a stretched mobile column.
class _ProfileFrame extends StatelessWidget {
  const _ProfileFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: child,
        ),
      ),
    );
  }
}

class ProfileSettingsButton extends StatelessWidget {
  const ProfileSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_rounded),
      onPressed: () => context.push('/settings'),
    );
  }
}

class _PolicyLinks extends StatelessWidget {
  const _PolicyLinks();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ListTile(
          leading: Icon(Icons.privacy_tip_rounded),
          title: Text('Privacy Policy'),
          subtitle: Text(AppConstants.privacyUrl),
        ),
        ListTile(
          leading: Icon(Icons.description_rounded),
          title: Text('Terms of Service'),
          subtitle: Text(AppConstants.termsUrl),
        ),
      ],
    );
  }
}
