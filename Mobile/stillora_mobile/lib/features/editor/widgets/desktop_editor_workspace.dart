import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_glow.dart';
import '../../../core/widgets/ad_widget.dart';
import '../editor_state.dart';
import 'desktop_export_panel.dart';
import 'editor_preview.dart';
import 'editor_progress_rail.dart';
import 'preset_card.dart';
import 'soundscape_card.dart';
import 'source_media_card.dart';
import 'style_card.dart';

class DesktopEditorWorkspace extends StatelessWidget {
  const DesktopEditorWorkspace({
    super.key,
    required this.editor,
    required this.session,
    required this.controller,
    required this.onPickAudio,
    required this.onRecordAudio,
    required this.onConvert,
    required this.onReset,
  });

  final EditorState editor;
  final Object? session;
  final EditorController controller;
  final VoidCallback onPickAudio;
  final VoidCallback onRecordAudio;
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
              SourceMediaCard(
                editor: editor,
                controller: controller,
                compact: compact,
              ),
              const SizedBox(height: 10),
              SoundscapeCard(
                editor: editor,
                onPickAudio: onPickAudio,
                onRecordAudio: onRecordAudio,
                onRemoveAudio: controller.removeAudio,
                compact: compact,
              ),
              const SizedBox(height: 10),
              PresetCard(
                editor: editor,
                controller: controller,
                compact: compact,
              ),
              const SizedBox(height: 10),
              StyleCard(editor: editor, controller: controller),
              const SizedBox(height: 10),
              DesktopExportPanel(
                editor: editor,
                isSignedIn: session != null,
                onConvert: onConvert,
                onReset: onReset,
                compact: compact,
              ),
              const SizedBox(height: 10),
              PreviewCard(
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
                        SourceMediaCard(
                          editor: editor,
                          controller: controller,
                          compact: compact,
                        ),
                        const SizedBox(height: 10),
                        SoundscapeCard(
                          editor: editor,
                          onPickAudio: onPickAudio,
                          onRecordAudio: onRecordAudio,
                          onRemoveAudio: controller.removeAudio,
                          compact: compact,
                        ),
                        const SizedBox(height: 10),
                        PresetCard(
                          editor: editor,
                          controller: controller,
                          compact: compact,
                        ),
                        const SizedBox(height: 10),
                        StyleCard(editor: editor, controller: controller),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: previewWidth,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        DesktopExportPanel(
                          editor: editor,
                          isSignedIn: session != null,
                          onConvert: onConvert,
                          onReset: onReset,
                          compact: compact,
                        ),
                        const SizedBox(height: 10),
                        PreviewCard(
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
        const ProgressRail(compact: true),
      ],
    );
  }
}
