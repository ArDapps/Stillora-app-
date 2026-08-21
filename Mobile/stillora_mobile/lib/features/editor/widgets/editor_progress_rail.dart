import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_glow.dart';
import '../../../core/design/stillora_spacing.dart';

class ProgressRail extends StatelessWidget {
  const ProgressRail({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ProgressStep(
          index: '1',
          label: context.strings.edUpload,
          color: StilloraColors.brandMagenta,
          compact: compact,
        ),
        _ProgressLine(compact: compact),
        _ProgressStep(
          index: '2',
          label: context.strings.edAudio,
          color: StilloraColors.accent,
          compact: compact,
        ),
        _ProgressLine(compact: compact),
        _ProgressStep(
          index: '3',
          label: context.strings.edExport,
          color: StilloraColors.brandCyan,
          compact: compact,
        ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.index,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String index;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 40.0;
    return Column(
      children: [
        StilloraPulse(
          builder: (context, t) {
            return Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4 + t * 0.4),
                    blurRadius: 8 + t * 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                index,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
        if (!compact) ...[
          const SizedBox(height: StilloraSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 26 : 42,
      height: 2,
      margin: EdgeInsets.only(
        bottom: compact ? 0 : 24,
        left: compact ? 6 : 8,
        right: compact ? 6 : 8,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x99d946ef), Color(0x9922d3ee)],
        ),
      ),
    );
  }
}
