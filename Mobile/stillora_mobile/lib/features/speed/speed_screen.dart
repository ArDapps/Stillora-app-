import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/section_split_view.dart';
import '../audio/audio_source.dart';
import '../color/color_grade_section.dart';
import '../editor/editor_state.dart' show formatFileSize;
import '../editor/video_preset.dart';
import '../export/export_cancellation.dart';
import '../preview/section_video_preview.dart';
import 'speed_state.dart';

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
                ? 'Nothing to export.'
                : 'Saved to Library · ${result.durationSeconds}s '
                      '(${result.width}×${result.height})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isExportCancellation(e) ? 'Export cancelled' : 'Failed: $e',
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
          previewCaption: speed.hasVideo
              ? 'How the exported video will look'
              : null,
          preview: SectionVideoPreview(
            videoPath: speed.videoPath,
            sourceWidth: speed.sourceWidth,
            sourceHeight: speed.sourceHeight,
            color: speed.color,
            badge: speed.speed > 1 ? '${speed.speed}x' : null,
            emptyLabel: 'Upload a video to preview the speed-up here',
            stats: [
              if (speed.hasVideo) ...[
                (
                  label: 'Source',
                  value:
                      '${speed.sourceDurationSeconds}s · '
                      '${speed.sourceWidth}×${speed.sourceHeight}',
                ),
                (
                  label: 'Output ≈',
                  value:
                      '${speed.hasNewAudio ? speed.sourceDurationSeconds : (speed.sourceDurationSeconds / speed.speed).ceil()}s · '
                      '${res.width}×${res.height}',
                ),
                (label: 'Size ≈', value: formatFileSize(speed.estimatedBytes)),
                (
                  label: 'Audio',
                  value: speed.hasNewAudio
                      ? speed.newAudioName!
                      : speed.muteAudio
                      ? 'Muted'
                      : 'Original',
                ),
              ],
            ],
          ),
          controls: [
            Text(
              'Upload a video and speed it up. Add a soundtrack and the sped '
              'video loops to match the audio length.',
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
                          speed.hasVideo ? speed.videoName! : 'Upload video',
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
            Text('Speed', style: Theme.of(context).textTheme.labelMedium),
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
                'Output ≈ ${((speed.sourceDurationSeconds) / speed.speed).ceil()}s '
                'at ${speed.speed}x',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),

            // Audio
            Text('Audio', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Mute (remove original audio)'),
              subtitle: Text(
                speed.hasNewAudio
                    ? 'Replaced by your new audio'
                    : 'Export the sped video with no sound',
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
                        'New audio · ${speed.newAudioName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: _running ? null : controller.removeNewAudio,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      tooltip: 'Remove new audio',
                      color: StilloraColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            if (speed.hasNewAudio) ...[
              const SizedBox(height: 6),
              Text(
                'New audio plays at normal speed; the sped video loops to match it.',
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
            Text('Quality', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ExportQuality>(
                showSelectedIcon: false,
                segments: [
                  for (final q in ExportQuality.values)
                    ButtonSegment(value: q, label: Text(q.label)),
                ],
                selected: {speed.quality},
                onSelectionChanged: _running
                    ? null
                    : (v) => controller.setQuality(v.first),
              ),
            ),
            const SizedBox(height: 10),
            if (speed.hasVideo)
              Text(
                '${res.width} × ${res.height}  ·  ≤ '
                '${formatFileSize(speed.estimatedBytes)}  ·  ${speed.quality.note}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 20),

            StilloraPrimaryButton(
              onPressed: speed.hasVideo && !_running ? _run : null,
              icon: Icons.fast_forward_rounded,
              label: _running ? 'Exporting…' : 'Speed up & export',
            ),
            if (_running) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancel,
                icon: const Icon(Icons.close_rounded),
                label: Text(_cancelling ? 'Cancelling…' : 'Cancel export'),
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
