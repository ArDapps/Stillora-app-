import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/platform/media_actions.dart';
import '../../core/platform/platform_info.dart';
import 'local_export_record.dart';

/// Filename offered in the save dialog, e.g. `stillora-reels-916-1080x1920.mp4`.
String suggestedFileNameFor(LocalExportRecord record) {
  final preset = record.preset.toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '-',
  );
  return 'stillora-$preset-${record.width}x${record.height}.mp4';
}

/// Saves [record] out of the app's private storage to somewhere the user
/// controls, reporting the outcome via a snackbar.
///
/// Desktop has no Camera Roll, so it opens a native "Save As" dialog rather
/// than asking for photo-library access that doesn't apply there.
Future<void> downloadRecord(
  BuildContext context,
  LocalExportRecord record,
) async {
  final messenger = ScaffoldMessenger.of(context);
  void snack(String message, {bool offerSettings = false}) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: offerSettings
            ? SnackBarAction(label: 'Settings', onPressed: openAppSettings)
            : null,
      ),
    );
  }

  final outcome = isDesktopPlatform
      ? await MediaActions.saveVideoToFile(
          record.outputPath,
          suggestedName: suggestedFileNameFor(record),
        )
      : await MediaActions.saveToCameraRoll(record.outputPath);

  switch (outcome) {
    case SaveOutcome.saved:
      snack(isDesktopPlatform ? 'Video saved.' : 'Saved to your Camera Roll.');
    case SaveOutcome.missingFile:
      snack('That video is no longer available.');
    case SaveOutcome.permissionDenied:
      snack('Allow photo access to save your video.', offerSettings: true);
    case SaveOutcome.failed:
      snack('Could not save the video. Please try again.');
    case SaveOutcome.cancelled:
      break; // User dismissed the save dialog.
  }
}

/// Per-video download control shown under each Library entry, so a render can
/// be pulled out of the app without opening it first.
///
/// Shows a spinner while the copy is in flight — large exports take a moment,
/// and without it a second tap would start a duplicate save.
class GalleryDownloadButton extends StatefulWidget {
  const GalleryDownloadButton({
    super.key,
    required this.record,
    this.compact = false,
  });

  final LocalExportRecord record;

  /// Icon-only, for the dense list rows; the grid cards use the labelled form.
  final bool compact;

  @override
  State<GalleryDownloadButton> createState() => _GalleryDownloadButtonState();
}

class _GalleryDownloadButtonState extends State<GalleryDownloadButton> {
  bool _saving = false;

  Future<void> _run() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await downloadRecord(context, widget.record);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = isDesktopPlatform ? 'Download' : 'Save';
    final spinner = const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    if (widget.compact) {
      return IconButton(
        onPressed: _saving ? null : _run,
        icon: _saving ? spinner : const Icon(Icons.download_rounded, size: 20),
        tooltip: label,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _saving ? null : _run,
        icon: _saving ? spinner : const Icon(Icons.download_rounded, size: 18),
        label: Text(_saving ? 'Saving…' : label),
      ),
    );
  }
}
