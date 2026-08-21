import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/section_export_widgets.dart';
import '../../core/widgets/section_split_view.dart';
import '../export/export_cancellation.dart';
import '../preview/section_video_preview.dart';
import 'text_overlay_controller.dart';
import 'widgets/text_layer_list.dart';
import 'widgets/text_overlay_preview.dart';
import 'widgets/text_property_editor.dart';
import '../../core/i18n/app_strings.dart';

/// "Text" section: load a video, then stack one or more animated text overlays
/// on top. Each layer is dragged into place on a live preview, timed with a
/// start/end window, and dissolved in/out with a fade. Text is rendered to a
/// transparent PNG at the export resolution and burned in, keeping the base
/// video's own audio.
class TextOverlayView extends ConsumerWidget {
  const TextOverlayView({super.key});

  Future<void> _runExport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!textOverlayExportSupported) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.strings.txtPlatformNote)),
      );
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SectionExportingDialog(
        onCancel: () =>
            ref.read(textOverlayControllerProvider.notifier).cancel(),
      ),
    );
    try {
      final result = await ref
          .read(textOverlayControllerProvider.notifier)
          .export();
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? context.strings.txtNeedVideoAndLayer
                : '${context.strings.savedToLibrary} · '
                      '${result.width}×${result.height}',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isExportCancellation(e)
                ? context.strings.exportCancelled
                : '${context.strings.txtExportFailed}: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(textOverlayControllerProvider);
    final controller = ref.read(textOverlayControllerProvider.notifier);

    // Desktop: the layer list and property editor scroll on the left while the
    // live composite stays pinned in the right-hand pane, so dragging a layer
    // or nudging a fade is reflected without losing sight of the frame.
    return DecoratedBox(
      decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: SectionSplitView(
          onStartOver: controller.reset,
          canStartOver: st.hasBase,
          previewCaption: st.hasBase ? context.strings.txtDragHint : null,
          preview: PreviewStage(
            aspectRatio: st.aspectRatio,
            emptyLabel: context.strings.txtLoadVideoFirst,
            emptyIcon: Icons.text_fields_rounded,
            child: st.hasBase
                ? TextOverlayPreview(
                    st: st,
                    onTransform: controller.setTransform,
                    onSelect: controller.select,
                  )
                : null,
          ),
          controls: [
            Text(
              context.strings.txtIntro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (!st.hasBase)
              SectionPickBaseCard(
                title: context.strings.txtChooseVideo,
                subtitle: context.strings.txtThenAdd,
                onPick: controller.pickBaseVideo,
              )
            else ...[
              SectionBaseInfoRow(
                resolution: st.outputResolution,
                durationSeconds: st.baseDurationSeconds,
                measured: st.baseWidth > 0,
                onReplace: controller.pickBaseVideo,
              ),
              const SizedBox(height: 16),
              AddTextRow(controller: controller),
              const SizedBox(height: 12),
              if (st.hasLayers) ...[
                TimelineStrip(st: st, onSelect: controller.select),
                const SizedBox(height: 16),
                LayerList(st: st, controller: controller),
                const SizedBox(height: 16),
                if (st.selectedLayer != null)
                  PropertyEditor(
                    index: st.selected,
                    layer: st.selectedLayer!,
                    baseDuration: st.baseDurationSeconds,
                    controller: controller,
                  ),
              ] else
                SectionEmptyHint(context.strings.txtNoLayersYet),
              const SizedBox(height: 16),
              SectionResolutionSelector(
                selected: st.quality,
                onSelected: controller.setQuality,
              ),
              const SizedBox(height: 16),
              SectionExportPanel(
                resolution: st.outputResolution,
                durationSeconds: st.baseDurationSeconds,
                canExport: st.canExport,
                onExport: () => _runExport(context, ref),
                platformNote: context.strings.txtPlatformNote,
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
