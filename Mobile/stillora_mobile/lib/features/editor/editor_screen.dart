import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../export/export_progress_screen.dart';
import 'editor_state.dart';
import 'video_preset.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  static const routePath = '/editor';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Create video')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: AspectRatio(
              aspectRatio: editor.preset.width > editor.preset.height
                  ? 16 / 9
                  : 9 / 16,
              child: Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: editor.imagePath == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image_rounded, size: 56),
                          const SizedBox(height: 10),
                          const Text('Select one local image'),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: controller.pickImage,
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text('Select Image'),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 48),
                            const SizedBox(height: 10),
                            Text(
                              editor.imagePath!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: controller.pickImage,
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: const Text('Replace Image'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('Format', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in videoPresets)
                ChoiceChip(
                  label: Text('${preset.label} ${preset.ratioLabel}'),
                  selected: editor.preset == preset,
                  onSelected: (_) => controller.setPreset(preset),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Duration', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 10, label: Text('10 sec')),
              ButtonSegment(value: 30, label: Text('30 sec')),
            ],
            selected: {editor.durationSeconds},
            onSelectionChanged: (value) => controller.setDuration(value.first),
          ),
          const SizedBox(height: 22),
          Text('Resize', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
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
          const SizedBox(height: 22),
          Text('Audio', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (editor.audioPath == null)
            OutlinedButton.icon(
              onPressed: () => _pickAudio(ref),
              icon: const Icon(Icons.audio_file_rounded),
              label: const Text('Add Optional Audio'),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.graphic_eq_rounded),
                title: Text(
                  editor.audioPath!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: 'Remove audio',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: controller.removeAudio,
                ),
              ),
            ),
          const SizedBox(height: 22),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Your image and audio stay on your phone during export.',
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: editor.canExport
                ? () => context.go(ExportProgressScreen.routePath)
                : null,
            icon: const Icon(Icons.movie_creation_rounded),
            label: const Text('Generate Video'),
          ),
        ],
      ),
    );
  }
}
