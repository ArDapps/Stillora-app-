import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/design/stillora_spacing.dart';

/// What the lifetime unlock actually buys, plus the two lines that are true on
/// both tiers (local processing, no cloud upload) so nobody reads privacy as a
/// paid feature.
List<(IconData, String, String)> _highlights(AppStrings s) => [
  (Icons.hd_rounded, s.proHiRes, s.proHiResBody),
  (Icons.tune_rounded, s.proAdvTools, s.proAdvToolsBody),
  (Icons.layers_rounded, s.proBatch, s.proBatchBody),
  (Icons.auto_awesome_rounded, s.proPresets, s.proPresetsBody),
  (Icons.block_rounded, s.proNoAds, s.proNoAdsBody),
  (Icons.shield_rounded, s.proLocalBoth, s.proLocalBothBody),
];

class ProHighlights extends StatelessWidget {
  const ProHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (icon, title, detail) in _highlights(context.strings))
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
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
