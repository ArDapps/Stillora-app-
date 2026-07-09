import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/import_directory.dart';
import '../editor/voice_narration_screen.dart';

const _audioExtensions = ['mp3', 'm4a', 'aac', 'wav'];
const _androidAudioExtensions = ['m4a', 'aac'];

/// Opens the voice recorder and returns the recording's temp path (or null if
/// cancelled). The caller materialises/uses the path.
Future<String?> recordVoice(BuildContext context) =>
    context.push<String>(VoiceNarrationScreen.routePath);

/// Opens the file picker for an audio file and returns its path (or null).
Future<String?> uploadAudioFile() async {
  final result = await pickImportFiles(
    type: FileType.custom,
    allowedExtensions:
        Platform.isAndroid ? _androidAudioExtensions : _audioExtensions,
  );
  return result?.files.single.path;
}

/// A pair of always-visible buttons — **Record voice** and **Upload audio** —
/// so both options are discoverable at a glance (no hidden menu). Calls
/// [onPicked] with the chosen raw path; the caller materialises/uses it.
///
/// Used everywhere audio can be attached (Speed, Remove Silence, HTML → Video)
/// so the two options are consistent across the app.
class AudioSourceButtons extends StatelessWidget {
  const AudioSourceButtons({
    super.key,
    required this.onPicked,
    this.enabled = true,
  });

  final ValueChanged<String> onPicked;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Future<void> pick(Future<String?> Function() source) async {
      final path = await source();
      if (path != null) onPicked(path);
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? () => pick(() => recordVoice(context)) : null,
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Record voice'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? () => pick(uploadAudioFile) : null,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload audio'),
          ),
        ),
      ],
    );
  }
}
