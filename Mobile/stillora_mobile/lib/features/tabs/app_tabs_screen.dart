import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/platform_info.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/desktop_shell.dart';
import '../editor/editor_screen.dart';
import '../gallery/gallery_screen.dart';
import '../html_to_video/html_to_video_screen.dart';
import '../loop_images/loop_images_screen.dart';
import '../profile/profile_screen.dart';

class AppTabsScreen extends ConsumerWidget {
  const AppTabsScreen({super.key});

  static const routePath = kHomeRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    const titles = ['Create', 'Library', 'HTML → Video', 'Profile', 'Loop images'];
    const views = [
      EditorView(),
      GalleryView(),
      HtmlToVideoView(),
      ProfileView(),
      LoopImagesView(),
    ];

    if (useDesktopLayout(context)) {
      return DesktopShell(
        activeIndex: index,
        title: titles[index],
        trailing: index == 3 ? const ProfileSettingsButton() : null,
        child: views[index],
      );
    }

    // Display order for the bottom bar, decoupled from the underlying view
    // index. Profile sits last (the conventional spot); the creation tools
    // (Create / HTML / Loop) and Library come first.
    const navItems = [
      (view: 0, icon: Icons.add_photo_alternate_outlined, selectedIcon: Icons.add_photo_alternate_rounded, label: 'Create'),
      (view: 1, icon: Icons.video_library_outlined, selectedIcon: Icons.video_library_rounded, label: 'Library'),
      (view: 2, icon: Icons.public_outlined, selectedIcon: Icons.public_rounded, label: 'HTML'),
      (view: 4, icon: Icons.repeat_rounded, selectedIcon: Icons.repeat_on_rounded, label: 'Loop'),
      (view: 3, icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
    ];
    final selectedPos = navItems.indexWhere((n) => n.view == index);

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: index == 3 ? const [ProfileSettingsButton()] : null,
      ),
      body: Column(
        children: [
          Expanded(child: IndexedStack(index: index, children: views)),
          // Banner shown on every tab (collapses to nothing on desktop/web).
          const SafeArea(top: false, child: AdSlotWidget()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPos < 0 ? 0 : selectedPos,
        onDestinationSelected: (pos) =>
            ref.read(homeTabProvider.notifier).state = navItems[pos].view,
        destinations: [
          for (final item in navItems)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
