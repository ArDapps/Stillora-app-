import 'package:flutter/material.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_glow.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/design/stillora_surface.dart';
import '../../../core/i18n/app_strings.dart';

class VoiceNarrationPrivacyNote extends StatelessWidget {
  const VoiceNarrationPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StilloraColors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(StilloraRadius.xl),
        border: Border.all(color: StilloraColors.glassStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.lock_rounded, color: StilloraColors.brandCyan, size: 20),
            const SizedBox(width: StilloraSpacing.sm),
            Expanded(
              child: Text(
                'Your recording stays on your device and is used only to create '
                'your video.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceNarrationPermissionDenied extends StatelessWidget {
  const VoiceNarrationPermissionDenied({
    super.key,
    required this.onOpenSettings,
  });

  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      child: Column(
        children: [
          Icon(Icons.mic_off_rounded, color: StilloraColors.error, size: 44),
          const SizedBox(height: StilloraSpacing.sm),
          Text(
            context.strings.edMicOff,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: StilloraSpacing.xs),
          Text(
            'Stillora needs microphone access to record your narration. Turn it '
            'on in Settings, then come back to record.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          StilloraPrimaryButton(
            onPressed: () => onOpenSettings(),
            icon: Icons.settings_rounded,
            label: context.strings.edOpenSettings,
          ),
        ],
      ),
    );
  }
}

class VoiceNarrationMicCircle extends StatelessWidget {
  const VoiceNarrationMicCircle({
    super.key,
    required this.active,
    this.level = 0,
  });

  final bool active;

  /// Live input level (0..1); the circle and its glow swell with the voice.
  final double level;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StilloraPulse(
        builder: (context, t) {
          final glow = active ? t : 0.0;
          final voice = active ? level : 0.0;
          return AnimatedScale(
            scale: 1 + voice * 0.12,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: 132,
              height: 132,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: stilloraBrandGradient,
                boxShadow: [
                  BoxShadow(
                    color: StilloraColors.brandMagenta.withValues(
                      alpha: 0.25 + glow * 0.25 + voice * 0.4,
                    ),
                    blurRadius: 28 + glow * 18 + voice * 30,
                    spreadRadius: 2 + voice * 6,
                  ),
                ],
              ),
              child: Icon(
                active ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A live audio waveform driven by the recorder's amplitude. Each bar animates
/// to its target height so the row ripples as the user speaks.
class VoiceNarrationWaveMeter extends StatelessWidget {
  const VoiceNarrationWaveMeter({
    super.key,
    required this.levels,
    required this.active,
  });

  final List<double> levels;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const maxHeight = 64.0;
    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < levels.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: 4,
              height: (8 + levels[i] * (maxHeight - 8)).clamp(4.0, maxHeight),
              decoration: BoxDecoration(
                gradient: active ? stilloraBrandGradient : null,
                color: active
                    ? null
                    : StilloraColors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

/// Playback + actions shown once a narration take has been recorded.
class VoiceNarrationRecordedPanel extends StatelessWidget {
  const VoiceNarrationRecordedPanel({
    super.key,
    required this.isPlaying,
    required this.durationLabel,
    required this.onTogglePlayback,
    required this.onUse,
    required this.onReRecord,
    required this.onRemove,
  });

  final bool isPlaying;
  final String durationLabel;
  final VoidCallback onTogglePlayback;
  final VoidCallback onUse;
  final VoidCallback onReRecord;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StilloraGlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton.filled(
                    onPressed: onTogglePlayback,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  const SizedBox(width: StilloraSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.strings.edYourNarration,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Duration $durationLabel',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: StilloraColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: StilloraSpacing.sm),
        StilloraPrimaryButton(
          onPressed: onUse,
          icon: Icons.check_rounded,
          label: context.strings.edUseRecording,
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReRecord,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.strings.edReRecord),
              ),
            ),
            const SizedBox(width: StilloraSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(context.strings.edRemoveAudio),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
