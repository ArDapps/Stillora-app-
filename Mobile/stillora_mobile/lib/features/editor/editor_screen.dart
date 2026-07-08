import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/design/render_components.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/widgets/seconds_input_field.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/platform/platform_info.dart';
import 'add_audio_screen.dart';
import 'choose_preset_screen.dart';
import 'editor_state.dart';
import 'pre_export_preview_screen.dart';
import 'video_styles.dart';
import 'upload_media_screen.dart';
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
    final result = await pickImportFiles(
      type: FileType.custom,
      allowedExtensions: _supportedAudioExtensions,
    );
    final path = result?.files.single.path;
    if (path != null) {
      await ref.read(editorControllerProvider.notifier).setAudioPath(path);
    }
  }

  void _convert(BuildContext context, WidgetRef ref, EditorState editor) {
    // Basic image-to-video creation is available to everyone, signed in or not.
    // Guests can pick media, preview, export, save and share without an account;
    // only account-based features (e.g. Voice Narration) prompt for sign-in.
    if (!editor.canExport) {
      return;
    }

    context.push(PreExportPreviewScreen.routePath);
  }

  Future<void> _confirmReset(
    BuildContext context,
    EditorController controller,
  ) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text(
          'This clears your media, audio, and settings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (shouldReset == true) {
      controller.reset();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorControllerProvider);
    final session = ref.watch(authControllerProvider).asData?.value;
    final controller = ref.read(editorControllerProvider.notifier);
    final isDesktop = useDesktopLayout(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: stilloraBackgroundGradient,
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
                onReset: () => _confirmReset(context, controller),
              )
            : _MobileEditorFlow(
                editor: editor,
                session: session,
                controller: controller,
                onPickAudio: () => _pickAudio(ref),
                onConvert: () => _convert(context, ref, editor),
                onReset: () => _confirmReset(context, controller),
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
    required this.onReset,
  });

  final EditorState editor;
  final Object? session;
  final EditorController controller;
  final VoidCallback onPickAudio;
  final VoidCallback onConvert;
  final VoidCallback onReset;

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
        if (_canReset(editor)) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Start over'),
            ),
          ),
          const SizedBox(height: StilloraSpacing.xs),
        ],
        // Main preview card – tap empty state to upload
        _MobilePreviewPanel(editor: editor, controller: controller),
        const SizedBox(height: StilloraSpacing.sm),
        // Step rows: audio and preset
        _StepRow(
          icon: editor.audioIsNarration
              ? Icons.mic_rounded
              : Icons.music_note_rounded,
          label: editor.audioPath == null
              ? 'Add Soundtrack'
              : editor.audioIsNarration
              ? 'Voice narration'
              : _audioName(editor.audioPath!),
          subtitle: editor.audioPath == null
              ? 'Soundtrack or voice narration'
              : 'Tap to change',
          onTap: () => context.push(AddAudioScreen.routePath),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        _StepRow(
          icon: Icons.aspect_ratio_rounded,
          label: 'Choose Preset',
          subtitle: '${editor.preset.label} · ${editor.preset.ratioLabel}',
          onTap: () => context.push(ChoosePresetScreen.routePath),
        ),
        const SizedBox(height: StilloraSpacing.sm),
        _StyleCard(editor: editor, controller: controller),
        const SizedBox(height: StilloraSpacing.sm),
        _PrivacyCard(isSignedIn: session != null),
        const SizedBox(height: StilloraSpacing.sm),
        StilloraPrimaryButton(
          onPressed: editor.canExport ? onConvert : null,
          icon: Icons.auto_fix_high_rounded,
          label: 'Create MP4',
        ),
      ],
    );
  }

  static String _audioName(String path) {
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    final name = slash == -1 ? path : path.substring(slash + 1);
    final dot = name.lastIndexOf('.');
    return dot == -1 ? name : name.substring(0, dot);
  }
}

