import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/platform/platform_info.dart';
import '../auth/login_screen.dart';
import '../export/export_progress_screen.dart';
import 'editor_state.dart';
import 'video_preset.dart';

const _standardAudioExtensions = ['mp3', 'm4a', 'aac', 'wav'];
const _androidAudioExtensions = ['m4a', 'aac'];

List<String> get _supportedAudioExtensions =>
    Platform.isAndroid ? _androidAudioExtensions : _standardAudioExtensions;

String get _supportedAudioLabel =>
    Platform.isAndroid ? 'M4A or AAC' : 'MP3, M4A, AAC, or WAV';

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
      allowedExtensions: _supportedAudioExtensions,
    );
    final path = result?.files.single.path;
    if (path != null) {
      await ref.read(editorControllerProvider.notifier).setAudioPath(path);
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
    final isDesktop = useDesktopLayout(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff0c0718), Color(0xff060611), Color(0xff030309)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: isDesktop
            ? _DesktopEditorWorkspace(
                editor: editor,
                session: session,
                controller: controller,
                onPickAudio: () => _pickAudio(ref),
                onConvert: () => _convert(context, ref, editor),
              )
            : _MobileEditorFlow(
                editor: editor,
                session: session,
                controller: controller,
                onPickAudio: () => _pickAudio(ref),
                onConvert: () => _convert(context, ref, editor),
              ),
      ),
    );
  }
}

class _MobileEditorFlow extends StatelessWidget {
  const _MobileEditorFlow({
    required this.editor,
    required this.session,
    required this.controller,
    required this.onPickAudio,
    required this.onConvert,
  });

  final EditorState editor;
  final Object? session;
  final EditorController controller;
  final VoidCallback onPickAudio;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    return ListView(
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
          onPickAudio: onPickAudio,
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
          onPressed: editor.canExport ? onConvert : null,
          icon: session == null
              ? Icons.lock_rounded
              : Icons.auto_fix_high_rounded,
          label: session == null ? 'Register to Convert' : 'Convert to MP4',
        ),
      ],
    );
  }
}

class _DesktopEditorWorkspace extends StatelessWidget {
  const _DesktopEditorWorkspace({
    required this.editor,
    required this.session,
    required this.controller,
    required this.onPickAudio,
    required this.onConvert,
  });

  final EditorState editor;
  final Object? session;
  final EditorController controller;
  final VoidCallback onPickAudio;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewWidth = constraints.maxWidth >= 1220 ? 460.0 : 400.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            StilloraSpacing.md,
            0,
            StilloraSpacing.md,
            StilloraSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: StilloraSpacing.lg),
                  children: [
                    const _DesktopStudioHeader(),
                    const SizedBox(height: StilloraSpacing.md),
                    _SourceMediaCard(editor: editor, controller: controller),
                    const SizedBox(height: StilloraSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _SoundscapeCard(
                            editor: editor,
                            onPickAudio: onPickAudio,
                            onRemoveAudio: controller.removeAudio,
                          ),
                        ),
                        const SizedBox(width: StilloraSpacing.sm),
                        Expanded(
                          child: _PrivacyCard(isSignedIn: session != null),
                        ),
                      ],
                    ),
                    const SizedBox(height: StilloraSpacing.sm),
                    _PresetCard(editor: editor, controller: controller),
                  ],
                ),
              ),
              const SizedBox(width: StilloraSpacing.md),
              SizedBox(
                width: previewWidth,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: StilloraSpacing.lg),
                  children: [
                    _DesktopExportPanel(
                      editor: editor,
                      isSignedIn: session != null,
                      onConvert: onConvert,
                    ),
                    const SizedBox(height: StilloraSpacing.sm),
                    _PreviewCard(
                      editor: editor,
                      maxPreviewHeight: 440,
                      maxPreviewWidth: previewWidth,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopStudioHeader extends StatelessWidget {
  const _DesktopStudioHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    stilloraBrandGradient.createShader(bounds),
                child: Text(
                  'Stillora Desktop Studio',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: StilloraSpacing.xs),
              Text(
                'Build a local MP4 timeline with desktop file picking and a wider control surface.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: StilloraSpacing.md),
        const _ProgressRail(),
      ],
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
  const _PreviewCard({
    required this.editor,
    this.maxPreviewHeight = 320,
    this.maxPreviewWidth = 420,
  });

  final EditorState editor;
  final double maxPreviewHeight;
  final double maxPreviewWidth;

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
                      '${editor.preset.ratioLabel} · ${editor.totalDurationSeconds}s · $fitLabel',
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxPreviewHeight,
                maxWidth: maxPreviewWidth,
              ),
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
          ),
        ],
      ),
    );
  }
}

