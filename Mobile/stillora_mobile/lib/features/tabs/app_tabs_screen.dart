import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../editor/editor_screen.dart';
import '../gallery/gallery_screen.dart';
import '../profile/profile_screen.dart';

/// Currently selected home tab. Lets other screens (e.g. Preview) jump to a
/// specific tab before navigating back to [AppTabsScreen].
final homeTabProvider = StateProvider<int>((ref) => 0);

class AppTabsScreen extends ConsumerWidget {
  const AppTabsScreen({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    final titles = ['Create', 'Library', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: index == 2 ? const [ProfileSettingsButton()] : null,
      ),
      body: IndexedStack(
        index: index,
        children: const [EditorView(), GalleryView(), ProfileView()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) =>
            ref.read(homeTabProvider.notifier).state = value,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_photo_alternate_outlined),
            selectedIcon: Icon(Icons.add_photo_alternate_rounded),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
