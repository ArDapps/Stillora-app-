import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../editor/editor_screen.dart';
import '../editor/video_preset.dart';
import '../gallery/gallery_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stillora'),
        actions: [
          IconButton(
            tooltip: 'Gallery',
            icon: const Icon(Icons.video_library_rounded),
            onPressed: () => context.go(GalleryScreen.routePath),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => context.go(ProfileScreen.routePath),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.go(SettingsScreen.routePath),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Create a new video',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Image to MP4, saved locally and ready to share.'),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.go(EditorScreen.routePath),
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: const Text('Create New Video'),
          ),
          const SizedBox(height: 20),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded),
                  SizedBox(width: 12),
                  Expanded(child: Text('Your media stays on this phone.')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Preset shortcuts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in videoPresets.take(6))
                ActionChip(
                  avatar: const Icon(Icons.aspect_ratio_rounded, size: 18),
                  label: Text('${preset.label} ${preset.ratioLabel}'),
                  onPressed: () => context.go(EditorScreen.routePath),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Recent local exports',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Icon(
                    Icons.movie_filter_rounded,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Exports you create on this device will appear here.',
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
