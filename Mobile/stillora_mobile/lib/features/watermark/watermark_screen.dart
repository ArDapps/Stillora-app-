import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/ad_widget.dart';
import '../color/color_correction_panel.dart';
import '../color/color_graded_preview.dart';
import '../editor/video_preset.dart';
import '../export/export_cancellation.dart';
import 'watermark_state.dart';

/// "Watermark" section: load a video, then stack one or more logos / images /
/// videos over it as overlays. Each overlay can be dragged, resized, and given a
/// time window so it only appears during part of the clip. The base video's own
/// audio is kept in the export.
class WatermarkView extends ConsumerWidget {
  const WatermarkView({super.key});

  Future<void> _runExport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!watermarkExportSupported) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Watermark export runs on macOS and Windows/Linux today. '
            'iPhone & Android export is coming next.',
          ),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExportingDialog(
        onCancel: () => ref.read(watermarkControllerProvider.notifier).cancel(),
      ),
    );
    try {
      final result =
          await ref.read(watermarkControllerProvider.notifier).export();
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? 'Add a video and at least one overlay first.'
                : 'Saved to Library · ${result.width}×${result.height}',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isExportCancellation(e) ? 'Export cancelled' : 'Export failed: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wm = ref.watch(watermarkControllerProvider);
    final controller = ref.read(watermarkControllerProvider.notifier);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Add a logo, image, or video on top of your clip. Drag to place it, '
              'resize it, and set when it appears. Your video keeps its own sound.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (!wm.hasBase)
              _PickBaseCard(onPick: controller.pickBaseVideo)
            else ...[
              Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 380, maxWidth: 440),
                  child: AspectRatio(
                    aspectRatio: wm.aspectRatio,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: StilloraColors.surfaceContainerLowest,
                        borderRadius:
                            BorderRadius.circular(StilloraRadius.full),
                        border: Border.all(
                          color:
                              StilloraColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(StilloraRadius.full),
                        // Grade the whole composite so the preview matches the
                        // exported (graded) file.
                        child: ColorGradedPreview(
                          adjust: wm.color,
                          child: _WatermarkPreview(
                            wm: wm,
                            onTransform: controller.setOverlayTransform,
                            onSelect: controller.selectOverlay,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BaseInfoRow(wm: wm, onReplace: controller.pickBaseVideo),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: controller.addOverlays,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Add logo, image, or video'),
              ),
              const SizedBox(height: 12),
              if (wm.hasOverlays)
                _OverlayList(wm: wm, controller: controller)
              else
                _OverlayHint(),
              if (colorGradingSupported) ...[
                const SizedBox(height: 16),
                ColorCorrectionPanel(
                  value: wm.color,
                  onChanged: controller.setColor,
                ),
              ],
              const SizedBox(height: 16),
              _ResolutionSelector(
                selected: wm.quality,
                onSelected: controller.setQuality,
              ),
              const SizedBox(height: 16),
              _ExportSection(
                wm: wm,
                onExport: () => _runExport(context, ref),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.reset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Clear'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
          ],
        ),
      ),
    );
  }
}

/// Plays the base video looping (muted) and overlays each layer on top. An
/// overlay is shown at full opacity while inside its time window and dimmed
/// outside it, so the timing is visible yet every layer stays editable.
class _WatermarkPreview extends StatefulWidget {
  const _WatermarkPreview({
    required this.wm,
    required this.onTransform,
    required this.onSelect,
  });

  final WatermarkState wm;
  final void Function(int index, double x, double y, double scale) onTransform;
  final ValueChanged<int> onSelect;

  @override
  State<_WatermarkPreview> createState() => _WatermarkPreviewState();
}

class _WatermarkPreviewState extends State<_WatermarkPreview> {
  VideoPlayerController? _base;
  String? _basePath;
  final Map<String, VideoPlayerController> _overlays = {};
  double _positionSeconds = 0;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _WatermarkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _onBaseTick() {
    final c = _base;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position.inMilliseconds / 1000.0;
    if ((pos - _positionSeconds).abs() >= 0.05) {
      setState(() => _positionSeconds = pos);
    }
  }

