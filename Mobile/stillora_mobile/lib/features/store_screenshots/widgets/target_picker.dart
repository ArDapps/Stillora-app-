import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/render_components.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/i18n/app_strings.dart';
import '../store_screenshots_state.dart';
import '../store_target.dart';

/// The size picker: one collapsible group per device family, each row a size
/// with its exact pixel dimensions. The dimensions are the point of the
/// section, so they are shown on every row rather than hidden behind a tap.
class TargetPicker extends ConsumerWidget {
  const TargetPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeScreenshotsControllerProvider);
    final controller = ref.read(storeScreenshotsControllerProvider.notifier);
    final grouped = targetsByFamily();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in grouped.entries) ...[
          _FamilyGroup(
            family: entry.key,
            targets: entry.value,
            selected: state.selectedTargetIds,
            landscape: state.landscape,
            onToggleTarget: controller.toggleTarget,
            onToggleFamily: () => controller.toggleFamily(entry.key),
          ),
          const SizedBox(height: StilloraSpacing.sm),
        ],
      ],
    );
  }
}

class _FamilyGroup extends StatelessWidget {
  const _FamilyGroup({
    required this.family,
    required this.targets,
    required this.selected,
    required this.landscape,
    required this.onToggleTarget,
    required this.onToggleFamily,
  });

  final StoreFamily family;
  final List<StoreTarget> targets;
  final Set<String> selected;
  final bool landscape;
  final ValueChanged<String> onToggleTarget;
  final VoidCallback onToggleFamily;

  @override
  Widget build(BuildContext context) {
    final chosen = targets.where((t) => selected.contains(t.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(_icon, size: 16, color: StilloraColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                family.label(context.strings),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (chosen > 0)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: RenderTagPill('$chosen/${targets.length}'),
              ),
            TextButton(
              onPressed: onToggleFamily,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                chosen == targets.length
                    ? context.strings.ssClear
                    : context.strings.ssAddMore,
              ),
            ),
          ],
        ),
        const SizedBox(height: StilloraSpacing.xs),
        for (final target in targets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _TargetRow(
              target: target,
              selected: selected.contains(target.id),
              landscape: landscape,
              onTap: () => onToggleTarget(target.id),
            ),
          ),
      ],
    );
  }

  IconData get _icon => switch (family) {
    StoreFamily.iPhone => Icons.phone_iphone_rounded,
    StoreFamily.iPad => Icons.tablet_mac_rounded,
    StoreFamily.mac => Icons.laptop_mac_rounded,
    StoreFamily.watch => Icons.watch_rounded,
    StoreFamily.appleTv => Icons.tv_rounded,
    StoreFamily.visionPro => Icons.visibility_rounded,
    StoreFamily.androidPhone => Icons.smartphone_rounded,
    StoreFamily.androidTablet => Icons.tablet_android_rounded,
  };
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.target,
    required this.selected,
    required this.landscape,
    required this.onTap,
  });

  final StoreTarget target;
  final bool selected;
  final bool landscape;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = target.resolve(landscape: landscape);
    final textTheme = Theme.of(context).textTheme;
    // Mac, TV and Vision sizes are *named* by their resolution, so printing the
    // dimension column as well would say the same thing twice on one row.
    final dimensions = '${size.width}×${size.height}';
    final duplicated =
        target.label.replaceAll(' ', '') == dimensions.replaceAll(' ', '');

    return Material(
      color: selected
          ? StilloraColors.primary.withValues(alpha: 0.12)
          : StilloraColors.surfaceDim,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? StilloraColors.primary
                  : StilloraColors.glassStroke,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: selected
                    ? StilloraColors.primary
                    : StilloraColors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            target.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (target.required) ...[
                          const SizedBox(width: 6),
                          _RequiredPill(label: context.strings.ssRequired),
                        ],
                      ],
                    ),
                    if (target.devices != null)
                      Text(
                        target.devices!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: StilloraColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (!duplicated) ...[
                const SizedBox(width: 8),
                Text(
                  dimensions,
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: selected
                        ? StilloraColors.onSurface
                        : StilloraColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Marks the sizes the store will not let you publish without.
class _RequiredPill extends StatelessWidget {
  const _RequiredPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: StilloraColors.secondary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(StilloraRadius.pill),
        border: Border.all(
          color: StilloraColors.secondary.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: StilloraColors.secondary,
        ),
      ),
    );
  }
}
