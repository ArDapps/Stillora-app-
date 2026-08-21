import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/section_split_view.dart';
import '../editor/editor_state.dart' show formatFileSize;
import '../export/export_cancellation.dart';
import '../preview/section_video_preview.dart';
import 'compress_state.dart';

/// Standalone "Compress" section: upload a video and re-encode it to a smaller
/// MP4 (HandBrake-style). Resolution tier + optional mute drive the file size;
/// the live preview pane shows the source frame with the source size next to
/// the estimated compressed size.
class CompressView extends ConsumerStatefulWidget {
  const CompressView({super.key});

  @override
  ConsumerState<CompressView> createState() => _CompressViewState();
}

class _CompressViewState extends ConsumerState<CompressView> {
  bool _running = false;
  bool _cancelling = false;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _cancelling = false;
    });
    try {
      final result = await ref.read(compressControllerProvider.notifier).run();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? 'Nothing to export.'
                : 'Saved to Library · ${result.width}×${result.height}',
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
    await ref.read(compressControllerProvider.notifier).cancel();
  }

  @override
  Widget build(BuildContext context) {
    final compress = ref.watch(compressControllerProvider);
    final controller = ref.read(compressControllerProvider.notifier);
    final res = compress.outputResolution;
    final textTheme = Theme.of(context).textTheme;

    // Desktop: controls on the left, the source frame plus the live size
    // estimate pinned in the right-hand pane so every level change is reflected
    // immediately. Phones get the same preview at the top of the column.
    return DecoratedBox(
      decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: SectionSplitView(
          onStartOver: controller.reset,
          canStartOver: compress.hasVideo && !_running,
          previewCaption: compress.hasVideo
              ? 'Same frame, smaller file — quality drops as the level rises'
              : null,
          preview: SectionVideoPreview(
            videoPath: compress.videoPath,
            sourceWidth: compress.sourceWidth,
            sourceHeight: compress.sourceHeight,
            badge: compress.hasVideo ? compress.level.label : null,
            emptyLabel: 'Upload a video to preview it here',
            stats: [
              if (compress.hasVideo) ...[
                (
                  label: 'Before',
                  value: compress.sourceBytes > 0
                      ? '${formatFileSize(compress.sourceBytes)} · '
                            '${compress.sourceWidth}×${compress.sourceHeight}'
                      : '${compress.sourceWidth}×${compress.sourceHeight}',
                ),
                (
                  label: 'After ≈',
                  value:
                      '${formatFileSize(compress.estimatedBytes)} · '
                      '${res.width}×${res.height}',
                ),
                if (compress.savingsPercent > 0)
                  (label: 'Saving', value: '−${compress.savingsPercent}%'),
                (
                  label: 'Audio',
                  value: compress.muteAudio ? 'Dropped' : 'Kept',
                ),
              ],
            ],
          ),
          controls: [
            Text(
              'Upload a video and shrink it to a smaller MP4 at the same '
              'resolution. Stronger compression means a smaller file — pick a '
              'level and see the estimate.',
              style: textTheme.bodyMedium?.copyWith(
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
                    compress.hasVideo
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
                          compress.hasVideo
                              ? compress.videoName!
                              : 'Upload video',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          compress.hasVideo
                              ? '${compress.sourceDurationSeconds}s · '
                                    '${compress.sourceWidth}×${compress.sourceHeight}'
                                    '${compress.sourceBytes > 0 ? ' · ${formatFileSize(compress.sourceBytes)}' : ''}'
                              : 'MP4 / MOV',
                          style: textTheme.bodySmall?.copyWith(
                            color: StilloraColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (compress.hasVideo)
                    Icon(
                      Icons.refresh_rounded,
                      color: StilloraColors.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Compression strength (the file-size lever)
            Text('Compression', style: textTheme.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<CompressLevel>(
                showSelectedIcon: false,
                segments: [
                  for (final l in CompressLevel.values)
                    ButtonSegment(value: l, label: Text(l.label)),
                ],
                selected: {compress.level},
                onSelectionChanged: _running
                    ? null
                    : (v) => controller.setLevel(v.first),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              compress.level.note,
              style: textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Audio
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Mute (drop audio for a smaller file)'),
              value: compress.muteAudio,
              onChanged: _running ? null : controller.setMuteAudio,
            ),
            // The before → after estimate lives in the live preview pane, so it
            // stays visible while the compression level is being changed.
            const SizedBox(height: 20),

            StilloraPrimaryButton(
              onPressed: compress.hasVideo && !_running ? _run : null,
              icon: Icons.compress_rounded,
              label: _running ? 'Compressing…' : 'Compress & export',
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
