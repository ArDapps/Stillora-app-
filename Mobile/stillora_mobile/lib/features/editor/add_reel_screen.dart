import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import 'reel_state.dart';
import 'widgets/add_reel_preview.dart';
import 'widgets/add_reel_widgets.dart';

const _reelAudioExtensions = ['mp3', 'm4a', 'aac', 'wav', 'ogg'];

class ReelView extends ConsumerWidget {
  const ReelView({super.key});

  Future<void> _pickAudio(WidgetRef ref) async {
    final result = await pickImportFiles(
      type: FileType.custom,
      allowedExtensions: _reelAudioExtensions,
    );
    final path = result?.files.single.path;
    if (path != null) {
      await ref.read(reelControllerProvider.notifier).setAudioPath(path);
    }
  }

  Future<void> _runExport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await ref
          .read(reelControllerProvider.notifier)
          .exportBase();
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? 'Add an app video before exporting.'
                : 'Saved to Library - ${result.width}x${result.height}',
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reel = ref.watch(reelControllerProvider);
    final controller = ref.read(reelControllerProvider.notifier);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            ReelModeSection(reel: reel, controller: controller),
            const SizedBox(height: 16),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 420,
                  maxWidth: 460,
                ),
                child: AspectRatio(
                  aspectRatio: reel.aspectRatio,
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
                      child: ReelPreview(
                        reel: reel,
                        onPick: controller.addMedia,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (reel.hasMedia) ...[
              ReelDurationBanner(reel: reel),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: controller.addMedia,
                icon: const Icon(Icons.video_call_rounded),
                label: Text(
                  reel.isMockupMode ? 'Replace app video' : 'Replace media',
                ),
              ),
              const SizedBox(height: 12),
              ReelAudioRow(
                reel: reel,
                onPick: () => _pickAudio(ref),
                onRemove: controller.removeAudio,
              ),
              const SizedBox(height: 16),
              ReelFormatExportSection(
                reel: reel,
                controller: controller,
                onExport: () => _runExport(context, ref),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.reset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Clear reel'),
                ),
              ),
            ] else
              ReelPickCard(onPick: controller.addMedia, mockup: reel.mockup),
          ],
        ),
      ),
    );
  }
}
