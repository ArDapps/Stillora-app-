import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/render_components.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/platform/media_actions.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/section_split_view.dart';
import 'store_screenshots_state.dart';
import 'widgets/shot_queue_panel.dart';
import 'widgets/target_picker.dart';

/// "Store Screenshots" — take one set of app screens and render them at every
/// size the App Store and Google Play ask for, packed into a single zip.
///
/// The sizes live in `store_target.dart`, transcribed from the stores' own
/// reference pages; this screen is just the picker and the export.
class StoreScreenshotsView extends ConsumerWidget {
  const StoreScreenshotsView({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(storeScreenshotsControllerProvider.notifier);
    final result = await controller.exportZip();
    if (!context.mounted || result == null) return;

    void snack(String message) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    if (result.isEmpty) {
      snack(context.strings.ssNothing);
      return;
    }

    // Desktop gets a Save As dialog; a phone has no file manager to save into,
    // so the share sheet is the way out (it offers "Save to Files").
    if (isDesktopPlatform) {
      final outcome = await MediaActions.saveZipToFile(
        result.zipPath,
        suggestedName: result.fileName,
        dialogTitle: context.strings.ssSaveZip,
      );
      if (!context.mounted) return;
      switch (outcome) {
        case SaveOutcome.saved:
          snack('${context.strings.ssSavedZip} · ${result.written}');
        case SaveOutcome.cancelled:
          break;
        case SaveOutcome.missingFile:
          snack(context.strings.ssGone);
        case SaveOutcome.permissionDenied:
        case SaveOutcome.failed:
          snack(context.strings.ssSaveFailed);
      }
      return;
    }

    final shared = await MediaActions.shareZip(context, result.zipPath);
    if (!context.mounted) return;
    if (!shared) snack(context.strings.ssGone);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeScreenshotsControllerProvider);
    final controller = ref.read(storeScreenshotsControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: SectionSplitView(
          onStartOver: controller.reset,
          canStartOver: state.hasImages && !state.isRunning,
          // Nothing to preview until screens are added — on a phone the panel
          // stays away entirely rather than showing an empty frame.
          hasPreview: state.hasImages,
          previewCaption: context.strings.ssPreviewCaption,
          previewActions: _ExportButton(onExport: () => _export(context, ref)),
          preview: ShotQueuePanel(onAdd: controller.pickImages),
          controls: [
            RenderEyebrow(context.strings.ssEyebrow),
            const SizedBox(height: StilloraSpacing.xs),
            Text(
              context.strings.ssHeading,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: StilloraSpacing.xs),
            Text(
              context.strings.ssIntro,
              style: TextStyle(
                color: StilloraColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: StilloraSpacing.sm),

            // 1 · Source images
            RenderStepCard(
              number: '1',
              title: context.strings.ssSourceImages,
              trailing: RenderTagPill('${state.paths.length}'),
              footer: context.strings.ssZipLayout,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: state.isRunning ? null : controller.pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(
                        state.hasImages
                            ? context.strings.ssAddMore
                            : context.strings.ssAddImages,
                      ),
                    ),
                  ),
                  if (state.hasImages) ...[
                    const SizedBox(height: StilloraSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: state.isRunning
                          ? null
                          : controller.clearImages,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(context.strings.ssClear),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: StilloraSpacing.sm),

            // 2 · Sizes
            RenderStepCard(
              number: '2',
              title: context.strings.ssSizes,
              trailing: RenderTagPill('${state.selectedTargetIds.length}'),
              footer: state.hasTargets ? null : context.strings.ssPickSizes,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.selectRequiredOnly,
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: Text(context.strings.ssRequiredOnly),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: StilloraSpacing.sm),
                  Text(
                    context.strings.ssOrientation,
                    style: textTheme.labelMedium,
                  ),
                  const SizedBox(height: StilloraSpacing.xs),
                  RenderPillSegmented(
                    options: [
                      context.strings.ssPortrait,
                      context.strings.ssLandscape,
                    ],
                    selectedIndex: state.landscape ? 1 : 0,
                    onSelected: (i) => controller.setLandscape(i == 1),
                  ),
                  const SizedBox(height: StilloraSpacing.sm),
                  const TargetPicker(),
                ],
              ),
            ),
            const SizedBox(height: StilloraSpacing.sm),

            // 3 · Look
            RenderStepCard(
              number: '3',
              title: context.strings.ssLook,
              footer: context.strings.ssNoAlphaNote,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RenderPillSegmented(
                    options: [context.strings.ssFit, context.strings.ssFill],
                    selectedIndex: state.fit == ShotFit.fit ? 0 : 1,
                    onSelected: (i) =>
                        controller.setFit(i == 0 ? ShotFit.fit : ShotFit.fill),
                  ),
                  const SizedBox(height: StilloraSpacing.sm),
                  Text(
                    context.strings.ssBackground,
                    style: textTheme.labelMedium,
                  ),
                  const SizedBox(height: StilloraSpacing.xs),
                  RenderPillSegmented(
                    options: [
                      context.strings.ssMidnight,
                      context.strings.ssBlack,
                      context.strings.ssWhite,
                    ],
                    selectedIndex: switch (state.background) {
                      ShotBackground.midnight => 0,
                      ShotBackground.black => 1,
                      ShotBackground.white => 2,
                    },
                    onSelected: (i) => controller.setBackground(switch (i) {
                      0 => ShotBackground.midnight,
                      1 => ShotBackground.black,
                      _ => ShotBackground.white,
                    }),
                  ),
                  const SizedBox(height: StilloraSpacing.sm),
                  Text(context.strings.ssFormat, style: textTheme.labelMedium),
                  const SizedBox(height: StilloraSpacing.xs),
                  RenderPillSegmented(
                    options: [ShotFormat.png.label, ShotFormat.jpeg.label],
                    selectedIndex: state.format == ShotFormat.png ? 0 : 1,
                    onSelected: (i) => controller.setFormat(
                      i == 0 ? ShotFormat.png : ShotFormat.jpeg,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: StilloraSpacing.sm),
            const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
          ],
        ),
      ),
    );
  }
}

/// The one button that turns the queue into a zip. Doubles as the progress
/// readout while the matrix renders, so a long export never looks stalled.
class _ExportButton extends ConsumerWidget {
  const _ExportButton({required this.onExport});

  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeScreenshotsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.isRunning) ...[
          ShotProgressBar(done: state.progress, total: state.total),
          const SizedBox(height: StilloraSpacing.xs),
        ],
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: state.canExport ? onExport : null,
            icon: state.isRunning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isDesktopPlatform
                        ? Icons.download_rounded
                        : Icons.ios_share_rounded,
                  ),
            label: Text(
              state.isRunning
                  ? context.strings.ssExporting
                  : '${context.strings.ssExport}'
                        '${state.hasImages && state.hasTargets ? ' · ${state.outputCount}' : ''}',
            ),
          ),
        ),
      ],
    );
  }
}