  void _sync() {
    // Base video.
    if (widget.wm.baseVideoPath != _basePath) {
      _base?.removeListener(_onBaseTick);
      _base?.dispose();
      _basePath = widget.wm.baseVideoPath;
      _base = null;
      _positionSeconds = 0;
      final path = _basePath;
      if (path != null) {
        final c = VideoPlayerController.file(File(path));
        _base = c;
        c.initialize().then((_) {
          c.setLooping(true);
          c.setVolume(0);
          c.addListener(_onBaseTick);
          c.play();
          if (mounted) setState(() {});
        }).catchError((_) {});
      }
    }

    // Overlay videos.
    final wanted = {
      for (final o in widget.wm.overlays)
        if (o.isVideo) o.path,
    };
    for (final path in wanted) {
      if (_overlays.containsKey(path)) continue;
      final c = VideoPlayerController.file(File(path));
      _overlays[path] = c;
      c.initialize().then((_) {
        c.setLooping(true);
        c.setVolume(0);
        c.play();
        if (mounted) setState(() {});
      }).catchError((_) {});
    }
    final stale =
        _overlays.keys.where((p) => !wanted.contains(p)).toList(growable: false);
    for (final path in stale) {
      _overlays.remove(path)?.dispose();
    }
  }

  @override
  void dispose() {
    _base?.removeListener(_onBaseTick);
    _base?.dispose();
    for (final c in _overlays.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wm = widget.wm;
    final overlays = wm.overlays;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            if (_base?.value.isInitialized ?? false)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _base!.value.size.width,
                    height: _base!.value.size.height,
                    child: VideoPlayer(_base!),
                  ),
                ),
              ),
            for (var i = 0; i < overlays.length; i++)
              Positioned(
                left: overlays[i].x * w,
                top: overlays[i].y * h,
                width: overlays[i].scale * w,
                child: _OverlayBox(
                  key: ValueKey(overlays[i].path),
                  overlay: overlays[i],
                  controller: _overlays[overlays[i].path],
                  selected: i == wm.selectedOverlay,
                  visible: overlays[i].isVisibleAt(_positionSeconds),
                  frameWidth: w,
                  frameHeight: h,
                  onTap: () => widget.onSelect(i),
                  onUpdate: (x, y, scale) =>
                      widget.onTransform(i, x, y, scale),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A draggable + resizable overlay box. Drag anywhere to move; pinch or drag the
/// corner handle to resize. Dimmed when outside its time window.
class _OverlayBox extends StatefulWidget {
  const _OverlayBox({
    super.key,
    required this.overlay,
    required this.controller,
    required this.selected,
    required this.visible,
    required this.frameWidth,
    required this.frameHeight,
    required this.onTap,
    required this.onUpdate,
  });

  final WatermarkOverlay overlay;
  final VideoPlayerController? controller;
  final bool selected;
  final bool visible;
  final double frameWidth;
  final double frameHeight;
  final VoidCallback onTap;
  final void Function(double x, double y, double scale) onUpdate;

  @override
  State<_OverlayBox> createState() => _OverlayBoxState();
}

class _OverlayBoxState extends State<_OverlayBox> {
  double _startScale = 1;

  @override
  Widget build(BuildContext context) {
    final overlay = widget.overlay;
    final Widget media;
    if (overlay.isVideo) {
      final c = widget.controller;
      media = (c != null && c.value.isInitialized)
          ? AspectRatio(
              aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))
          : const AspectRatio(
              aspectRatio: 1,
              child: ColoredBox(color: Colors.black26),
            );
    } else {
      media = Image.file(File(overlay.path), fit: BoxFit.contain);
    }

    // Outside its window the overlay is dimmed; the selected one stays a little
    // more visible so it can still be grabbed and positioned.
    final opacity = widget.visible
        ? 1.0
        : widget.selected
            ? 0.45
            : 0.18;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onScaleStart: (_) {
        widget.onTap();
        _startScale = widget.overlay.scale;
      },
      onScaleUpdate: (details) {
        final x =
            widget.overlay.x + details.focalPointDelta.dx / widget.frameWidth;
        final y =
            widget.overlay.y + details.focalPointDelta.dy / widget.frameHeight;
        final scale = _startScale * details.scale;
        widget.onUpdate(x, y, scale);
      },
      child: Opacity(
        opacity: opacity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.selected
                      ? StilloraColors.primary
                      : Colors.white,
                  width: widget.selected ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRect(child: media),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  final scale =
                      widget.overlay.scale + d.delta.dx / widget.frameWidth;
                  widget.onUpdate(
                      widget.overlay.x, widget.overlay.y, scale);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: StilloraColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaseInfoRow extends StatelessWidget {
  const _BaseInfoRow({required this.wm, required this.onReplace});

  final WatermarkState wm;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final res = wm.outputResolution;
    final measured = wm.baseWidth > 0;
    return StilloraGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.movie_creation_rounded,
              size: 20, color: StilloraColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              measured
                  ? 'Base video · ${res.width}×${res.height} · '
                      '${_fmt(wm.baseDurationSeconds)}'
                  : 'Reading video…',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onReplace, child: const Text('Replace')),
        ],
      ),
    );
  }
}

