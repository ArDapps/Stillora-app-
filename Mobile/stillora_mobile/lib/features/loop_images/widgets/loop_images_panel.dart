import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/widgets/render_panel.dart';
import '../loop_images_controller.dart';
import 'loop_image_card.dart';

/// The right-hand panel: a header chip and the image grid (or empty hint).
class LoopImagesPanel extends ConsumerWidget {
  const LoopImagesPanel({super.key, required this.fill, required this.onAdd});

  final bool fill;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loopImagesControllerProvider);
    final items = state.items;

    final grid = GridView.builder(
      shrinkWrap: !fill,
      physics: fill ? null : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 210,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => LoopCard(item: items[i]),
    );

    final body = items.isEmpty
        ? LoopEmptyDrop(onAdd: onAdd, expand: fill)
        : (fill ? Expanded(child: grid) : grid);

    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.md),
      decoration: BoxDecoration(
        color: StilloraColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StilloraColors.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              RenderTagPill('${items.length}/$kLoopMaxImages images'),
              const Spacer(),
              if (state.isRunning)
                Text(
                  'Rendering…',
                  style: TextStyle(
                    color: StilloraColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          body,
        ],
      ),
    );
  }
}

class LoopEmptyDrop extends StatelessWidget {
  const LoopEmptyDrop({super.key, required this.onAdd, required this.expand});

  final VoidCallback onAdd;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: StilloraColors.surfaceDim,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onAdd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StilloraColors.panelBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 34,
                color: StilloraColors.accent,
              ),
              SizedBox(height: StilloraSpacing.xs),
              Text(
                'Drop images or click to add',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: StilloraColors.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'JPG · PNG · WebP — each becomes its own MP4',
                style: TextStyle(
                  color: StilloraColors.onSurfaceVariant,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    return expand ? Expanded(child: Center(child: tile)) : tile;
  }
}

class LoopFormatGrid extends StatelessWidget {
  const LoopFormatGrid({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < loopSizes.length; i += 2)
          Padding(
            padding: EdgeInsets.only(
              bottom: i + 2 < loopSizes.length ? StilloraSpacing.xs : 0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: RenderFormatTile(
                    label: loopSizes[i].label,
                    ratio: loopSizes[i].ratio,
                    selected: loopSizes[i].id == selectedId,
                    onTap: () => onSelected(loopSizes[i].id),
                  ),
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: i + 1 < loopSizes.length
                      ? RenderFormatTile(
                          label: loopSizes[i + 1].label,
                          ratio: loopSizes[i + 1].ratio,
                          selected: loopSizes[i + 1].id == selectedId,
                          onTap: () => onSelected(loopSizes[i + 1].id),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
