import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/widgets/ad_widget.dart';
import '../editor/editor_state.dart' show formatFileSize;
import '../editor/video_preset.dart';
import 'silence_state.dart';

/// Standalone "Remove Silence" section: upload a video, auto-cut the silent
/// (non-speech) stretches, merge what's left, and export at a quality tier.
class SilenceView extends ConsumerStatefulWidget {
  const SilenceView({super.key});

  @override
  ConsumerState<SilenceView> createState() => _SilenceViewState();
}

class _SilenceViewState extends ConsumerState<SilenceView> {
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      final result = await ref.read(silenceControllerProvider.notifier).run();
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
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final silence = ref.watch(silenceControllerProvider);
    final controller = ref.read(silenceControllerProvider.notifier);
    final res = silence.outputResolution;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Upload a video, and Stillora removes the silent gaps where no one '
              'is speaking — then merges the rest and exports it.',
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
                          silence.hasVideo ? silence.videoName! : 'Upload video',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          silence.hasVideo
                              ? '${silence.sourceDurationSeconds}s · '
                                  '${silence.sourceWidth}×${silence.sourceHeight}'
                              : 'MP4 / MOV with speech',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: StilloraColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (silence.hasVideo)
                    const Icon(Icons.refresh_rounded,
                        color: StilloraColors.onSurfaceVariant),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sensitivity
            Text('Sensitivity', style: Theme.of(context).textTheme.labelMedium),
            Text(
              silence.sensitivity < 0.34
                  ? 'Gentle — only clear silence is cut'
                  : silence.sensitivity > 0.66
                      ? 'Aggressive — trims quiet pauses too'
                      : 'Balanced',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            Slider(
              value: silence.sensitivity,
              onChanged: _running ? null : controller.setSensitivity,
            ),
            const SizedBox(height: 12),

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
                selected: {silence.speed},
                onSelectionChanged:
                    _running ? null : (v) => controller.setSpeed(v.first),
              ),
            ),
            const SizedBox(height: 12),

            // Audio
            Text('Audio', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Remove original audio'),
              subtitle: Text(
                silence.hasNewAudio
                    ? 'Replaced by your new audio'
                    : 'Export the trimmed video with no sound',
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
            StilloraGlassCard(
              onTap: _running || silence.hasNewAudio
                  ? null
                  : controller.pickNewAudio,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.music_note_rounded,
                      size: 20, color: StilloraColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      silence.hasNewAudio
                          ? 'New audio · ${silence.newAudioName}'
                          : 'Add new audio (optional)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (silence.hasNewAudio)
                    IconButton(
                      onPressed: _running ? null : controller.removeNewAudio,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      tooltip: 'Remove new audio',
                      color: StilloraColors.onSurfaceVariant,
                    )
                  else
                    const Icon(Icons.chevron_right_rounded,
                        color: StilloraColors.onSurfaceVariant),
                ],
              ),
            ),
            if (silence.hasNewAudio) ...[
              const SizedBox(height: 6),
              Text(
                'New audio plays at normal speed; the video loops to match it.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            ],
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
                selected: {silence.quality},
                onSelectionChanged: _running
                    ? null
                    : (v) => controller.setQuality(v.first),
              ),
            ),
            const SizedBox(height: 10),
            if (silence.hasVideo)
              Text(
                '${res.width} × ${res.height}  ·  ≤ '
                '${formatFileSize(silence.estimatedBytes)}  ·  ${silence.quality.note}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 20),

            StilloraPrimaryButton(
              onPressed: silence.hasVideo && !_running ? _run : null,
              icon: Icons.content_cut_rounded,
              label: _running ? 'Removing silence…' : 'Remove silence & export',
            ),
            if (_running) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 16),
            const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
          ],
        ),
      ),
    );
  }
}
