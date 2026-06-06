import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/stillora_mark.dart';
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
    const titles = ['Create', 'Library', 'Profile'];
    const views = [EditorView(), GalleryView(), ProfileView()];

    if (useDesktopLayout(context)) {
      return _DesktopTabsShell(
        index: index,
        title: titles[index],
        onDestinationSelected: (value) =>
            ref.read(homeTabProvider.notifier).state = value,
        child: views[index],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: index == 2 ? const [ProfileSettingsButton()] : null,
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
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DesktopTabsShell extends StatelessWidget {
  const _DesktopTabsShell({
    required this.index,
    required this.title,
    required this.onDestinationSelected,
    required this.child,
  });

  final int index;
  final String title;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff090613), Color(0xff050610), Color(0xff030309)],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: 232,
                child: _DesktopSidebar(
                  index: index,
                  onDestinationSelected: onDestinationSelected,
                ),
              ),
              Container(width: 1, color: StilloraColors.glassStroke),
              Expanded(
                child: Column(
                  children: [
                    _DesktopTopBar(title: title, showSettings: index == 2),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.index,
    required this.onDestinationSelected,
  });

  final int index;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StilloraSpacing.sm,
        StilloraSpacing.md,
        StilloraSpacing.sm,
        StilloraSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              StilloraMark(size: 44),
              SizedBox(width: StilloraSpacing.xs),
              Expanded(
                child: Text(
                  'Stillora',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.lg),
          _DesktopNavItem(
            selected: index == 0,
            icon: Icons.add_photo_alternate_outlined,
            selectedIcon: Icons.add_photo_alternate_rounded,
            label: 'Create',
            onTap: () => onDestinationSelected(0),
          ),
          _DesktopNavItem(
            selected: index == 1,
            icon: Icons.video_library_outlined,
            selectedIcon: Icons.video_library_rounded,
            label: 'Library',
            onTap: () => onDestinationSelected(1),
          ),
          _DesktopNavItem(
            selected: index == 2,
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
            onTap: () => onDestinationSelected(2),
          ),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(StilloraRadius.full),
              border: Border.all(color: StilloraColors.glassStroke),
              color: StilloraColors.surfaceContainer.withValues(alpha: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(StilloraSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: StilloraColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(height: StilloraSpacing.xs),
                  Text(
                    'Local desktop workspace',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: StilloraSpacing.base),
                  Text(
                    'Files stay on this computer while you build exports.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: StilloraColors.onSurfaceVariant,
                    ),
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

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StilloraSpacing.xs),
      child: Material(
        color: selected
            ? StilloraColors.primaryContainer.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(StilloraRadius.full),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: StilloraSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(StilloraRadius.full),
              border: Border.all(
                color: selected
                    ? StilloraColors.primary.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: selected
                      ? StilloraColors.primary
                      : StilloraColors.onSurfaceVariant,
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected
                          ? StilloraColors.primary
                          : StilloraColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.title, required this.showSettings});

  final String title;
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: StilloraSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (showSettings) const ProfileSettingsButton(),
          ],
        ),
      ),
    );
  }
}