/// Compact step row used on the main mobile screen for audio + preset.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: StilloraColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: StilloraColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Effect + transition pickers shown on the main Create screen so styles are
/// discoverable without opening the format sub-screen. Mirrors the same
/// controls in ChoosePresetScreen (both drive the shared editor state).
class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.editor, required this.controller});

  final EditorState editor;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 20, color: StilloraColors.primary),
              const SizedBox(width: 8),
              Text(
                'Style & effects',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StylePickerRow<ClipEffect>(
            title: 'Effect',
            values: ClipEffect.values,
            selected: editor.effect,
            labelOf: (e) => e.label,
            iconOf: (e) => e.icon,
            onSelected: controller.setEffect,
          ),
          const SizedBox(height: 14),
          StylePickerRow<FrameTransition>(
            title: 'Transition',
            values: FrameTransition.values,
            selected: editor.transition,
            labelOf: (t) => t.label,
            iconOf: (t) => t.icon,
            onSelected: controller.setTransition,
          ),
        ],
      ),
    );
  }
}

/// The main preview panel on the mobile screen.
/// Shows selected media in correct output aspect-ratio.
/// Tapping the empty state navigates to UploadMediaScreen.
/// When media is selected, shows thumbnail strip with add/replace buttons.
class _MobilePreviewPanel extends StatelessWidget {
  const _MobilePreviewPanel({required this.editor, required this.controller});

  final EditorState editor;
  final EditorController controller;

