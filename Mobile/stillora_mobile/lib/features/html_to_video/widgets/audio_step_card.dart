import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/design/render_components.dart';
import '../../audio/audio_source.dart';

/// Step 5: the optional soundtrack / voice-over muxed onto the render.
class AudioStepCard extends StatelessWidget {
  const AudioStepCard({
    super.key,
    required this.audioName,
    required this.hasAudio,
    required this.converting,
    required this.onRemove,
    required this.onPicked,
  });

  final String? audioName;
  final bool hasAudio;
  final bool converting;
  final VoidCallback onRemove;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return RenderStepCard(
      number: '5',
      title: 'Audio',
      trailing: const RenderTagPill('optional'),
      footer:
          'Voice-over or music mixed onto the video · trimmed to its length',
      child: hasAudio
          ? Material(
              color: StilloraColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(StilloraRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(StilloraRadius.sm),
                  border: Border.all(color: StilloraColors.accent),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: 20,
                      color: StilloraColors.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        audioName ?? 'Audio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: StilloraColors.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: converting ? null : onRemove,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      tooltip: 'Remove audio',
                      color: StilloraColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            )
          : AudioSourceButtons(enabled: !converting, onPicked: onPicked),
    );
  }
}
