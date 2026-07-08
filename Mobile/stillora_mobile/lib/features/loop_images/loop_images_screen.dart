import 'dart:io';

import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/platform/media_actions.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/seconds_input_field.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/render_panel.dart';
import '../editor/editor_state.dart';
import '../editor/video_preset.dart';
import 'loop_images_controller.dart';

/// "Loop images" — add many images, pick one size + one duration, and render a
/// SEPARATE MP4 per image (never merged). Styled to match the HTML → Video tab.
class LoopImagesView extends ConsumerWidget {
  const LoopImagesView({super.key});

  Future<void> _pick(WidgetRef ref) async {
    final result = await pickImportFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null) return;
    final paths = result.files.map((f) => f.path).whereType<String>();
    ref.read(loopImagesControllerProvider.notifier).addPaths(paths);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = useDesktopLayout(context);
    if (desktop) {
      return Padding(
        padding: const EdgeInsets.all(StilloraSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _leftColumn(context, ref, desktop: true),
                ),
              ),
            ),
            const SizedBox(width: StilloraSpacing.lg),
            Expanded(flex: 4, child: _rightColumn(context, ref, fill: true)),
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(StilloraSpacing.sm),
        children: [
          ..._leftColumn(context, ref, desktop: false),
          const SizedBox(height: StilloraSpacing.md),
          _rightColumn(context, ref, fill: false),
        ],
      ),
    );
  }

  List<Widget> _leftColumn(
    BuildContext context,
    WidgetRef ref, {
    required bool desktop,
  }) {
    final state = ref.watch(loopImagesControllerProvider);
    final controller = ref.read(loopImagesControllerProvider.notifier);

    return [
      const RenderEyebrow('BATCH RENDER'),
      const SizedBox(height: StilloraSpacing.sm),
      Text(
        'Loop images to videos',
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.05,
        ),
      ),
      const SizedBox(height: StilloraSpacing.xs),
      const Text(
        'Add up to $kLoopMaxImages images, pick one size and one duration. Each '
        'image becomes its own MP4 of that length — they are not merged.',
        style: TextStyle(color: StilloraColors.onSurfaceVariant, height: 1.4),
      ),
      const SizedBox(height: StilloraSpacing.md),
      RenderStepCard(
        number: '1',
        title: 'Output size',
        trailing: RenderTagPill(
          '${state.outputSize.width}×${state.outputSize.height}',
        ),
        footer: 'Reels · TikTok · Stories · YouTube',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormatGrid(
              selectedId: state.sizeId,
              onSelected: controller.setSize,
            ),
            const SizedBox(height: StilloraSpacing.sm),
            Text('Quality', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: StilloraSpacing.xs),
            RenderPillSegmented(
              options: [for (final q in ExportQuality.values) q.label],
              selectedIndex: ExportQuality.values.indexOf(state.exportQuality),
              onSelected: (i) =>
                  controller.setExportQuality(ExportQuality.values[i]),
            ),
            const SizedBox(height: 4),
            Text(
              '${state.outputSize.width} × ${state.outputSize.height}'
              '  ·  ≈ ${formatFileSize(state.estimatedBytesPerVideo)} each',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: StilloraSpacing.sm),
      RenderStepCard(
        number: '2',
        title: 'Duration',
        trailing: const RenderTagPill('each clip'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${state.durationSeconds} s',
                  style: const TextStyle(
                    color: renderAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                const Text(
                  'type any duration',
                  style: TextStyle(color: StilloraColors.onSurfaceVariant),
                ),
              ],
            ),
            SecondsInputField(
              seconds: state.durationSeconds,
              onChanged: controller.setDuration,
            ),
            Wrap(
              spacing: StilloraSpacing.xs,
              runSpacing: StilloraSpacing.xs,
              children: [
                for (final option in const [
                  (10, '10s'),
                  (30, '30s'),
                  (60, '1 min'),
                  (300, '5 min'),
                  (600, '10 min'),
                  (1800, '30 min'),
                ])
                  ChoiceChip(
                    label: Text(option.$2),
                    selected: state.durationSeconds == option.$1,
                    onSelected: (_) => controller.setDuration(option.$1),
                  ),
              ],
            ),
            const SizedBox(height: StilloraSpacing.xs),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Shorter',
                  onPressed: () => controller.setDuration(
                    state.durationSeconds -
                        durationAdjustmentStep(state.durationSeconds),
                  ),
                  icon: const Icon(Icons.remove_rounded),
                ),
                const Spacer(),
                Text(
                  '${state.durationSeconds} s',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'Longer',
                  onPressed: () => controller.setDuration(
                    state.durationSeconds +
                        durationAdjustmentStep(state.durationSeconds),
                  ),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            TextFormField(
              key: ValueKey('loop-duration-${state.durationSeconds}'),
              initialValue: state.durationSeconds.toString(),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                isDense: true,
                suffixText: 'seconds',
                helperText: 'Any positive duration for each output',
              ),
              onFieldSubmitted: (value) {
                final seconds = int.tryParse(value);
                if (seconds != null) {
                  controller.setDuration(seconds);
                }
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: StilloraSpacing.sm),
      RenderStepCard(
        number: '3',
        title: 'Image mode',
        child: RenderPillSegmented(
          options: const ['Fit', 'Fill'],
          selectedIndex: state.resizeMode == engine.ResizeMode.fit ? 0 : 1,
          onSelected: (i) => controller.setResizeMode(
            i == 0 ? engine.ResizeMode.fit : engine.ResizeMode.fill,
          ),
        ),
      ),
    ];
  }

  Widget _rightColumn(
    BuildContext context,
    WidgetRef ref, {
    required bool fill,
  }) {
    final state = ref.watch(loopImagesControllerProvider);
    final controller = ref.read(loopImagesControllerProvider.notifier);

    final panel = _ImagesPanel(fill: fill, onAdd: () => _pick(ref));
    final convert = SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: state.items.isEmpty || state.isRunning
            ? null
            : controller.convertAll,
        icon: state.isRunning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.movie_creation_outlined),
        label: Text(
          state.isRunning
              ? 'Converting…'
              : 'Convert ${state.items.length} ${state.items.length == 1 ? "image" : "images"}',
        ),
      ),
    );

    final actions = Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: state.isRunning ? null : () => _pick(ref),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(state.items.isEmpty ? 'Add images' : 'Add more'),
          ),
        ),
        if (state.items.isNotEmpty && !state.isRunning) ...[
          const SizedBox(width: StilloraSpacing.xs),
          OutlinedButton.icon(
            onPressed: controller.clear,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Clear'),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fill) Expanded(child: panel) else panel,
        const SizedBox(height: StilloraSpacing.sm),
        actions,
        const SizedBox(height: StilloraSpacing.sm),
        convert,
        if (state.doneCount > 0) ...[
          const SizedBox(height: StilloraSpacing.xs),
          Text(
            '${state.doneCount} of ${state.items.length} saved to Library',
            style: const TextStyle(
              color: StilloraColors.secondary,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 16),
        const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
      ],
    );
  }
}