  double get _aspectRatio {
    final p = editor.preset;
    return (p.width > 0 && p.height > 0) ? p.width / p.height : 9 / 16;
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MP4 Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${editor.preset.ratioLabel} · ${editor.totalDurationSeconds}s'
                      ' · ${editor.resizeMode == ResizeMode.fit ? "Fit" : "Fill"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push(ChoosePresetScreen.routePath),
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          GestureDetector(
            onTap: editor.hasMedia
                ? null
                : () => context.push(UploadMediaScreen.routePath),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 320,
                  maxWidth: 400,
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
                      child: _PreviewStage(editor: editor),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (editor.hasMedia) ...[
            const SizedBox(height: StilloraSpacing.sm),
            _MediaTimeline(editor: editor, controller: controller),
            const SizedBox(height: StilloraSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(UploadMediaScreen.routePath),
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

class _DesktopEditorWorkspace extends StatelessWidget {
  const _DesktopEditorWorkspace({
    required this.editor,
    required this.session,
    required this.controller,
    required this.onPickAudio,
    required this.onConvert,
    required this.onReset,
  });

  final EditorState editor;
  final Object? session;
  final EditorController controller;
  final VoidCallback onPickAudio;
  final VoidCallback onConvert;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoPane = constraints.maxWidth >= 820;
        final previewWidth = constraints.maxWidth >= 1160 ? 360.0 : 328.0;
        const workspaceMaxWidth = 1120.0;
        const compact = true;

        if (!twoPane) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const _DesktopStudioHeader(),
              const SizedBox(height: 12),
              _SourceMediaCard(
                editor: editor,
                controller: controller,
                compact: compact,
              ),
              const SizedBox(height: 10),
              _SoundscapeCard(
                editor: editor,
                onPickAudio: onPickAudio,
                onRemoveAudio: controller.removeAudio,
                compact: compact,
              ),
              const SizedBox(height: 10),
              _PrivacyCard(isSignedIn: session != null, compact: compact),
              const SizedBox(height: 10),
              _PresetCard(
                editor: editor,
                controller: controller,
                compact: compact,
              ),
              const SizedBox(height: 10),
              _StyleCard(editor: editor, controller: controller),
              const SizedBox(height: 10),
              _DesktopExportPanel(
                editor: editor,
                isSignedIn: session != null,
                onConvert: onConvert,
                onReset: onReset,
                compact: compact,
              ),
              const SizedBox(height: 10),
              _PreviewCard(
                editor: editor,
                maxPreviewHeight: 320,
                maxPreviewWidth: 360,
              ),
              const SizedBox(height: 10),
              const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
            ],
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: workspaceMaxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        const _DesktopStudioHeader(),
                        const SizedBox(height: 12),
                        _SourceMediaCard(
                          editor: editor,
                          controller: controller,
                          compact: compact,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SoundscapeCard(
                                editor: editor,
                                onPickAudio: onPickAudio,
                                onRemoveAudio: controller.removeAudio,
                                compact: compact,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PrivacyCard(
                                isSignedIn: session != null,
                                compact: compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _PresetCard(
                          editor: editor,
                          controller: controller,
                          compact: compact,
                        ),
                        const SizedBox(height: 10),
                        _StyleCard(editor: editor, controller: controller),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: previewWidth,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        _DesktopExportPanel(
                          editor: editor,
                          isSignedIn: session != null,
                          onConvert: onConvert,
                          onReset: onReset,
                          compact: compact,
                        ),
                        const SizedBox(height: 10),
                        _PreviewCard(
                          editor: editor,
                          maxPreviewHeight: 360,
                          maxPreviewWidth: previewWidth,
                        ),
                        const SizedBox(height: 10),
                        const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
        SvgPicture.asset(
          'assets/logo/stillora-icon.svg',
          width: 36,
          height: 36,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    stilloraBrandGradient.createShader(bounds),
                child: Text(
                  'Stillora',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                'Desktop Studio · Build your MP4 with full file access.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const _ProgressRail(compact: true),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/logo/stillora-icon.svg',
              width: 44,
              height: 44,
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) =>
                  stilloraBrandGradient.createShader(bounds),
              child: Text(
                'Stillora',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
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
  const _ProgressRail({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ProgressStep(
          index: '1',
          label: 'Upload',
          color: StilloraColors.brandMagenta,
          compact: compact,
        ),
        _ProgressLine(compact: compact),
        _ProgressStep(
          index: '2',
          label: 'Audio',
          color: StilloraColors.accent,
          compact: compact,
        ),
        _ProgressLine(compact: compact),
        _ProgressStep(
          index: '3',
          label: 'Export',
          color: StilloraColors.brandCyan,
          compact: compact,
        ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.index,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String index;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 40.0;
    return Column(
      children: [
        StilloraPulse(
          builder: (context, t) {
            return Container(
              width: size,
              height: size,
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
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
        if (!compact) ...[
          const SizedBox(height: StilloraSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 26 : 42,
      height: 2,
      margin: EdgeInsets.only(
        bottom: compact ? 0 : 24,
        left: compact ? 6 : 8,
        right: compact ? 6 : 8,
      ),
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
                    child: _PreviewStage(editor: editor),
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
    required this.onReset,
    this.compact = false,
  });

  final EditorState editor;
  final bool isSignedIn;
  final VoidCallback onConvert;
  final VoidCallback onReset;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StilloraGlowCard(
      padding: EdgeInsets.all(compact ? 12 : StilloraSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 36 : 44,
                height: compact ? 36 : 44,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      editor.canExport
                          ? 'Review the desktop preview before converting.'
                          : 'Choose media to unlock conversion.',
                      style:
                          (compact
                                  ? Theme.of(context).textTheme.bodySmall
                                  : Theme.of(context).textTheme.bodyMedium)
                              ?.copyWith(
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
            compact: compact,
          ),
          _DesktopExportStat(
            icon: Icons.aspect_ratio_rounded,
            label: 'Preset',
            value: '${editor.preset.label} · ${editor.preset.ratioLabel}',
            compact: compact,
          ),
          _DesktopExportStat(
            icon: Icons.high_quality_rounded,
            label: 'Quality',
            value:
                '${editor.exportQuality.label} · '
                '${editor.outputResolution.width}×${editor.outputResolution.height}',
            compact: compact,
          ),
          _DesktopExportStat(
            icon: Icons.sd_storage_rounded,
            label: 'Est. size',
            value: '≈ ${formatFileSize(editor.estimatedExportBytes)}',
            compact: compact,
          ),
          _DesktopExportStat(
            icon: Icons.timer_rounded,
            label: 'Duration',
            value: _formatDuration(editor.totalDurationSeconds),
            compact: compact,
          ),
          _DesktopExportStat(
            icon: isSignedIn
                ? Icons.verified_user_rounded
                : Icons.person_outline_rounded,
            label: 'Account',
            value: isSignedIn ? 'Signed in' : 'Guest',
            compact: compact,
          ),
          SizedBox(height: compact ? 10 : StilloraSpacing.sm),
          StilloraPrimaryButton(
            onPressed: editor.canExport ? onConvert : null,
            icon: Icons.auto_fix_high_rounded,
            label: 'Convert to MP4',
          ),
          if (_canReset(editor)) ...[
            const SizedBox(height: StilloraSpacing.xs),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Start over'),
            ),
          ],
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
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

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
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : StilloraSpacing.sm,
            vertical: compact ? 6 : StilloraSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: compact ? 15 : 18,
                color: StilloraColors.primary,
              ),
              SizedBox(width: compact ? 6 : StilloraSpacing.xs),
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

/// Chooses how to render the preview: an auto-playing [SlideshowPreview] that
/// animates the transition between each image asset when there are multiple
/// images, otherwise the static [_PreviewMedia] wrapped in [StyledMedia].
class _PreviewStage extends StatelessWidget {
  const _PreviewStage({required this.editor});

  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    if (editor.exportsImageSlideshow && editor.media.length > 1) {
      return SlideshowPreview(
        media: editor.media,
        transition: editor.transition,
        effect: editor.effect,
        resizeMode: editor.resizeMode,
      );
    }
    return StyledMedia(
      effect: editor.effect,
      transition: editor.transition,
      child: _PreviewMedia(
        media: editor.selectedMedia,
        resizeMode: editor.resizeMode,
      ),
    );
  }
}

/// Auto-advancing preview of a multi-image slideshow. Each clip is shown for its
/// own duration and the selected [transition] plays on every asset-to-asset
/// handoff, so the preview reflects how the exported video moves between images.
class SlideshowPreview extends StatefulWidget {
  const SlideshowPreview({
    super.key,
    required this.media,
    required this.transition,
    required this.effect,
    required this.resizeMode,
  });

  final List<MediaItem> media;
  final FrameTransition transition;
  final ClipEffect effect;
  final ResizeMode resizeMode;

  @override
  State<SlideshowPreview> createState() => _SlideshowPreviewState();
}

class _SlideshowPreviewState extends State<SlideshowPreview> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant SlideshowPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart cycling when the clip list changes (count/order/paths or timing).
    if (!_sameClips(oldWidget.media, widget.media)) {
      _index = _index.clamp(0, widget.media.length - 1);
      _schedule();
    }
  }

  bool _sameClips(List<MediaItem> a, List<MediaItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].path != b[i].path ||
          a[i].durationSeconds != b[i].durationSeconds) {
        return false;
      }
    }
    return true;
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.media.length < 2) return;
    final index = _index.clamp(0, widget.media.length - 1);
    final secs = widget.media[index].durationSeconds.clamp(1, 60);
    _timer = Timer(Duration(seconds: secs), _advance);
  }

  void _advance() {
    if (!mounted || widget.media.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.media.length);
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return _PreviewMedia(media: null, resizeMode: widget.resizeMode);
    }
    final index = _index.clamp(0, widget.media.length - 1);
    final item = widget.media[index];
    return AnimatedSwitcher(
      duration: frameTransitionDuration(widget.transition),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          frameTransitionBuilder(widget.transition, child, animation),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          ?currentChild,
        ],
      ),
      child: KeyedSubtree(
        key: ValueKey('slide_$index@${item.path}'),
        child: EffectAnimator(
          effect: widget.effect,
          child: _PreviewMedia(media: item, resizeMode: widget.resizeMode),
        ),
      ),
    );
  }
}

class _SourceMediaCard extends StatelessWidget {
  const _SourceMediaCard({
    required this.editor,
    required this.controller,
    this.compact = false,
  });

  final EditorState editor;
  final EditorController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RenderStepCard(
      number: '1',
      title: 'Source Media',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!editor.hasMedia)
            _MediaDropZone(onTap: controller.pickMedia, compact: compact)
          else ...[
            _MediaTimeline(
              editor: editor,
              controller: controller,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : StilloraSpacing.sm),
            Text(
              _mediaSummary(editor),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: compact ? 8 : StilloraSpacing.sm),
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
  const _MediaDropZone({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: StilloraColors.surfaceContainerLowest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        border: Border.all(
          color: StilloraColors.outlineVariant,
          width: compact ? 1 : 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : StilloraSpacing.md),
          child: compact
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.perm_media_rounded,
                      color: StilloraColors.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose photos or videos',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Drag to reorder after selecting media.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: StilloraColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
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
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StilloraRadius.full),
      child: compact
          ? SizedBox(height: 116, child: content)
          : AspectRatio(aspectRatio: 1.6, child: content),
    );
  }
}

class _MediaTimeline extends StatelessWidget {
  const _MediaTimeline({
    required this.editor,
    required this.controller,
    this.compact = false,
  });

  final EditorState editor;
  final EditorController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 96 : 124,
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
              width: compact ? 76 : 96,
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
        initialVolume: item.volume,
        onChanged: (seconds) => controller.setClipDuration(index, seconds),
        onVolumeChanged: (volume) => controller.setClipVolume(index, volume),
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
    required this.initialVolume,
    required this.onChanged,
    required this.onVolumeChanged,
  });

  final int clipNumber;
  final bool isVideo;
  final int initialSeconds;
  final double initialVolume;
  final ValueChanged<int> onChanged;
  final ValueChanged<double> onVolumeChanged;

  @override
  State<_ClipDurationSheet> createState() => _ClipDurationSheetState();
}

class _ClipDurationSheetState extends State<_ClipDurationSheet> {
  late int _seconds = widget.initialSeconds;
  late double _volume = widget.initialVolume;
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialSeconds.toString());

  static const _quickPicks = [1, 3, 5, 10, 30, 60, 300, 600, 1800];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setVolume(double volume) {
    final clamped = normalizeClipVolume(volume);
    setState(() => _volume = clamped);
    widget.onVolumeChanged(clamped);
  }

  /// Applies a new duration. [syncField] keeps the text box in step when the
  /// change comes from the steppers / quick-picks; it's left false while the
  /// user is typing so the cursor doesn't jump.
  void _set(int seconds, {bool syncField = true}) {
    final clamped = normalizeDurationSeconds(seconds);
    setState(() => _seconds = clamped);
    if (syncField && _controller.text != clamped.toString()) {
      _controller.text = clamped.toString();
    }
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
                  label: _formatDuration(pick),
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
                onPressed: () =>
                    _set(_seconds - durationAdjustmentStep(_seconds)),
                icon: const Icon(Icons.remove_rounded),
              ),
              const SizedBox(width: StilloraSpacing.xs),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    isDense: true,
                    suffixText: 'seconds',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final seconds = int.tryParse(value);
                    if (seconds != null) _set(seconds, syncField: false);
                  },
                  onEditingComplete: () {
                    _set(_seconds);
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              const SizedBox(width: StilloraSpacing.xs),
              IconButton.filledTonal(
                tooltip: 'Longer',
                onPressed: () =>
                    _set(_seconds + durationAdjustmentStep(_seconds)),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (widget.isVideo) ...[
            const SizedBox(height: StilloraSpacing.md),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: _volume <= 0 ? 'Unmute' : 'Mute',
                  onPressed: () => _setVolume(_volume <= 0 ? 1.0 : 0.0),
                  icon: Icon(
                    _volume <= 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                  ),
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: Text(
                    _volume <= 0
                        ? 'Muted'
                        : 'Volume ${(_volume * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            Slider(
              value: _volume,
              min: 0,
              max: 1,
              divisions: 20,
              label: _volume <= 0 ? 'Muted' : '${(_volume * 100).round()}%',
              onChanged: _setVolume,
            ),
            Text(
              'Controls this video clip’s own sound in the export.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
          ],
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
              if (item.kind == MediaKind.video && item.isMuted)
                const Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    Icons.volume_off_rounded,
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
    this.compact = false,
  });

  final EditorState editor;
  final VoidCallback onPickAudio;
  final VoidCallback onRemoveAudio;
  final bool compact;

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
  const _PresetCard({
    required this.editor,
    required this.controller,
    this.compact = false,
  });

  final EditorState editor;
  final EditorController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RenderStepCard(
      number: '3',
      title: 'Presets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RenderTileGrid(
            tiles: [
              for (final preset in videoPresets)
                RenderSelectTile(
                  title: preset.label,
                  subtitle: preset.ratioLabel,
                  selected: editor.preset == preset,
                  onTap: () => controller.setPreset(preset),
                ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text('Resize', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: StilloraSpacing.xs),
          RenderPillSegmented(
            options: const ['Fit', 'Fill'],
            selectedIndex: editor.resizeMode == ResizeMode.fit ? 0 : 1,
            onSelected: (i) => controller.setResizeMode(
              i == 0 ? ResizeMode.fit : ResizeMode.fill,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text('Quality', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: StilloraSpacing.xs),
          RenderPillSegmented(
            options: [for (final q in ExportQuality.values) q.label],
            selectedIndex: ExportQuality.values.indexOf(editor.exportQuality),
            onSelected: (i) =>
                controller.setExportQuality(ExportQuality.values[i]),
          ),
          const SizedBox(height: 4),
          Text(
            '${editor.outputResolution.width} × ${editor.outputResolution.height}'
            '  ·  ≈ ${formatFileSize(editor.estimatedExportBytes)}'
            '  ·  ${editor.exportQuality.note}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
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
                compact: compact,
              ),
              _DurationChip(
                label: '30s',
                selected: editor.totalDurationSeconds == 30,
                onSelected: () => controller.setDuration(30),
                compact: compact,
              ),
              _DurationChip(
                label: '1 min',
                selected: editor.totalDurationSeconds == 60,
                onSelected: () => controller.setDuration(60),
                compact: compact,
              ),
              _DurationChip(
                label: '5 min',
                selected: editor.totalDurationSeconds == 300,
                onSelected: () => controller.setDuration(300),
                compact: compact,
              ),
              _DurationChip(
                label: '10 min',
                selected: editor.totalDurationSeconds == 600,
                onSelected: () => controller.setDuration(600),
                compact: compact,
              ),
              _DurationChip(
                label: '30 min',
                selected: editor.totalDurationSeconds == 1800,
                onSelected: () => controller.setDuration(1800),
                compact: compact,
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
                  compact: compact,
                ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.xs),
          SecondsInputField(
            seconds: editor.totalDurationSeconds,
            min: minDurationSeconds,
            onChanged: controller.setDuration,
          ),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Shorter',
                onPressed: () => controller.setDuration(
                  editor.totalDurationSeconds -
                      durationAdjustmentStep(editor.totalDurationSeconds),
                ),
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
                    helperText: 'Any positive duration',
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
                onPressed: () => controller.setDuration(
                  editor.totalDurationSeconds +
                      durationAdjustmentStep(editor.totalDurationSeconds),
                ),
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
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(StilloraRadius.full);
    final textStyle =
        (compact
                ? Theme.of(context).textTheme.labelMedium
                : Theme.of(context).textTheme.labelLarge)
            ?.copyWith(
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
                      color: StilloraColors.accent.withValues(alpha: 0.42),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 7 : 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey('selected'),
                          color: Colors.white,
                          size: compact ? 15 : 18,
                        )
                      : Icon(
                          Icons.radio_button_unchecked_rounded,
                          key: const ValueKey('unselected'),
                          color: StilloraColors.onSurfaceVariant.withValues(
                            alpha: 0.78,
                          ),
                          size: compact ? 15 : 18,
                        ),
                ),
                SizedBox(width: compact ? 5 : 7),
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
  final hours = seconds ~/ 3600;
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  if (hours > 0) {
    final remainingMinutes = minutes % 60;
    return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }
  if (minutes == 0) {
    return '${seconds}s';
  }
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

/// Whether the editor holds anything worth clearing (media, audio, or a
/// non-default preset/duration/resize choice).
bool _canReset(EditorState editor) =>
    editor.hasMedia ||
    editor.audioPath != null ||
    editor.preset != defaultVideoPreset ||
    editor.durationSeconds != defaultDurationSeconds ||
    editor.resizeMode != ResizeMode.fit;

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.isSignedIn, this.compact = false});

  final bool isSignedIn;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      padding: EdgeInsets.all(compact ? 12 : StilloraSpacing.sm),
      child: Row(
        children: [
          Icon(
            isSignedIn ? Icons.verified_user_rounded : Icons.lock_rounded,
            color: StilloraColors.secondary,
            size: compact ? 20 : 24,
          ),
          SizedBox(width: compact ? 10 : StilloraSpacing.sm),
          Expanded(
            child: Text(
              isSignedIn
                  ? 'Ready to convert. Media files stay on your phone.'
                  : 'No account needed. Media files stay on this phone.',
              style: (compact
                  ? Theme.of(context).textTheme.bodySmall
                  : Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
