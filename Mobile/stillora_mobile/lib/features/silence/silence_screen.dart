import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/section_split_view.dart';
import '../audio/audio_source.dart';
import '../color/color_grade_section.dart';
import '../editor/editor_state.dart' show formatFileSize;
import '../export/export_cancellation.dart';
import '../preview/section_video_preview.dart';
import 'silence_state.dart';
import '../../core/pro/pro_quality_picker.dart';
import '../../core/pro/pro_gate.dart';
import '../../core/i18n/app_strings.dart';

/// Standalone "Remove Silence" section: upload a video, auto-cut the silent
/// (non-speech) stretches, merge what's left, and export at a quality tier.
class SilenceView extends ConsumerStatefulWidget {
  const SilenceView({super.key});

  @override
  ConsumerState<SilenceView> createState() => _SilenceViewState();
}

class _SilenceViewState extends ConsumerState<SilenceView> {
  bool _running = false;
  bool _cancelling = false;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _cancelling = false;
    });
    try {
      final result = await ref.read(silenceControllerProvider.notifier).run();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? context.strings.exNothingToExport
                : '${context.strings.savedToLibrary} · ${result.durationSeconds}s '
                      '(${result.width}×${result.height})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isExportCancellation(e)
                ? context.strings.exportCancelled
                : '${context.strings.exFailed}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _cancelling = false;
        });
      }
    }
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    await ref.read(silenceControllerProvider.notifier).cancel();
  }

  @override
  Widget build(BuildContext context) {
    final silence = ref.watch(silenceControllerProvider);
    final controller = ref.read(silenceControllerProvider.notifier);
    final res = silence.outputResolution;

    // Desktop: controls scroll on the left, the graded frame stays pinned in
    // the right-hand pane so sensitivity / speed / colour edits are reflected
    // straight away. Phones get the same preview at the top of the column.
    return DecoratedBox(
      decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: SectionSplitView(
          onStartOver: controller.reset,
          canStartOver: silence.hasVideo && !_running,
          hasPreview: silence.hasVideo,
          previewCaption: silence.hasVideo
              ? context.strings.slPreviewCaption
              : null,
          preview: SectionVideoPreview(
            videoPath: silence.videoPath,
            sourceWidth: silence.sourceWidth,
            sourceHeight: silence.sourceHeight,
            color: silence.color,
            badge: silence.speed > 1 ? '${silence.speed}x' : null,
            emptyLabel: context.strings.slUploadToPreview,
            stats: [
              if (silence.hasVideo) ...[
                (
                  label: context.strings.toolSource,
                  value:
                      '${silence.sourceDurationSeconds}s · '
                      '${silence.sourceWidth}×${silence.sourceHeight}',
                ),
                (
                  label: context.strings.silenceSensitivity,
                  value: silence.sensitivity < 0.34
                      ? context.strings.slGentle
                      : silence.sensitivity > 0.66
                      ? context.strings.slAggressive
                      : context.strings.cmpBalanced,
                ),
                (
                  label: context.strings.toolOutput,
                  value: '${res.width}×${res.height}',
                ),
                (
                  label: context.strings.toolSizeApprox,
                  value: formatFileSize(silence.estimatedBytes),
                ),
                (
                  label: context.strings.toolAudio,
                  value: silence.hasNewAudio
                      ? silence.newAudioName!
                      : silence.muteAudio
                      ? context.strings.audMuted
                      : context.strings.exportOriginal,
                ),
              ],
            ],
          ),
          controls: [
            Text(
              context.strings.silenceIntro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Source video
            StilloraGlassCard(
              onTap: _running ? null : controller.pickVideo,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    silence.hasVideo
                        ? Icons.movie_creation_rounded
                        : Icons.upload_file_rounded,
                    color: StilloraColors.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          silence.hasVideo
                              ? silence.videoName!
                              : context.strings.toolUploadVideo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          silence.hasVideo
                              ? '${silence.sourceDurationSeconds}s · '
                                    '${silence.sourceWidth}×${silence.sourceHeight}'
                              : context.strings.slSourceHint,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: StilloraColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (silence.hasVideo)
                    Icon(
                      Icons.refresh_rounded,
                      color: StilloraColors.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sensitivity — the silence-detection threshold. Free users get
            // automatic balanced detection; tuning it is a Pro control.
            ProControlLabel(context.strings.silenceSensitivity),
            Text(
              silence.sensitivity < 0.34
                  ? context.strings.slGentleNote
                  : silence.sensitivity > 0.66
                  ? context.strings.slAggressiveNote
                  : context.strings.cmpBalanced,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            ProLockedControl(
              child: Slider(
                value: silence.sensitivity,
                onChanged: _running ? null : controller.setSensitivity,
              ),
            ),
            const SizedBox(height: 12),

            // Speed
            Text(
              context.strings.toolSpeed,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1, label: Text('1x')),
                  ButtonSegment(value: 2, label: Text('2x')),
                  ButtonSegment(value: 3, label: Text('3x')),
                  ButtonSegment(value: 4, label: Text('4x')),
                ],
                selected: {silence.speed},
                onSelectionChanged: _running
                    ? null
                    : (v) => controller.setSpeed(v.first),
              ),
            ),
            const SizedBox(height: 12),

            // Audio
            Text(
              context.strings.toolAudio,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(context.strings.silenceRemoveAudio),
              subtitle: Text(
                silence.hasNewAudio
                    ? context.strings.audReplacedByNew
                    : context.strings.slMuteNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
              value: silence.muteAudio,
              // Forced on while a replacement track is attached.
              onChanged: _running || silence.hasNewAudio
                  ? null
                  : controller.setMuteAudio,
            ),
            const SizedBox(height: 4),
            if (!silence.hasNewAudio)
              AudioSourceButtons(
                enabled: !_running,
                onPicked: (path) => controller.setNewAudio(path),
              )
            else
              StilloraGlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: 20,
                      color: StilloraColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${context.strings.audNewAudio} · ${silence.newAudioName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: _running ? null : controller.removeNewAudio,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      tooltip: context.strings.audRemoveNewAudio,
                      color: StilloraColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            if (silence.hasNewAudio) ...[
              const SizedBox(height: 6),
              Text(
                context.strings.silenceNewAudioNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Colour correction — the graded frame lives in the preview pane.
            ColorGradeSection(
              videoPath: silence.videoPath,
              value: silence.color,
              onChanged: controller.setColor,
              enabled: !_running,
              showPreview: false,
            ),
            const SizedBox(height: 12),

            // Quality
            Text(
              context.strings.toolQuality,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            ProQualityPicker(
              selected: silence.quality,
              onSelected: controller.setQuality,
              style: ProQualityPickerStyle.segmented,
              enabled: !_running,
            ),
            const SizedBox(height: 10),
            if (silence.hasVideo)
              Text(
                '${res.width} × ${res.height}  ·  ≤ '
                '${formatFileSize(silence.estimatedBytes)}  ·  ${silence.quality.note(context.strings)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 20),

            StilloraPrimaryButton(
              onPressed: silence.hasVideo && !_running ? _run : null,
              icon: Icons.content_cut_rounded,
              label: _running
                  ? context.strings.slExporting
                  : context.strings.slExportCta,
            ),
            if (_running) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancel,
                icon: const Icon(Icons.close_rounded),
                label: Text(
                  _cancelling
                      ? context.strings.exportCancelling
                      : context.strings.exportCancel,
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
