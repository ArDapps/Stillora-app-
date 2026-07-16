import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/widgets/ad_widget.dart';
import 'remove_watermark_state.dart';

/// "Remove Watermark" section: load a TikTok clip, mark where the watermark sits
/// (top/bottom presets), then either blur those regions or cover them with your
/// own logo, and export the clean video to the Library.
class RemoveWatermarkView extends ConsumerWidget {
  const RemoveWatermarkView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(removeWatermarkControllerProvider);
    final controller = ref.read(removeWatermarkControllerProvider.notifier);

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(StilloraSpacing.md),
        children: [
          Text(
            'Remove Watermark',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Hide a TikTok watermark: load a clip, mark where the watermark '
            'sits, then blur it or cover it with your own logo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: StilloraSpacing.md),
          if (!state.hasBase)
            _EmptyHero(onPick: controller.pickBaseVideo)
          else ...[
            _LoadVideoCard(state: state, onPick: controller.pickBaseVideo),
            const SizedBox(height: StilloraSpacing.md),
            _PreviewBox(state: state),
            const SizedBox(height: StilloraSpacing.md),
            _ModeToggle(state: state, onChanged: controller.setMode),
            const SizedBox(height: StilloraSpacing.md),
            _TargetsCard(state: state, controller: controller),
            const SizedBox(height: StilloraSpacing.md),
            if (state.mode == RemoveMode.blur)
              _BlurControls(state: state, onStrength: controller.setStrength)
            else
              _LogoControls(state: state, onPickLogo: controller.pickLogo),
            const SizedBox(height: StilloraSpacing.md),
            _ExportButton(state: state),
          ],
          const SizedBox(height: StilloraSpacing.md),
          const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
        ],
      ),
    );
  }
}

