import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/pro/pro_controller.dart';
import '../../../core/pro/pro_gate.dart';

/// What the lifetime unlock actually buys, plus the line that is true on both
/// tiers (local processing, no cloud upload) so nobody reads privacy as a paid
/// feature.
///
/// The trailing flag is what earns a PRO tag. It is deliberately false on
/// [AppStrings.proLocalBoth]: badging that row would advertise privacy as
/// something you have to pay for, which is the opposite of what it says.
List<(IconData, String, String, bool)> _highlights(AppStrings s) => [
  (Icons.hd_rounded, s.proHiRes, s.proHiResBody, true),
  (Icons.tune_rounded, s.proAdvTools, s.proAdvToolsBody, true),
  (Icons.layers_rounded, s.proBatch, s.proBatchBody, true),
  (Icons.auto_awesome_rounded, s.proPresets, s.proPresetsBody, true),
  (Icons.block_rounded, s.proNoAds, s.proNoAdsBody, true),
  (Icons.shield_rounded, s.proLocalBoth, s.proLocalBothBody, false),
];

class ProHighlights extends ConsumerWidget {
  const ProHighlights({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Once the unlock is owned every row is included, so the tags stop being
    // information and become decoration.
    final isPro = ref.watch(isProProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (icon, title, detail, proOnly) in _highlights(
          context.strings,
        ))
          Padding(
            padding: const EdgeInsets.only(bottom: StilloraSpacing.snug),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: StilloraColors.brandCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(StilloraRadius.sm),
                  ),
                  child: Icon(icon, size: 18, color: StilloraColors.brandCyan),
                ),
                const SizedBox(width: StilloraSpacing.snug),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (proOnly && !isPro) ...[
                            const SizedBox(width: StilloraSpacing.base + 2),
                            const ProBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: StilloraColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
