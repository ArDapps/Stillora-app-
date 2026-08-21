import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/platform/platform_info.dart';
import '../audio/audio_source.dart';
import 'editor_state.dart';
import 'pre_export_preview_screen.dart';
import 'widgets/desktop_editor_workspace.dart';
import 'widgets/editor_shared.dart';
import 'widgets/mobile_editor_flow.dart';
import '../../core/i18n/app_strings.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  static const routePath = '/editor';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.create)),
      body: const EditorView(),
    );
  }
}

class EditorView extends ConsumerWidget {
  const EditorView({super.key});

  Future<void> _pickAudio(WidgetRef ref) async {
    final result = await pickImportFiles(
      type: FileType.custom,
      allowedExtensions: supportedAudioExtensions,
    );
    final path = result?.files.single.path;
    if (path != null) {
      await ref.read(editorControllerProvider.notifier).setAudioPath(path);
    }
  }

  /// Records a voice-over and attaches it as narration (desktop Create). Mobile
  /// reaches the recorder through the Add Soundtrack screen instead.
  Future<void> _recordAudio(BuildContext context, WidgetRef ref) async {
    final path = await recordVoice(context);
    if (path != null && context.mounted) {
      await ref.read(editorControllerProvider.notifier).setNarration(path);
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
        title: Text(context.strings.startOverConfirm),
        content: Text(context.strings.edClearWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.strings.reset),
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
      decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: isDesktop
            ? DesktopEditorWorkspace(
                editor: editor,
                session: session,
                controller: controller,
                onPickAudio: () => _pickAudio(ref),
                onRecordAudio: () => _recordAudio(context, ref),
                onConvert: () => _convert(context, ref, editor),
                onReset: () => _confirmReset(context, controller),
              )
            : MobileEditorFlow(
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