class _DesktopExportPanel extends StatelessWidget {
  const _DesktopExportPanel({
    required this.editor,
    required this.isSignedIn,
    required this.onConvert,
  });

  final EditorState editor;
  final bool isSignedIn;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    return StilloraGlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: stilloraBrandGradient,
                  borderRadius: BorderRadius.circular(StilloraRadius.full),
                ),
                child: const Icon(
                  Icons.movie_creation_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: StilloraSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editor.canExport ? 'Ready to export' : 'Set up export',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      editor.canExport
                          ? 'Review the desktop preview before converting.'
                          : 'Choose media to unlock conversion.',
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
          _DesktopExportStat(
            icon: Icons.perm_media_rounded,
            label: 'Assets',
            value: editor.media.isEmpty
                ? 'None selected'
                : '${editor.media.length} item${editor.media.length == 1 ? '' : 's'}',
          ),
          _DesktopExportStat(
            icon: Icons.aspect_ratio_rounded,
            label: 'Preset',
            value: '${editor.preset.label} · ${editor.preset.ratioLabel}',
          ),
          _DesktopExportStat(
            icon: Icons.timer_rounded,
            label: 'Duration',
            value: _formatDuration(editor.totalDurationSeconds),
          ),
          _DesktopExportStat(
            icon: isSignedIn ? Icons.verified_user_rounded : Icons.lock_rounded,
            label: 'Account',
            value: isSignedIn ? 'Signed in' : 'Sign in on export',
          ),
          const SizedBox(height: StilloraSpacing.sm),
          StilloraPrimaryButton(
            onPressed: editor.canExport ? onConvert : null,
            icon: isSignedIn ? Icons.auto_fix_high_rounded : Icons.lock_rounded,
            label: isSignedIn ? 'Convert to MP4' : 'Register to Convert',
          ),
        ],
      ),
    );
  }
}

