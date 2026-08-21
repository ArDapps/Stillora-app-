import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/stillora_mark.dart';

/// Brand mark, tagline and sponsor slot. This is what used to be the standalone
/// "Info" tab; it now lives inside the About section of Settings.
class AboutStilloraBlock extends StatelessWidget {
  const AboutStilloraBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StilloraSpacing.sm),
      child: Column(
        children: [
          const SizedBox(height: StilloraSpacing.sm),
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
            context.strings.appTagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: StilloraSpacing.md),
          const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
          const SizedBox(height: StilloraSpacing.sm),
        ],
      ),
    );
  }
}

/// Standalone `/profile` route. Settings is the primary home for this content;
/// this keeps the existing deep link working.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const routePath = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.about)),
      body: const ProfileView(),
    );
  }
}

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(StilloraSpacing.sm),
            children: [
              const AboutStilloraBlock(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_rounded),
                title: Text(strings.privacyPolicy),
                subtitle: const Text(AppConstants.privacyUrl),
              ),
              ListTile(
                leading: const Icon(Icons.description_rounded),
                title: Text(strings.termsOfService),
                subtitle: const Text(AppConstants.termsUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
