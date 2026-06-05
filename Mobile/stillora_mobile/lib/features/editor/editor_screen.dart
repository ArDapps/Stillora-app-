import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../auth/login_screen.dart';
import '../export/export_progress_screen.dart';
import 'editor_state.dart';
import 'video_preset.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  static const routePath = '/editor';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: const EditorView(),
    );
  }
}

class EditorView extends ConsumerWidget {
  const EditorView({super.key});

  Future<void> _pickAudio(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav'],
    );
    final path = result?.files.single.path;
    if (path != null) {
      ref.read(editorControllerProvider.notifier).setAudioPath(path);
    }
  }

  void _convert(BuildContext context, WidgetRef ref, EditorState editor) {
    final session = ref.read(authControllerProvider).asData?.value;
    if (!editor.canExport) {
      return;
    }

    if (session == null) {
      context.go(
        '${LoginScreen.routePath}?next=${Uri.encodeComponent(ExportProgressScreen.routePath)}',
      );
      return;
    }

    context.push(ExportProgressScreen.routePath);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorControllerProvider);
    final session = ref.watch(authControllerProvider).asData?.value;
    final controller = ref.read(editorControllerProvider.notifier);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff0c0718),
            Color(0xff060611),
            Color(0xff030309),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            StilloraSpacing.mobileMargin,
            StilloraSpacing.sm,
            StilloraSpacing.mobileMargin,
            StilloraSpacing.lg,
          ),
          children: [
          const _StudioHeader(),
          const SizedBox(height: StilloraSpacing.lg),
          const _ProgressRail(),
          const SizedBox(height: StilloraSpacing.lg),
          _SourceMediaCard(editor: editor, controller: controller),
          const SizedBox(height: StilloraSpacing.sm),
          _SoundscapeCard(
            editor: editor,
            onPickAudio: () => _pickAudio(ref),
            onRemoveAudio: controller.removeAudio,
          ),
          const SizedBox(height: StilloraSpacing.sm),
          _PresetCard(editor: editor, controller: controller),
          const SizedBox(height: StilloraSpacing.sm),
          _PrivacyCard(isSignedIn: session != null),
          const SizedBox(height: StilloraSpacing.sm),
          _PreviewCard(editor: editor),
          const SizedBox(height: StilloraSpacing.sm),
          StilloraPrimaryButton(
            onPressed: editor.canExport
                ? () => _convert(context, ref, editor)
                : null,
            icon: session == null
                ? Icons.lock_rounded
                : Icons.auto_fix_high_rounded,
            label: session == null ? 'Register to Convert' : 'Convert to MP4',
          ),
        ],
        ),
      ),
    );
  }
}

