import '../../../core/i18n/app_strings.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/design/stillora_spacing.dart';
import '../../../core/platform/media_actions.dart';
import '../../../core/platform/platform_info.dart';

/// The primary render button, which becomes a progress row + cancel while a
/// conversion is in flight.
class ConvertButton extends StatelessWidget {
  const ConvertButton({
    super.key,
    required this.converting,
    required this.onConvert,
    required this.onCancel,
  });

  final bool converting;
  final VoidCallback onConvert;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (converting) {
      return SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(context.strings.htmlRendering),
                ],
              ),
            ),
            const SizedBox(width: StilloraSpacing.xs),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              label: Text(context.strings.cancel),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: onConvert,
        icon: const Icon(Icons.auto_awesome),
        label: Text(context.strings.htmlConvertCta),
      ),
    );
  }
}

/// Writes the finished render to the camera roll (mobile) or a chosen file
/// (desktop), reporting the outcome in a snack bar.
Future<void> saveRenderedVideo(BuildContext context, File file) async {
  final name = 'stillora_${DateTime.now().millisecondsSinceEpoch}.mp4';
  final outcome = isDesktopPlatform
      ? await MediaActions.saveVideoToFile(
          file.path,
          suggestedName: name,
          dialogTitle: context.strings.shareSaveVideo,
        )
      : await MediaActions.saveToCameraRoll(file.path);
  if (!context.mounted || outcome == SaveOutcome.cancelled) return;
  final message = switch (outcome) {
    SaveOutcome.saved =>
      isDesktopPlatform
          ? context.strings.htmlVideoSaved
          : context.strings.htmlSavedToRoll,
    SaveOutcome.permissionDenied => context.strings.htmlPhotosDenied,
    SaveOutcome.missingFile => context.strings.htmlFileMissing,
    SaveOutcome.failed => context.strings.htmlSaveFailed,
    SaveOutcome.cancelled => '',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Hands the finished render to the platform share sheet.
Future<void> shareRenderedVideo(BuildContext context, File file) async {
  final ok = await MediaActions.shareVideo(context, file.path);
  if (!context.mounted || ok) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(context.strings.htmlFileMissing)));
}

/// Save / share row shown once a render has finished.
class ResultActions extends StatelessWidget {
  const ResultActions({super.key, required this.onSave, required this.onShare});

  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onSave,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Save'),
          ),
        ),
        const SizedBox(width: StilloraSpacing.xs),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }
}