class _OverlayList extends StatelessWidget {
  const _OverlayList({required this.wm, required this.controller});

  final WatermarkState wm;
  final WatermarkController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overlays', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < wm.overlays.length; i++)
          _OverlayRow(
            key: ValueKey(wm.overlays[i].path),
            index: i,
            overlay: wm.overlays[i],
            baseDuration: wm.baseDurationSeconds,
            selected: i == wm.selectedOverlay,
            onSelect: () => controller.selectOverlay(i),
            onRemove: () => controller.removeOverlay(i),
            onWindow: (start, end) =>
                controller.setOverlayWindow(i, start, end),
          ),
      ],
    );
  }
}

class _OverlayRow extends StatelessWidget {
  const _OverlayRow({
    super.key,
    required this.index,
    required this.overlay,
    required this.baseDuration,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
    required this.onWindow,
  });

  final int index;
  final WatermarkOverlay overlay;
  final int baseDuration;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final void Function(double start, double end) onWindow;

  @override
  Widget build(BuildContext context) {
    final max = baseDuration <= 0 ? 1.0 : baseDuration.toDouble();
    final start = overlay.start.clamp(0.0, max);
    final end = overlay.end.clamp(start, max);
    return Padding(
      padding: const EdgeInsets.only(bottom: StilloraSpacing.xs),
      child: StilloraGlassCard(
        onTap: onSelect,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  overlay.isVideo
                      ? Icons.movie_creation_rounded
                      : Icons.image_rounded,
                  size: 20,
                  color: selected
                      ? StilloraColors.primary
                      : StilloraColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    overlay.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  color: StilloraColors.onSurfaceVariant,
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 15, color: StilloraColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Shows ${_fmt(start.round())} – ${_fmt(end.round())}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            RangeSlider(
              min: 0,
              max: max,
              divisions: baseDuration > 0 ? baseDuration : null,
              values: RangeValues(start, end),
              labels: RangeLabels(_fmt(start.round()), _fmt(end.round())),
              onChanged: (v) => onWindow(v.start, v.end),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportSection extends StatelessWidget {
  const _ExportSection({required this.wm, required this.onExport});

  final WatermarkState wm;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final res = wm.outputResolution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Export', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Text(
          'Output ${res.width} × ${res.height} · ${_fmt(wm.baseDurationSeconds)} '
          '· keeps original audio',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        StilloraPrimaryButton(
          onPressed: wm.canExport ? onExport : null,
          icon: Icons.movie_filter_rounded,
          label: 'Export MP4',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 15, color: StilloraColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Each overlay is burned in with its time window on macOS and '
                'Windows/Linux. iPhone & Android export is coming next.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StilloraColors.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverlayHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'No overlays yet. Add a logo, image, or video to place on the clip.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
    );
  }
}

class _PickBaseCard extends StatelessWidget {
  const _PickBaseCard({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      onTap: onPick,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        children: [
          const Icon(Icons.video_call_rounded,
              color: StilloraColors.primary, size: 34),
          const SizedBox(height: 10),
          Text(
            'Choose a video to watermark',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Then drop your logo, image, or another video on top.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

String _fmt(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '${m}m' : '${m}m ${s}s';
}

/// Output-resolution picker: Original (keep the source size) or a tier that
/// scales the short edge to 720p/1080p/2K/4K, aspect preserved. `null` = Original.
class _ResolutionSelector extends StatelessWidget {
  const _ResolutionSelector({required this.selected, required this.onSelected});

  final ExportQuality? selected;
  final ValueChanged<ExportQuality?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resolution', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Original'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
            for (final q in ExportQuality.values)
              ChoiceChip(
                label: Text(q.label),
                selected: selected == q,
                onSelected: (_) => onSelected(q),
              ),
          ],
        ),
      ],
    );
  }
}

/// Modal shown while the watermark export runs, with a Cancel button that aborts
/// the in-flight export (and its colour-grade pass).
class _ExportingDialog extends StatefulWidget {
  const _ExportingDialog({required this.onCancel});

  final Future<void> Function() onCancel;

  @override
  State<_ExportingDialog> createState() => _ExportingDialogState();
}

class _ExportingDialogState extends State<_ExportingDialog> {
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: StilloraColors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: StilloraSpacing.sm),
            Text(
              _cancelling ? 'Cancelling…' : 'Exporting…',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: StilloraSpacing.sm),
            OutlinedButton.icon(
              onPressed: _cancelling
                  ? null
                  : () async {
                      setState(() => _cancelling = true);
                      await widget.onCancel();
                    },
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel export'),
            ),
          ],
        ),
      ),
    );
  }
}