class _StudioHeader extends StatelessWidget {
  const _StudioHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              stilloraBrandGradient.createShader(bounds),
          child: Text(
            'Stillora',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          'Transform static memories into social videos in three simple steps.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ProgressStep(index: '1', label: 'Upload', color: Color(0xffd946ef)),
        _ProgressLine(),
        _ProgressStep(index: '2', label: 'Audio', color: Color(0xff8b5cf6)),
        _ProgressLine(),
        _ProgressStep(index: '3', label: 'Export', color: Color(0xff22d3ee)),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.index,
    required this.label,
    required this.color,
  });

  final String index;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StilloraPulse(
          builder: (context, t) {
            return Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4 + t * 0.4),
                    blurRadius: 8 + t * 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                index,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x99d946ef), Color(0x9922d3ee)],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.editor});

  final EditorState editor;

  double get _aspectRatio {
    final preset = editor.preset;
    if (preset.width <= 0 || preset.height <= 0) {
      return 9 / 16;
    }
    return preset.width / preset.height;
  }

  @override
  Widget build(BuildContext context) {
    final media = editor.selectedMedia;
    final fitLabel = editor.resizeMode == ResizeMode.fit ? 'Fit' : 'Fill';

    return StilloraGlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.smart_display_rounded,
                color: StilloraColors.primary,
                size: 20,
              ),
              const SizedBox(width: StilloraSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MP4 Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${editor.preset.ratioLabel} · ${editor.durationSeconds}s · $fitLabel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Center(
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: StilloraColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(StilloraRadius.full),
                  border: Border.all(
                    color: StilloraColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(StilloraRadius.full),
                  child: _PreviewMedia(
                    media: media,
                    resizeMode: editor.resizeMode,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMedia extends StatelessWidget {
  const _PreviewMedia({required this.media, required this.resizeMode});

  final MediaItem? media;
  final ResizeMode resizeMode;

  @override
  Widget build(BuildContext context) {
    final item = media;
    if (item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(StilloraSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: StilloraColors.primary,
                size: 36,
              ),
              const SizedBox(height: StilloraSpacing.xs),
              Text(
                'Upload media to begin',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: StilloraSpacing.xs),
              Text(
                'The preview matches your final video frame.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (item.kind == MediaKind.image) {
      return Image.file(
        File(item.path),
        fit: resizeMode == ResizeMode.fit ? BoxFit.contain : BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: StilloraColors.primary,
            size: 44,
          ),
          const SizedBox(height: StilloraSpacing.xs),
          Text(
            'Video selected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceMediaCard extends StatelessWidget {
  const _SourceMediaCard({required this.editor, required this.controller});

  final EditorState editor;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StilloraSectionHeader(title: 'Source Media', step: 'Step 1'),
          const SizedBox(height: StilloraSpacing.sm),
          if (!editor.hasMedia)
            _MediaDropZone(onTap: controller.pickMedia)
          else ...[
            _MediaGrid(editor: editor, controller: controller),
            const SizedBox(height: StilloraSpacing.sm),
            Text(
              'Selected ${editor.media.length} item${editor.media.length == 1 ? '' : 's'}. The highlighted one is exported.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: StilloraSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.addMedia,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add more'),
                  ),
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickMedia,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Replace'),
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

class _MediaDropZone extends StatelessWidget {
  const _MediaDropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StilloraRadius.full),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: StilloraColors.surfaceContainerLowest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            border: Border.all(
              color: StilloraColors.outlineVariant,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(StilloraSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.perm_media_rounded,
                    color: StilloraColors.primary,
                    size: 48,
                  ),
                  const SizedBox(height: StilloraSpacing.xs),
                  Text(
                    'Choose photos or videos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: StilloraSpacing.xs),
                  Text(
                    'Select multiple — images, videos, or a mix.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: StilloraColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.editor, required this.controller});

  final EditorState editor;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: StilloraSpacing.xs,
        crossAxisSpacing: StilloraSpacing.xs,
      ),
      itemCount: editor.media.length,
      itemBuilder: (context, index) {
        final item = editor.media[index];
        return _MediaThumb(
          item: item,
          selected: index == editor.selectedIndex,
          onTap: () => controller.selectMedia(index),
          onRemove: () => controller.removeMediaAt(index),
        );
      },
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final MediaItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(StilloraRadius.full);
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? StilloraColors.primary
                    : StilloraColors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: item.kind == MediaKind.image
                  ? Image.file(File(item.path), fit: BoxFit.cover)
                  : ColoredBox(
                      color: StilloraColors.surfaceContainerLowest,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          color: StilloraColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (item.kind == MediaKind.video)
          const Positioned(
            left: 4,
            bottom: 4,
            child: Icon(
              Icons.videocam_rounded,
              size: 16,
              color: StilloraColors.onSurface,
            ),
          ),
        if (selected)
          const Positioned(
            left: 4,
            top: 4,
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: StilloraColors.primary,
            ),
          ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: StilloraColors.surfaceContainerLowest.withValues(
                  alpha: 0.7,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: StilloraColors.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SoundscapeCard extends StatelessWidget {
  const _SoundscapeCard({
    required this.editor,
    required this.onPickAudio,
    required this.onRemoveAudio,
  });

  final EditorState editor;
  final VoidCallback onPickAudio;
  final VoidCallback onRemoveAudio;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StilloraSectionHeader(
            title: 'Soundscape',
            step: 'Optional',
            subtitle: 'Add a soundtrack — this step is optional.',
          ),
          const SizedBox(height: StilloraSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: StilloraColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(StilloraRadius.full),
              border: Border.all(color: StilloraColors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(StilloraSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          editor.audioPath ?? 'MP3, M4A, AAC, or WAV',
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
                  IconButton(
                    tooltip: editor.audioPath == null
                        ? 'Add audio'
                        : 'Remove audio',
                    onPressed: editor.audioPath == null
                        ? onPickAudio
                        : onRemoveAudio,
                    icon: Icon(
                      editor.audioPath == null
                          ? Icons.add_circle_outline_rounded
                          : Icons.close_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.editor, required this.controller});

  final EditorState editor;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StilloraSectionHeader(title: 'Presets', step: 'Step 3'),
          const SizedBox(height: StilloraSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: StilloraSpacing.xs,
              crossAxisSpacing: StilloraSpacing.xs,
              childAspectRatio: 1.45,
            ),
            itemCount: videoPresets.length,
            itemBuilder: (context, index) {
              final preset = videoPresets[index];
              final selected = editor.preset == preset;
              return StilloraGlassCard(
                selected: selected,
                onTap: () => controller.setPreset(preset),
                padding: const EdgeInsets.all(StilloraSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.movie_filter_rounded,
                      color: selected
                          ? StilloraColors.primary
                          : StilloraColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: StilloraSpacing.xs),
                    Text(
                      preset.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected
                            ? StilloraColors.primary
                            : StilloraColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      preset.ratioLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text('Resize', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: StilloraSpacing.xs),
          SegmentedButton<ResizeMode>(
            segments: const [
              ButtonSegment(
                value: ResizeMode.fit,
                icon: Icon(Icons.fit_screen_rounded),
                label: Text('Fit'),
              ),
              ButtonSegment(
                value: ResizeMode.fill,
                icon: Icon(Icons.fullscreen_rounded),
                label: Text('Fill'),
              ),
            ],
            selected: {editor.resizeMode},
            onSelectionChanged: (value) =>
                controller.setResizeMode(value.first),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text('Duration', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: StilloraSpacing.xs),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 10, label: Text('10s')),
              ButtonSegment(value: 30, label: Text('30s')),
            ],
            selected: {editor.durationSeconds},
            onSelectionChanged: (value) => controller.setDuration(value.first),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.isSignedIn});

  final bool isSignedIn;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      child: Row(
        children: [
          Icon(
            isSignedIn ? Icons.verified_user_rounded : Icons.lock_rounded,
            color: StilloraColors.secondary,
          ),
          const SizedBox(width: StilloraSpacing.sm),
          Expanded(
            child: Text(
              isSignedIn
                  ? 'Ready to convert locally. Media files stay on your phone.'
                  : 'Explore freely. Register only when you convert.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
