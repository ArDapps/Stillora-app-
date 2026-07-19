import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/duration_slider.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/render_panel.dart';
import '../../core/widgets/start_over_button.dart';
import '../editor/editor_state.dart';
import '../editor/video_preset.dart';
import 'loop_images_controller.dart';
import 'widgets/loop_images_panel.dart';

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
    final state = ref.watch(loopImagesControllerProvider);
    final startOver = Align(
      alignment: Alignment.centerRight,
      child: StartOverButton(
        onReset: ref.read(loopImagesControllerProvider.notifier).reset,
        enabled: state.items.isNotEmpty && !state.isRunning,
        confirmMessage:
            'This clears the queued images and the size, duration and quality '
            'choices. This cannot be undone.',
      ),
    );

    if (desktop) {
      return Padding(
        padding: const EdgeInsets.all(StilloraSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  startOver,
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _leftColumn(context, ref, desktop: true),
                      ),
                    ),
                  ),
                ],
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
          startOver,
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
            LoopFormatGrid(
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
                    color: StilloraColors.accent,
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
            const SizedBox(height: StilloraSpacing.sm),
            DurationSlider(
              seconds: state.durationSeconds,
              min: minDurationSeconds,
              label: 'Each output',
              onChanged: controller.setDuration,
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

    final panel = LoopImagesPanel(fill: fill, onAdd: () => _pick(ref));
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
