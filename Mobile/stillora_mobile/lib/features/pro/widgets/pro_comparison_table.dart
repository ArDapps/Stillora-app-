import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/i18n/app_strings.dart';

/// One row of the Free vs Pro table. A null cell renders the muted em dash.
typedef _Row = (String feature, String? free, String? pro);

/// Free vs Pro Lifetime, in the order that makes the deal obvious: everything
/// shared sits at the top, so the paid rows below read as *more power* rather
/// than as access being taken away.
List<_Row> _buildRows(AppStrings s) => [
  (s.proRowLocal, '✓', '✓'),
  (s.proRowFilesStay, '✓', '✓'),
  (s.proRowBasicTools, '✓', '✓'),
  (s.proRowNoWatermark, '✓', '✓'),
  ('720p ${s.proRowExport}', '✓', '✓'),
  ('1080p ${s.proRowExport}', null, '✓'),
  ('2K / 4K ${s.proRowExport}', null, '✓'),
  (s.proRowAdvanced, s.proLimited, '✓'),
  (s.proRowBatch, null, '✓'),
  (s.proRowPresets, null, '✓'),
  (s.proRowAds, s.proYes, s.proNo),
  (s.proRowLifetime, s.proFreeTier, '✓'),
];

class ProComparisonTable extends StatelessWidget {
  const ProComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = _buildRows(context.strings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.strings.proCompareTitle,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: StilloraColors.surfaceContainer,
            borderRadius: BorderRadius.circular(StilloraRadius.card),
            border: Border.all(color: StilloraColors.panelBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _HeaderRow(),
              for (var i = 0; i < rows.length; i++)
                _FeatureRow(row: rows[i], striped: i.isOdd),
            ],
          ),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          context.strings.proCompareFooter,
          style: text.bodySmall?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.6,
    );
    return Container(
      color: StilloraColors.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(
        horizontal: StilloraSpacing.snug,
        vertical: StilloraSpacing.xs + 2,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(context.strings.proCompareFeature, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(
              context.strings.proCompareFree,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              context.strings.proComparePro,
              textAlign: TextAlign.center,
              style: style?.copyWith(color: StilloraColors.brandCyan),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.row, required this.striped});

  final _Row row;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    final (feature, free, pro) = row;
    return Container(
      color: striped
          ? StilloraColors.onSurface.withValues(alpha: 0.03)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: StilloraSpacing.snug,
        vertical: StilloraSpacing.xs + 2,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(feature, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(flex: 2, child: _Cell(free)),
          Expanded(flex: 3, child: _Cell(pro, highlighted: true)),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.value, {this.highlighted = false});

  final String? value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (value == null) {
      return Text(
        '—',
        textAlign: TextAlign.center,
        style: text.bodyMedium?.copyWith(
          color: StilloraColors.onSurfaceVariant,
        ),
      );
    }
    final isCheck = value == '✓';
    return Text(
      value!,
      textAlign: TextAlign.center,
      style: text.bodyMedium?.copyWith(
        fontWeight: isCheck ? FontWeight.w900 : FontWeight.w600,
        color: isCheck
            ? (highlighted
                  ? StilloraColors.brandCyan
                  : StilloraColors.secondary)
            : StilloraColors.onSurfaceVariant,
      ),
    );
  }
}
