import 'package:flutter/material.dart';

import '../../../core/format/duration_label.dart';
import '../../../core/design/render_components.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../editor_state.dart';
import 'editor_shared.dart';

class SoundscapeCard extends StatelessWidget {
  const SoundscapeCard({
    super.key,
    required this.editor,
    required this.onPickAudio,
    required this.onRecordAudio,
    required this.onRemoveAudio,
    this.compact = false,
  });

  final EditorState editor;
  final VoidCallback onPickAudio;
  final VoidCallback onRecordAudio;
  final VoidCallback onRemoveAudio;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String audioDetail;
    if (editor.audioPath == null) {
      audioDetail = supportedAudioLabel;
    } else if (editor.audioDurationSeconds == null) {
      audioDetail = editor.audioPath!;
    } else {
      audioDetail =
          '${formatDurationClock(editor.audioDurationSeconds!)} · ${editor.audioPath!}';
    }

    return RenderStepCard(
      number: '2',
      title: 'Soundscape',
      trailing: const RenderTagPill('optional'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: StilloraColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(StilloraRadius.full),
              border: Border.all(color: StilloraColors.outlineVariant),
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 10 : StilloraSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: compact ? 38 : 48,
                    height: compact ? 38 : 48,
                    decoration: BoxDecoration(
                      color: StilloraColors.primaryContainer,
                      borderRadius: BorderRadius.circular(StilloraRadius.xl),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: StilloraColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: StilloraSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editor.audioPath == null
                              ? 'Optional Audio'
                              : 'Audio Attached',
                          style:
                              (compact
                                      ? Theme.of(context).textTheme.labelLarge
                                      : Theme.of(context).textTheme.titleMedium)
                                  ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          audioDetail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: StilloraColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (editor.audioPath != null)
                    IconButton(
                      tooltip: 'Remove audio',
                      onPressed: onRemoveAudio,
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
          ),
          // When videos are in the timeline and nothing is attached, they keep
          // their own sound — make that default explicit so users don't think
          // the export is silent. Mute lives per-clip on the timeline.
          if (editor.audioPath == null && editor.hasVideos) ...[
            SizedBox(height: compact ? 6 : 10),
            Row(
              children: [
                const Icon(
                  Icons.graphic_eq_rounded,
                  size: 15,
                  color: StilloraColors.secondary,
                ),
                const SizedBox(width: StilloraSpacing.base + 2),
                Expanded(
                  child: Text(
                    editor.media.length > 1
                        ? 'Your videos keep their own sound. Add audio to '
                              'replace it, or mute a clip on the timeline.'
                        : 'Your video keeps its own sound. Add audio to '
                              'replace it, or mute it on the timeline.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StilloraColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Two clear options when nothing is attached: record a voice-over or
          // upload an audio file (same as every other section).
          if (editor.audioPath == null) ...[
            SizedBox(height: compact ? 8 : StilloraSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRecordAudio,
                    icon: const Icon(Icons.mic_rounded),
                    label: const Text('Record voice'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickAudio,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload audio'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
