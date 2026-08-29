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
import 'speed_state.dart';
import '../../core/pro/pro_quality_picker.dart';
import '../../core/i18n/app_strings.dart';

/// Standalone "Speed" section: upload a video, speed it up (1x–4x), optionally
/// mute it, and optionally add a soundtrack the sped video loops to match.
class SpeedView extends ConsumerStatefulWidget {
  const SpeedView({super.key});

  @override
  ConsumerState<SpeedView> createState() => _SpeedViewState();
}

class _SpeedViewState extends ConsumerState<SpeedView> {
  bool _running = false;
  bool _cancelling = false;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _cancelling = false;
    });
    try {
      final result = await ref.read(speedControllerProvider.notifier).run();
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
    await ref.read(speedControllerProvider.notifier).cancel();
  }

  @override
  Widget build(BuildContext context) {
    final speed = ref.watch(speedControllerProvider);
    final controller = ref.read(speedControllerProvider.notifier);
    final res = speed.outputResolution;

    // On desktop the controls scroll on the left while the graded frame stays
    // pinned on the right, so speed / quality / colour edits are reflected
    // immediately without scrolling back up. On phones the same preview simply
    // sits at the top of the single column.
    return DecoratedBox(
      decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: SectionSplitView(
          onStartOver: controller.reset,
          canStartOver: speed.hasVideo && !_running,
          hasPreview: speed.hasVideo,
          previewCaption: speed.hasVideo
              ? context.strings.spPreviewCaption
              : null,
          preview: SectionVideoPreview(
            videoPath: speed.videoPath,
            sourceWidth: speed.sourceWidth,
            sourceHeight: speed.sourceHeight,
            color: speed.color,
            badge: speed.speed > 1 ? '${speed.speed}x' : null,
            emptyLabel: context.strings.spUploadToPreview,
            stats: [
              if (speed.hasVideo) ...[
                (
                  label: context.strings.toolSource,
                  value:
                      '${speed.sourceDurationSeconds}s · '
                      '${speed.sourceWidth}×${speed.sourceHeight}',
                ),
                (
                  label: context.strings.toolOutputApprox,
                  value:
                      '${speed.hasNewAudio ? speed.sourceDurationSeconds : (speed.sourceDurationSeconds / speed.speed).ceil()}s · '
                      '${res.width}×${res.height}',
                ),
                (
                  label: context.strings.toolSizeApprox,
                  value: formatFileSize(speed.estimatedBytes),
                ),
                (
                  label: context.strings.toolAudio,
                  value: speed.hasNewAudio
                      ? speed.newAudioName!
                      : speed.muteAudio
                      ? context.strings.audMuted
                      : context.strings.exportOriginal,
                ),
              ],
            ],
          ),
          controls: [
            Text(
              context.strings.speedIntro,
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
                    speed.hasVideo
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
                          speed.hasVideo
                              ? speed.videoName!
                              : context.strings.toolUploadVideo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          speed.hasVideo
                              ? '${speed.sourceDurationSeconds}s · '
                                    '${speed.sourceWidth}×${speed.sourceHeight}'
                              : 'MP4 / MOV',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: StilloraColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (speed.hasVideo)
                    Icon(
                      Icons.refresh_rounded,
                      color: StilloraColors.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
                selected: {speed.speed},
                onSelectionChanged: _running
                    ? null
                    : (v) => controller.setSpeed(v.first),
              ),
            ),
            const SizedBox(height: 6),
            if (speed.hasVideo && speed.speed > 1 && !speed.hasNewAudio)
              Text(
                '${context.strings.toolOutputApprox} '
                '${((speed.sourceDurationSeconds) / speed.speed).ceil()}s '
                '${context.strings.spAtSpeed} ${speed.speed}x',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
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
              title: Text(context.strings.speedMute),
              subtitle: Text(
                speed.hasNewAudio
                    ? context.strings.audReplacedByNew
                    : context.strings.spMuteNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
              value: speed.muteAudio,
              // Forced on while a replacement track is attached.
              onChanged: _running || speed.hasNewAudio
                  ? null
                  : controller.setMuteAudio,
            ),
            const SizedBox(height: 4),
            if (!speed.hasNewAudio)
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
                        '${context.strings.audNewAudio} · ${speed.newAudioName}',
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
            if (speed.hasNewAudio) ...[
              const SizedBox(height: 6),
              Text(
                context.strings.speedNewAudioNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Color correction (desktop) — live preview + grade the final video.
            ColorGradeSection(
              videoPath: speed.videoPath,
              value: speed.color,
              onChanged: controller.setColor,
              enabled: !_running,
              // The graded frame lives in the preview pane above/right.
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
              selected: speed.quality,
              onSelected: controller.setQuality,
              style: ProQualityPickerStyle.segmented,
              enabled: !_running,
            ),
            const SizedBox(height: 10),
            if (speed.hasVideo)
              Text(
                '${res.width} × ${res.height}  ·  ≤ '
                '${formatFileSize(speed.estimatedBytes)}  ·  ${speed.quality.note(context.strings)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 20),

            StilloraPrimaryButton(
              onPressed: speed.hasVideo && !_running ? _run : null,
              icon: Icons.fast_forward_rounded,
              label: _running
                  ? context.strings.exportExporting
                  : context.strings.spExportCta,
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
