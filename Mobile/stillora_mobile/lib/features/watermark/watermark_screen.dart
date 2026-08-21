import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/section_export_widgets.dart';
import '../../core/widgets/section_split_view.dart';
import '../color/color_correction_panel.dart';
import '../color/color_graded_preview.dart';
import '../export/export_cancellation.dart';
import '../preview/section_video_preview.dart';
import 'watermark_state.dart';
import 'widgets/watermark_overlay_list.dart';
import 'widgets/watermark_preview.dart';

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
      builder: (_) => SectionExportingDialog(
        onCancel: () => ref.read(watermarkControllerProvider.notifier).cancel(),
      ),
    );
    try {
      final result = await ref
          .read(watermarkControllerProvider.notifier)
          .export();
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

    // Desktop: overlay list, grade and export controls scroll on the left while
    // the live composite stays pinned in the right-hand pane, so dragging or
    // resizing an overlay is reflected without scrolling back to the frame.
    return DecoratedBox(
      decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: SectionSplitView(
          onStartOver: controller.reset,
          canStartOver: wm.hasBase,
          previewCaption: wm.hasBase
              ? 'Drag an overlay to place it — this is what gets exported'
              : null,
          preview: PreviewStage(
            aspectRatio: wm.aspectRatio,
            emptyLabel: 'Load a video to stack overlays on it',
            emptyIcon: Icons.branding_watermark_outlined,
            // Grade the whole composite so the preview matches the exported
            // (graded) file.
            child: wm.hasBase
                ? ColorGradedPreview(
                    adjust: wm.color,
                    child: WatermarkPreview(
                      wm: wm,
                      onTransform: controller.setOverlayTransform,
                      onSelect: controller.selectOverlay,
                    ),
                  )
                : null,
          ),
          controls: [
            Text(
              'Add a logo, image, or video on top of your clip. Drag to place it, '
              'resize it, and set when it appears. Your video keeps its own sound.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (!wm.hasBase)
              SectionPickBaseCard(
                title: 'Choose a video to watermark',
                subtitle:
                    'Then drop your logo, image, or another video on top.',
                onPick: controller.pickBaseVideo,
              )
            else ...[
              SectionBaseInfoRow(
                resolution: wm.outputResolution,
                durationSeconds: wm.baseDurationSeconds,
                measured: wm.baseWidth > 0,
                onReplace: controller.pickBaseVideo,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: controller.addOverlays,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Add logo, image, or video'),
              ),
              const SizedBox(height: 12),
              if (wm.hasOverlays)
                WatermarkOverlayList(wm: wm, controller: controller)
              else
                const SectionEmptyHint(
                  'No overlays yet. Add a logo, image, or video to place on '
                  'the clip.',
                ),
              if (colorGradingSupported) ...[
                const SizedBox(height: 16),
                ColorCorrectionPanel(
                  value: wm.color,
                  onChanged: controller.setColor,
                ),
              ],
              const SizedBox(height: 16),
              SectionResolutionSelector(
                selected: wm.quality,
                onSelected: controller.setQuality,
              ),
              const SizedBox(height: 16),
              SectionExportPanel(
                resolution: wm.outputResolution,
                durationSeconds: wm.baseDurationSeconds,
                canExport: wm.canExport,
                onExport: () => _runExport(context, ref),
                platformNote:
                    'Each overlay is burned in with its time window on macOS '
                    'and Windows/Linux. iPhone & Android export is coming next.',
              ),
              // Clearing is the shared "Start over" control pinned above the
              // controls column.
            ],
            const SizedBox(height: 16),
            const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
          ],
        ),
      ),
    );
  }
}