class _DesktopExportStat extends StatelessWidget {
  const _DesktopExportStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StilloraSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StilloraColors.surfaceContainerLow.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(StilloraRadius.full),
          border: Border.all(color: StilloraColors.glassStroke),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StilloraSpacing.sm,
            vertical: StilloraSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: StilloraColors.primary),
              const SizedBox(width: StilloraSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: StilloraSpacing.xs),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            _MediaTimeline(editor: editor, controller: controller),
            const SizedBox(height: StilloraSpacing.sm),
            Text(
              _mediaSummary(editor),
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

  String _mediaSummary(EditorState editor) {
    final totalCount = editor.media.length;
    final totalDuration = _formatDuration(editor.totalDurationSeconds);
    if (editor.exportsMixedTimeline) {
      return '$totalCount assets · $totalDuration total. Tap a clip’s time to trim it, drag to reorder.';
    }
    if (editor.exportsImageSlideshow && totalCount > 1) {
      return '$totalCount images · $totalDuration total. Tap a clip’s time to trim it, drag to reorder.';
    }
    if (editor.exportsVideoSource) {
      return 'Selected video exports as a $totalDuration MP4. Tap the clip time to change its length.';
    }
    return 'Selected $totalCount item${totalCount == 1 ? '' : 's'} · $totalDuration total.';
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
                    'Select photos and videos, then drag to reorder.',
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

class _MediaTimeline extends StatelessWidget {
  const _MediaTimeline({required this.editor, required this.controller});

  final EditorState editor;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, _, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + animation.value * 0.04,
                child: Material(color: Colors.transparent, child: child),
              );
            },
            child: child,
          );
        },
        onReorder: controller.reorderMedia,
        itemCount: editor.media.length,
        itemBuilder: (context, index) {
          final item = editor.media[index];
          return Padding(
            key: ValueKey(item.path),
            padding: const EdgeInsets.only(right: StilloraSpacing.xs),
            child: SizedBox(
              width: 96,
              child: _MediaThumb(
                index: index,
                item: item,
                durationLabel: _formatDuration(item.durationSeconds),
                selected: index == editor.selectedIndex,
                onTap: () => controller.selectMedia(index),
                onRemove: () => controller.removeMediaAt(index),
                onEditDuration: () => _editClipDuration(context, index, item),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editClipDuration(
    BuildContext context,
    int index,
    MediaItem item,
  ) async {
    controller.selectMedia(index);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StilloraColors.surfaceContainerLow,
      showDragHandle: true,
      builder: (sheetContext) => _ClipDurationSheet(
        clipNumber: index + 1,
        isVideo: item.kind == MediaKind.video,
        initialSeconds: item.durationSeconds,
        onChanged: (seconds) => controller.setClipDuration(index, seconds),
      ),
    );
  }
}

/// Bottom sheet that edits a single clip's duration. Every change is applied
/// live so the timeline and preview update behind the sheet.
class _ClipDurationSheet extends StatefulWidget {
  const _ClipDurationSheet({
    required this.clipNumber,
    required this.isVideo,
    required this.initialSeconds,
    required this.onChanged,
  });

  final int clipNumber;
  final bool isVideo;
  final int initialSeconds;
  final ValueChanged<int> onChanged;

  @override
  State<_ClipDurationSheet> createState() => _ClipDurationSheetState();
}

class _ClipDurationSheetState extends State<_ClipDurationSheet> {
  late int _seconds = widget.initialSeconds;

  // A 60s ceiling keeps a single clip's slider usable; the typed field still
  // accepts longer values up to the engine limit.
  static const _sliderMax = 60;
  static const _quickPicks = [1, 2, 3, 5, 10, 15, 30];

  void _set(int seconds) {
    final clamped = normalizeDurationSeconds(seconds);
    setState(() => _seconds = clamped);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        StilloraSpacing.md,
        0,
        StilloraSpacing.md,
        StilloraSpacing.md + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.isVideo ? 'Video' : 'Photo'} ${widget.clipNumber} duration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: StilloraSpacing.xs),
          Text(
            'Set how long this clip plays in the final video.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Wrap(
            spacing: StilloraSpacing.xs,
            runSpacing: StilloraSpacing.xs,
            children: [
              for (final pick in _quickPicks)
                _DurationChip(
                  label: '${pick}s',
                  selected: _seconds == pick,
                  onSelected: () => _set(pick),
                ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Shorter',
                onPressed: () => _set(_seconds - 1),
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Slider(
                  value: _seconds
                      .clamp(minDurationSeconds, _sliderMax)
                      .toDouble(),
                  min: minDurationSeconds.toDouble(),
                  max: _sliderMax.toDouble(),
                  divisions: _sliderMax - minDurationSeconds,
                  label: '${_seconds}s',
                  onChanged: (value) => _set(value.round()),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Longer',
                onPressed: () => _set(_seconds + 1),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          Center(
            child: Text(
              '${_seconds}s',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          StilloraPrimaryButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.check_rounded,
            label: 'Done',
          ),
        ],
      ),
    );
  }
}

class _TimelineBadge extends StatelessWidget {
  const _TimelineBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: stilloraBrandGradient,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: SizedBox.square(
        dimension: 22,
        child: Center(
          child: Text(
            '${index + 1}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({
    required this.index,
    required this.item,
    required this.durationLabel,
    required this.selected,
    required this.onTap,
    required this.onRemove,
    required this.onEditDuration,
  });

  final int index;
  final MediaItem item;
  final String durationLabel;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onEditDuration;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(StilloraRadius.full);
    final durationForeground = selected
        ? Colors.white
        : StilloraColors.onSurfaceVariant;

    return Column(
      children: [
        Expanded(
          child: Stack(
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
                  right: 4,
                  bottom: 4,
                  child: Icon(
                    Icons.videocam_rounded,
                    size: 16,
                    color: StilloraColors.onSurface,
                  ),
                ),
              Positioned(
                left: 4,
                bottom: 4,
                child: _TimelineBadge(index: index),
              ),
              Positioned(
                right: 4,
                top: 30,
                child: ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: StilloraColors.surfaceContainerLowest.withValues(
                        alpha: 0.75,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.drag_indicator_rounded,
                      size: 16,
                      color: StilloraColors.onSurface,
                    ),
                  ),
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
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEditDuration,
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                gradient: selected ? stilloraBrandGradient : null,
                color: selected
                    ? null
                    : StilloraColors.surfaceContainerLowest.withValues(
                        alpha: 0.8,
                      ),
                borderRadius: BorderRadius.circular(StilloraRadius.full),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.24)
                      : StilloraColors.glassStroke,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: durationForeground,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      durationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: durationForeground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.edit_rounded, size: 11, color: durationForeground),
                ],
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
    final String audioDetail;
    if (editor.audioPath == null) {
      audioDetail = _supportedAudioLabel;
    } else if (editor.audioDurationSeconds == null) {
      audioDetail = editor.audioPath!;
    } else {
      audioDetail =
          '${_formatDuration(editor.audioDurationSeconds!)} · ${editor.audioPath!}';
    }

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
                    FaIcon(
                      preset.icon,
                      size: 22,
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
          Text(
            editor.media.length > 1 ? 'Total duration' : 'Duration',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (editor.media.length > 1) ...[
            const SizedBox(height: 2),
            Text(
              'Splits evenly across all clips. Tap a clip above to set its own time.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: StilloraSpacing.xs),
          Wrap(
            spacing: StilloraSpacing.xs,
            runSpacing: StilloraSpacing.xs,
            children: [
              _DurationChip(
                label: '10s',
                selected: editor.totalDurationSeconds == 10,
                onSelected: () => controller.setDuration(10),
              ),
              _DurationChip(
                label: '30s',
                selected: editor.totalDurationSeconds == 30,
                onSelected: () => controller.setDuration(30),
              ),
              if (editor.audioDurationSeconds != null)
                _DurationChip(
                  label:
                      'Use audio ${_formatDuration(editor.audioDurationSeconds!)}',
                  selected:
                      editor.totalDurationSeconds ==
                      editor.audioDurationSeconds,
                  onSelected: () =>
                      controller.setDuration(editor.audioDurationSeconds!),
                ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.xs),
          Slider(
            value: editor.totalDurationSeconds
                .clamp(minDurationSeconds, maxDurationSeconds)
                .toDouble(),
            min: minDurationSeconds.toDouble(),
            max: maxDurationSeconds.toDouble(),
            divisions: maxDurationSeconds - minDurationSeconds,
            label: _formatDuration(editor.totalDurationSeconds),
            onChanged: (value) => controller.setDuration(value.round()),
          ),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Shorter',
                onPressed: () =>
                    controller.setDuration(editor.totalDurationSeconds - 1),
                icon: const Icon(Icons.remove_rounded),
              ),
              const SizedBox(width: StilloraSpacing.xs),
              Expanded(
                child: TextFormField(
                  key: ValueKey('duration-${editor.totalDurationSeconds}'),
                  initialValue: editor.totalDurationSeconds.toString(),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    isDense: true,
                    suffixText: 's',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    final seconds = int.tryParse(value);
                    if (seconds != null) {
                      controller.setDuration(seconds);
                    }
                  },
                ),
              ),
              const SizedBox(width: StilloraSpacing.xs),
              IconButton.filledTonal(
                tooltip: 'Longer',
                onPressed: () =>
                    controller.setDuration(editor.totalDurationSeconds + 1),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(StilloraRadius.full);
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: selected ? Colors.white : StilloraColors.onSurfaceVariant,
      fontWeight: FontWeight.w800,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected ? stilloraBrandGradient : null,
            color: selected ? null : StilloraColors.surfaceContainerLow,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.28)
                  : StilloraColors.outlineVariant,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xff8b5cf6).withValues(alpha: 0.42),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('selected'),
                          color: Colors.white,
                          size: 18,
                        )
                      : Icon(
                          Icons.radio_button_unchecked_rounded,
                          key: const ValueKey('unselected'),
                          color: StilloraColors.onSurfaceVariant.withValues(
                            alpha: 0.78,
                          ),
                          size: 18,
                        ),
                ),
                const SizedBox(width: 7),
                Text(label, style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  if (minutes == 0) {
    return '${seconds}s';
  }
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
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
                  ? 'Ready to convert. Media files stay on your phone.'
                  : 'Explore freely. Register only when you convert.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
