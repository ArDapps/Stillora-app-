import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../i18n/app_strings.dart';
import '../../features/editor/video_preset.dart';
import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';
import 'pro_controller.dart';

/// Where the Free tier stops.
///
/// Free is a genuinely complete toolkit: every section, every core operation,
/// local processing, and exports with no Stillora watermark. What Pro buys is
/// *more power* — sharper output, finer control, batch runs, no ads — never
/// access to the user's own files and never privacy.
class ProLimits {
  const ProLimits._();

  /// Highest export tier a Free user can pick. 1080p / 2K / 4K are Pro.
  static const freeExportQuality = ExportQuality.hd720;

  /// Route of the upgrade page. Kept here so gate call-sites don't have to
  /// import the feature layer.
  static const proRoutePath = '/pro';
}

extension ProExportQuality on ExportQuality {
  /// True for tiers above the Free ceiling (1080p, 2K, 4K).
  bool get requiresPro => shortSide > ProLimits.freeExportQuality.shortSide;
}

/// Why the paywall opened. Only used to pick the line of copy at the top of the
/// Pro page, so the upsell explains itself instead of appearing out of nowhere.
enum ProFeature {
  higherResolution,
  advancedControls,
  batchProcessing,
  premiumPresets,
  removeAds,
  afterOnboarding,
  scheduledReminder,
  proMenu;

  String reason(AppStrings s) => switch (this) {
    ProFeature.higherResolution => s.proGate720p,
    ProFeature.advancedControls => s.proGateAdvanced,
    ProFeature.batchProcessing => s.proGateBatch,
    ProFeature.premiumPresets => s.proGatePresets,
    ProFeature.removeAds => s.proGateAds,
    ProFeature.afterOnboarding => s.proGateOnboarding,
    ProFeature.scheduledReminder => s.proGateReminder,
    ProFeature.proMenu => '',
  };
}

/// Opens the upgrade page. Contextual paywalls push (so the user lands back
/// where they were on dismiss) rather than replacing the current section.
void openProUpgrade(
  BuildContext context, {
  ProFeature reason = ProFeature.proMenu,
}) {
  context.push(ProLimits.proRoutePath, extra: reason);
}

/// The one call every Pro-gated control makes.
///
/// Returns true when the user may proceed. Otherwise it opens the paywall,
/// explains why, and returns false — the caller simply does nothing else. Pro
/// options are never hidden, so the user always sees what the upgrade buys.
bool ensurePro(
  BuildContext context,
  WidgetRef ref,
  ProFeature feature, {
  bool required = true,
}) {
  if (!required) return true;
  if (ref.read(isProProvider)) return true;
  openProUpgrade(context, reason: feature);
  return false;
}

/// The small "PRO" chip shown next to any paid option. Subtle premium accent
/// (brand magenta → cyan), sized to sit inline with a label.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.compact = false});

  /// Drops the padding for tight rows like segmented-control chips.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [StilloraColors.brandMagenta, StilloraColors.brandCyan],
        ),
        borderRadius: BorderRadius.circular(StilloraRadius.pill),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          fontSize: compact ? 8 : 9,
          height: 1.2,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// A label with a trailing [ProBadge] when [locked]. Used for menu rows,
/// resolution chips and any other paid option that stays visible to Free users.
class ProLabel extends StatelessWidget {
  const ProLabel(
    this.label, {
    super.key,
    required this.locked,
    this.style,
    this.compact = false,
  });

  final String label;
  final bool locked;
  final TextStyle? style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!locked) return Text(label, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(label, style: style, overflow: TextOverflow.ellipsis),
        ),
        SizedBox(width: compact ? 4 : StilloraSpacing.base + 2),
        ProBadge(compact: compact),
      ],
    );
  }
}

/// Clamps a chosen tier to what the current entitlement actually allows.
///
/// The pickers already gate selection and correct a stale Pro tier on sight,
/// but a section can be exported without its picker ever being built (the phone
/// Create flow can skip the preset step, and a saved session restores whatever
/// tier it was saved with). Calling this at the export call-site makes the
/// entitlement true of the *output*, not just of the UI.
///
/// `null` means "Original size" and is never clamped: re-exporting a video at
/// the size it already was is basic access to the user's own file.
ExportQuality? entitledQuality(Ref ref, ExportQuality? quality) {
  if (quality == null || ref.read(isProProvider) || !quality.requiresPro) {
    return quality;
  }
  return ProLimits.freeExportQuality;
}

/// Wraps an advanced, Pro-only control.
///
/// For Pro users this is a pass-through. For Free users the control stays fully
/// **visible** — dimmed, inert, and tapping anywhere on it opens the paywall —
/// so it advertises what the upgrade buys instead of vanishing. Only use this
/// on genuine power controls; the section's core operation must keep working
/// without it.
class ProLockedControl extends ConsumerWidget {
  const ProLockedControl({
    super.key,
    required this.child,
    this.feature = ProFeature.advancedControls,
  });

  final Widget child;
  final ProFeature feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isProProvider)) return child;
    return Semantics(
      button: true,
      label: context.strings.proFeatureLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openProUpgrade(context, reason: feature),
        child: Opacity(opacity: 0.55, child: IgnorePointer(child: child)),
      ),
    );
  }
}

/// A control heading that carries a PRO badge for Free users, e.g. the
/// "Sensitivity" label above Remove Silence's threshold slider.
class ProControlLabel extends ConsumerWidget {
  const ProControlLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProLabel(
      label,
      locked: !ref.watch(isProProvider),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}