/// Shown before a video is loaded — a clear hero so the section never looks
/// blank, with the primary "load a video" call to action.
class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.onPick});

  final Future<void> Function() onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.auto_fix_high_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No video yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Load a TikTok video, then blur the watermark or cover it with '
              'your own logo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onPick(),
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('Load a video'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadVideoCard extends StatelessWidget {
  const _LoadVideoCard({required this.state, required this.onPick});

  final RemoveWatermarkState state;
  final Future<void> Function() onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.video_library_outlined),
            const SizedBox(width: StilloraSpacing.sm),
            Expanded(
              child: Text(
                state.hasBase
                    ? '${_fileName(state.baseVideoPath!)}  ·  '
                        '${state.baseWidth}×${state.baseHeight}'
                    : 'No video loaded',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FilledButton.tonal(
              onPressed: () => onPick(),
              child: Text(state.hasBase ? 'Change' : 'Load video'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dark aspect-ratio box with the enabled target rectangles drawn on top, so
/// the user sees roughly where the blur / logo cover will land.
class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.state});

  final RemoveWatermarkState state;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: state.aspectRatio <= 0 ? 9 / 16 : state.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              children: [
                Container(color: const Color(0xFF12131A)),
                const Center(
                  child: Icon(Icons.movie_outlined, color: Colors.white24, size: 48),
                ),
                for (var i = 0; i < state.targets.length; i++)
                  if (state.targets[i].enabled)
                    Positioned(
                      left: state.targets[i].x * w,
                      top: state.targets[i].y * h,
                      width: state.targets[i].w * w,
                      height: state.targets[i].h * h,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: (state.mode == RemoveMode.blur
                                  ? StilloraColors.primary
                                  : StilloraColors.secondary)
                              .withValues(alpha: 0.25),
                          border: Border.all(
                            color: i == state.selectedTarget
                                ? StilloraColors.primary
                                : Colors.white54,
                            width: i == state.selectedTarget ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            state.targets[i].label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.state, required this.onChanged});

  final RemoveWatermarkState state;
  final void Function(RemoveMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<RemoveMode>(
      segments: const [
        ButtonSegment(
          value: RemoveMode.blur,
          label: Text('Blur'),
          icon: Icon(Icons.blur_on),
        ),
        ButtonSegment(
          value: RemoveMode.logo,
          label: Text('Cover with logo'),
          icon: Icon(Icons.image_outlined),
        ),
      ],
      selected: {state.mode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _TargetsCard extends StatelessWidget {
  const _TargetsCard({required this.state, required this.controller});

  final RemoveWatermarkState state;
  final RemoveWatermarkController controller;

  @override
  Widget build(BuildContext context) {
    final sel = state.selectedTarget.clamp(0, state.targets.length - 1);
    final target = state.targets[sel];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Watermark area', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: StilloraSpacing.xs),
            Wrap(
              spacing: StilloraSpacing.sm,
              children: [
                for (var i = 0; i < state.targets.length; i++)
                  FilterChip(
                    label: Text(state.targets[i].label),
                    selected: state.targets[i].enabled,
                    onSelected: (v) => controller.toggleTarget(i, v),
                    avatar: i == sel ? const Icon(Icons.edit, size: 16) : null,
                    onDeleted: null,
                  ),
              ],
            ),
            const SizedBox(height: StilloraSpacing.sm),
            Text(
              'Editing: ${target.label}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
            ),
            _rectSlider(context, 'Left', target.x, (v) => controller.setTargetRect(sel, x: v)),
            _rectSlider(context, 'Top', target.y, (v) => controller.setTargetRect(sel, y: v)),
            _rectSlider(context, 'Width', target.w, (v) => controller.setTargetRect(sel, w: v)),
            _rectSlider(context, 'Height', target.h, (v) => controller.setTargetRect(sel, h: v)),
            Wrap(
              spacing: StilloraSpacing.sm,
              children: [
                for (var i = 0; i < state.targets.length; i++)
                  TextButton(
                    onPressed: () => controller.selectTarget(i),
                    child: Text('Edit ${state.targets[i].label}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rectSlider(
    BuildContext context,
    String label,
    double value,
    void Function(double) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            value: value.clamp(0.0, 1.0),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text('${(value * 100).round()}%',
              style: const TextStyle(fontSize: 11), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _BlurControls extends StatelessWidget {
  const _BlurControls({required this.state, required this.onStrength});

  final RemoveWatermarkState state;
  final void Function(double) onStrength;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blur strength', style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: state.strength.clamp(0.05, 1.0),
              min: 0.05,
              max: 1.0,
              onChanged: onStrength,
            ),
            if (!blurRemovalSupported)
              Text(
                'Blur runs on Windows/Linux today. On macOS/iPhone/Android, use '
                '“Cover with logo”.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StilloraColors.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogoControls extends StatelessWidget {
  const _LogoControls({required this.state, required this.onPickLogo});

  final RemoveWatermarkState state;
  final Future<void> Function() onPickLogo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.image_outlined),
            const SizedBox(width: StilloraSpacing.sm),
            Expanded(
              child: Text(
                state.logoPath == null
                    ? 'No logo selected'
                    : _fileName(state.logoPath!),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FilledButton.tonal(
              onPressed: () => onPickLogo(),
              child: Text(state.logoPath == null ? 'Upload logo' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends ConsumerWidget {
  const _ExportButton({required this.state});

  final RemoveWatermarkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supported = removeWatermarkSupported;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: state.canExport && supported ? () => _export(context, ref) : null,
          icon: const Icon(Icons.download_done_outlined),
          label: Text(state.mode == RemoveMode.blur ? 'Blur & export' : 'Cover & export'),
        ),
        if (!supported)
          Padding(
            padding: const EdgeInsets.only(top: StilloraSpacing.xs),
            child: Text(
              'Export runs on macOS and Windows/Linux today. iPhone & Android '
              'export is coming next.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(removeWatermarkControllerProvider.notifier);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Processing…')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => controller.cancel(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    try {
      final result = await controller.export();
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? 'Load a video and select a watermark area first.'
                : 'Saved to Library · ${result.width}×${result.height}',
          ),
        ),
      );
    } on BlurUnavailableException {
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Blur removal runs on Windows/Linux today. Try “Cover with logo”.',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed. $e')),
      );
    }
  }
}

String _fileName(String path) {
  final i = path.lastIndexOf(RegExp(r'[/\\]'));
  return i == -1 ? path : path.substring(i + 1);
}
