import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/pro/pro_config.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_gate.dart';
import '../../core/widgets/desktop_shell.dart';
import 'widgets/pro_comparison_table.dart';
import 'widgets/pro_highlights.dart';

/// Route wrapper for the contextual paywall. Every gated control pushes this,
/// passing the [ProFeature] that triggered it as `extra` so the page can open
/// with a line explaining why the user landed here.
class ProScreen extends ConsumerWidget {
  const ProScreen({super.key, this.reason = ProFeature.proMenu});

  static const routePath = ProLimits.proRoutePath;

  final ProFeature reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SidebarScaffold(
      desktopTitle: context.strings.stilloraPro,
      appBar: AppBar(title: Text(context.strings.stilloraPro)),
      body: ProView(reason: reason),
    );
  }
}

/// The Stillora Pro page — also a home tab, reached from the ACCOUNT / APP
/// group at the bottom of the navigation.
///
/// Deliberately not a launch interstitial: it is only ever reached by choosing
/// it, or by tapping a clearly-badged Pro option. The app itself is never
/// blocked behind it.
class ProView extends ConsumerStatefulWidget {
  const ProView({super.key, this.reason = ProFeature.proMenu});

  final ProFeature reason;

  @override
  ConsumerState<ProView> createState() => _ProViewState();
}

class _ProViewState extends ConsumerState<ProView> {
  @override
  void initState() {
    super.initState();
    // Pick up a remotely-changed price whenever the paywall is opened. Fails
    // soft: on error the cached/build-time price stays on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proConfigProvider.notifier).refresh();
    });
  }

  void _showResult(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    ref.read(proControllerProvider.notifier).clearMessage();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proControllerProvider, (previous, next) {
      final message = next.message;
      if (message != null && message != previous?.message) {
        _showResult(message);
      }
    });

    final status = ref.watch(proControllerProvider);
    final config = ref.watch(proConfigProvider);

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              StilloraSpacing.sm,
              StilloraSpacing.sm,
              StilloraSpacing.sm,
              StilloraSpacing.lg,
            ),
            children: [
              _ProHeader(isPro: status.isPro, reason: widget.reason),
              const SizedBox(height: StilloraSpacing.md),
              const ProHighlights(),
              const SizedBox(height: StilloraSpacing.md),
              _PurchaseBlock(
                status: status,
                config: config,
                onPurchase: () =>
                    ref.read(proControllerProvider.notifier).purchaseLifetime(),
                onRestore: () =>
                    ref.read(proControllerProvider.notifier).restorePurchases(),
              ),
              const SizedBox(height: StilloraSpacing.md),
              const ProComparisonTable(),
              const SizedBox(height: StilloraSpacing.md),
              const _PrivacyNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProHeader extends StatelessWidget {
  const _ProHeader({required this.isPro, required this.reason});

  final bool isPro;
  final ProFeature reason;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StilloraColors.brandMagenta.withValues(alpha: 0.18),
            StilloraColors.brandCyan.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(StilloraRadius.card),
        border: Border.all(color: StilloraColors.glassStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: StilloraColors.brandCyan,
                size: 28,
              ),
              const SizedBox(width: StilloraSpacing.xs),
              Expanded(
                child: Text(
                  'Stillora Pro',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (isPro)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StilloraSpacing.snug,
                    vertical: StilloraSpacing.base + 2,
                  ),
                  decoration: BoxDecoration(
                    color: StilloraColors.secondary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(StilloraRadius.pill),
                  ),
                  child: Text(
                    context.strings.proActive,
                    style: text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: StilloraColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.snug),
          Text(
            context.strings.proTagline,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: StilloraSpacing.base + 2),
          Text(
            isPro ? context.strings.proPaidOnce : context.strings.proPayOnce,
            style: text.bodyMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
          // Why the paywall opened, when it opened by itself.
          if (!isPro && reason.reason(context.strings).isNotEmpty) ...[
            const SizedBox(height: StilloraSpacing.snug),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_open_rounded,
                  size: 16,
                  color: StilloraColors.brandCyan,
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: Text(
                    reason.reason(context.strings),
                    style: text.bodySmall?.copyWith(
                      color: StilloraColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PurchaseBlock extends StatelessWidget {
  const _PurchaseBlock({
    required this.status,
    required this.config,
    required this.onPurchase,
    required this.onRestore,
  });

  final ProStatus status;
  final ProConfig config;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (status.isPro) {
      return Container(
        padding: const EdgeInsets.all(StilloraSpacing.sm),
        decoration: BoxDecoration(
          color: StilloraColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(StilloraRadius.card),
          border: Border.all(
            color: StilloraColors.secondary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: StilloraColors.secondary),
            const SizedBox(width: StilloraSpacing.snug),
            Expanded(
              child: Text(
                context.strings.proUnlockedBody,
                style: text.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The app's own primary button — brand gradient, white label, magenta +
        // cyan glow — so the paywall's main action matches every other export
        // button instead of introducing a second button language.
        StilloraPrimaryButton(
          onPressed: status.busy ? null : onPurchase,
          icon: Icons.workspace_premium_rounded,
          label: status.busy
              ? context.strings.proContacting
              : '${context.strings.proUnlockCta} — ${config.priceLabel}',
        ),
        if (status.busy) ...[
          const SizedBox(height: StilloraSpacing.snug),
          const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
        const SizedBox(height: StilloraSpacing.xs),
        TextButton(
          onPressed: status.busy ? null : onRestore,
          child: Text(context.strings.proRestore),
        ),
        const SizedBox(height: StilloraSpacing.base),
        Text(
          context.strings.proOneTime,
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(
            color: StilloraColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Says out loud what Pro is *not*: privacy is not the product. Local
/// processing, no cloud upload and watermark-free exports are the Free tier's
/// behaviour too, and stay that way.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.sm),
      decoration: BoxDecoration(
        color: StilloraColors.surfaceContainer,
        borderRadius: BorderRadius.circular(StilloraRadius.card),
        border: Border.all(color: StilloraColors.panelBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: StilloraColors.secondary, size: 20),
          const SizedBox(width: StilloraSpacing.snug),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.strings.filesStayOnDevice,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: StilloraSpacing.base + 2),
                Text(
                  context.strings.proPrivacyBody,
                  style: text.bodySmall?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
