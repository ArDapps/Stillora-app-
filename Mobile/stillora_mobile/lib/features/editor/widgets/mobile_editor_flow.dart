import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/preview_metrics.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_glow.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/design/stillora_surface.dart';
import '../../../core/widgets/ad_widget.dart';
import '../add_audio_screen.dart';
import '../choose_preset_screen.dart';
import '../editor_state.dart';
import '../video_preset.dart';
import '../upload_media_screen.dart';
import 'editor_preview.dart';
import 'editor_progress_rail.dart';
import 'editor_shared.dart';
import 'media_timeline.dart';
import 'style_card.dart';
import '../../../core/i18n/app_strings.dart';

class MobileEditorFlow extends StatelessWidget {
  const MobileEditorFlow({
    super.key,
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
        const ProgressRail(),
        const SizedBox(height: StilloraSpacing.lg),
        if (canReset(editor)) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(context.strings.startOver),
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
              ? context.strings.edAddSoundtrack
              : editor.audioIsNarration
              ? context.strings.edVoiceNarration
              : _audioName(editor.audioPath!),
          subtitle: editor.audioPath == null
              ? context.strings.edSoundtrackOrNarration
              : context.strings.edTapToChange,
          onTap: () => context.push(AddAudioScreen.routePath),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        _StepRow(
          icon: Icons.aspect_ratio_rounded,
          label: context.strings.edChoosePreset,
          subtitle:
              '${editor.preset.labelOf(context.strings)} · '
              '${editor.preset.ratioLabelOf(context.strings)}',
          onTap: () => context.push(ChoosePresetScreen.routePath),
        ),
        const SizedBox(height: StilloraSpacing.sm),
        StyleCard(editor: editor, controller: controller),
        const SizedBox(height: StilloraSpacing.sm),
        StilloraPrimaryButton(
          onPressed: editor.canExport ? onConvert : null,
          icon: Icons.auto_fix_high_rounded,
          label: context.strings.edCreateMp4,
        ),
        const SizedBox(height: StilloraSpacing.md),
        const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
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
            // Flexible + scaleDown: the wordmark keeps its display size when
            // there is room and shrinks instead of overflowing on narrow
            // phones (it was blowing the row by ~8px at 390pt).
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      stilloraBrandGradient.createShader(bounds),
                  child: Text(
                    'Stillora',
                    maxLines: 1,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          context.strings.edThreeSteps,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
      ],
    );
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
          Icon(
            Icons.chevron_right_rounded,
            color: StilloraColors.onSurfaceVariant,
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
    // Match the resolved output size so "Original Size"/"Custom" preview at the
    // real export shape rather than a fixed 9:16.
    final res = editor.outputResolution;
    return (res.width > 0 && res.height > 0) ? res.width / res.height : 9 / 16;
  }

  @override
  Widget build(BuildContext context) {
    return StilloraGlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
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
                      context.strings.edMp4Preview,
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
                child: Text(context.strings.edChange),
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
                constraints: BoxConstraints(
                  maxHeight: mobilePreviewMaxHeight(context),
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
                      child: EditorPreviewStage(editor: editor),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (editor.hasMedia) ...[
            const SizedBox(height: StilloraSpacing.sm),
            MediaTimeline(editor: editor, controller: controller),
            const SizedBox(height: StilloraSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(UploadMediaScreen.routePath),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.strings.edAddMore),
                  ),
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickMedia,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.strings.edReplace),
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
