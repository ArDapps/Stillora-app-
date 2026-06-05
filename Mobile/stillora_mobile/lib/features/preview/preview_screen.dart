import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../editor/editor_screen.dart';
import '../gallery/gallery_screen.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  static const routePath = '/preview';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.play_circle_fill_rounded, size: 72),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Play'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.pause_rounded),
            label: const Text('Pause'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Save to Gallery'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Share'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go(EditorScreen.routePath),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Another Video'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.go(GalleryScreen.routePath),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete Local Export'),
          ),
        ],
      ),
    );
  }
}