/// The right-hand panel: a header chip and the image grid (or empty hint).
class _ImagesPanel extends ConsumerWidget {
  const _ImagesPanel({required this.fill, required this.onAdd});

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
      itemBuilder: (context, i) => _LoopCard(item: items[i]),
    );

    final body = items.isEmpty
        ? _EmptyDrop(onAdd: onAdd, expand: fill)
        : (fill ? Expanded(child: grid) : grid);

    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.md),
      decoration: BoxDecoration(
        color: renderPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renderPanelBorder),
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
                const Text(
                  'Rendering…',
                  style: TextStyle(
                    color: renderAccent,
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

class _EmptyDrop extends StatelessWidget {
  const _EmptyDrop({required this.onAdd, required this.expand});

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
            border: Border.all(color: renderPanelBorder),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 34,
                color: renderAccent,
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

class _LoopCard extends ConsumerWidget {
  const _LoopCard({required this.item});

  final LoopItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(
      loopImagesControllerProvider.select((s) => s.isRunning),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StilloraColors.surfaceDim,
          border: Border.all(color: renderPanelBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(item.path), fit: BoxFit.cover),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: _StatusBadge(item: item),
                  ),
                  if (!running)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: _RoundIcon(
                        icon: Icons.close_rounded,
                        onTap: () => ref
                            .read(loopImagesControllerProvider.notifier)
                            .remove(item.id),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.status == LoopItemStatus.done &&
                      item.resultPath != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      tooltip: 'Share video',
                      onPressed: () =>
                          MediaActions.shareVideo(context, item.resultPath!),
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.item});

  final LoopItem item;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final String text;
    Widget? leading;
    switch (item.status) {
      case LoopItemStatus.rendering:
        bg = renderAccent;
        text = 'Rendering';
        leading = const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
      case LoopItemStatus.done:
        bg = const Color(0xff16a34a);
        text = 'Done';
      case LoopItemStatus.error:
        bg = const Color(0xffdc2626);
        text = 'Failed';
      case LoopItemStatus.ready:
        bg = Colors.black.withValues(alpha: 0.6);
        text = 'Ready';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 5)],
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _FormatGrid extends StatelessWidget {
  const _FormatGrid({required this.selectedId, required this.onSelected});

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
