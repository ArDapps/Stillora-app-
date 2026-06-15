import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/platform_info.dart';
import '../../core/widgets/desktop_shell.dart';
import '../editor/editor_screen.dart';
import '../gallery/gallery_screen.dart';
import '../html_to_video/html_to_video_screen.dart';
import '../profile/profile_screen.dart';

class AppTabsScreen extends ConsumerWidget {
  const AppTabsScreen({super.key});

  static const routePath = kHomeRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    const titles = ['Create', 'Library', 'HTML → Video', 'Profile'];
    const views = [
      EditorView(),
      GalleryView(),
      HtmlToVideoView(),
      ProfileView(),
    ];

    if (useDesktopLayout(context)) {
      return DesktopShell(
        activeIndex: index,
        title: titles[index],
        trailing: index == 3 ? const ProfileSettingsButton() : null,
        child: views[index],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: index == 3 ? const [ProfileSettingsButton()] : null,
      ),
      body: IndexedStack(index: index, children: views),
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
            icon: Icon(Icons.html_outlined),
            selectedIcon: Icon(Icons.html_rounded),
            label: 'HTML',
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
