import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/widgets/desktop_shell.dart';
import 'editor_state.dart';
import 'voice_narration_screen.dart';

class AddAudioScreen extends ConsumerStatefulWidget {
  const AddAudioScreen({super.key});

  static const routePath = '/add-audio';

  @override
  ConsumerState<AddAudioScreen> createState() => _AddAudioScreenState();
}

class _AddAudioScreenState extends ConsumerState<AddAudioScreen> {
  double _volume = 0.8;

  Future<void> _pickAudio() async {
    final result = await pickImportFiles(
      type: FileType.custom,
      allowedExtensions: Platform.isAndroid
          ? ['m4a', 'aac']
          : ['mp3', 'm4a', 'aac', 'wav'],
    );
    final path = result?.files.single.path;
    if (path != null) {
      await ref.read(editorControllerProvider.notifier).setAudioPath(path);
    }
  }

  Future<void> _openRecorder() async {
    final path = await context.push<String>(VoiceNarrationScreen.routePath);
    if (path != null && mounted) {
      await ref.read(editorControllerProvider.notifier).setNarration(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);
    final hasAudio = editor.audioPath != null;
    final hasNarration = editor.audioIsNarration && hasAudio;

    return SidebarScaffold(
      desktopTitle: 'Add Soundtrack',
      appBar: AppBar(leading: const BackButton()),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              stilloraBrandGradient.createShader(bounds),
                          child: Text(
                            'Stillora',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add Soundtrack (Optional)',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Record your voice or upload an audio file to play with '
                      'your video.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Two clear options, same as every other section: record a
                    // voice-over, or upload an audio file.
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openRecorder,
                            icon: const Icon(Icons.mic_rounded),
                            label: const Text('Record voice'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickAudio,
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Upload audio'),
                          ),
                        ),
                      ],
                    ),
                    if (hasAudio) ...[
                      const SizedBox(height: 20),
                      Text(
                        hasNarration ? 'Your Narration' : 'Selected Track',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _TrackCard(
                        audioPath: editor.audioPath!,
                        volume: _volume,
                        onVolumeChanged: (v) => setState(() => _volume = v),
                        onRemove: controller.removeAudio,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: StilloraColors.brandCyan,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your audio is secured and used only for this conversion.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: StilloraColors.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: StilloraPrimaryButton(
                  onPressed: () => context.pop(),
                  icon: Icons.check_rounded,
                  label: 'Continue',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.audioPath,
    required this.volume,
    required this.onVolumeChanged,
    required this.onRemove,
  });

  final String audioPath;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onRemove;

  String get _name {
    final slash = audioPath.lastIndexOf(RegExp(r'[/\\]'));
    return slash == -1 ? audioPath : audioPath.substring(slash + 1);
  }

  String get _ext {
    final dot = audioPath.lastIndexOf('.');
    if (dot == -1) return 'Audio';
    return audioPath.substring(dot + 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: StilloraColors.primaryContainer,
                  borderRadius: BorderRadius.circular(StilloraRadius.xl),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: StilloraColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _ext,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Waveform(seed: audioPath.hashCode),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Volume', style: Theme.of(context).textTheme.labelMedium),
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0,
                  max: 1,
                  onChanged: onVolumeChanged,
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(volume * 100).round()}%',
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final rng = Random(seed);
    const bars = 40;
    const h = 44.0;

    return SizedBox(
      height: h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(bars, (i) {
          final barH = (rng.nextDouble() * 0.7 + 0.15) * h;
          final played = i < bars * 0.3;
          return Container(
            width: 3,
            height: barH,
            decoration: BoxDecoration(
              gradient: played
                  ? LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        StilloraColors.brandMagenta,
                        StilloraColors.accent,
                      ],
                    )
                  : null,
              color: played ? null : StilloraColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
