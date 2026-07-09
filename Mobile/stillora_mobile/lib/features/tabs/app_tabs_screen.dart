import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/desktop_shell.dart';
import '../../core/widgets/stillora_mark.dart';
import '../editor/editor_screen.dart';
import '../gallery/gallery_screen.dart';
import '../silence/silence_screen.dart';
import '../speed/speed_screen.dart';
import '../convert/convert_screen.dart';
import '../html_to_video/html_to_video_screen.dart';
import '../loop_images/loop_images_screen.dart';
import '../profile/profile_screen.dart';
import '../watermark/watermark_screen.dart';

class AppTabsScreen extends ConsumerWidget {
  const AppTabsScreen({super.key});

  static const routePath = kHomeRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    const titles = [
      'Create',
      'Library',
      'HTML',
      'Info',
      'Loop images',
      'Remove Silence',
      'Watermark',
      'Speed',
      'Convert',
    ];
    const views = [
      EditorView(),
      GalleryView(),
      HtmlToVideoView(),
      ProfileView(),
      LoopImagesView(),
      SilenceView(),
      WatermarkView(),
      SpeedView(),
      ConvertView(),
    ];

    if (useDesktopLayout(context)) {
      return DesktopShell(
        activeIndex: index,
        title: titles[index],
        trailing: index == 3 ? const ProfileSettingsButton() : null,
        child: views[index],
      );
    }

    // Mobile / tablet (narrow): navigation lives in a hamburger drawer (the
    // desktop's persistent sidebar is shown via DesktopShell above). Display
    // order: creation tools (Create / HTML / Loop) first, then Library, Info.
    final selected = index;

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: index == 3 ? const [ProfileSettingsButton()] : null,
      ),
      drawer: _AppNavDrawer(
        activeView: selected,
        onSelect: (view) => ref.read(homeTabProvider.notifier).state = view,
      ),
      // Each section screen embeds its own ad banner, so no persistent bottom
      // banner here (that showed a duplicate/static ad under every tab).
      body: IndexedStack(index: index, children: views),
    );
  }
}

/// Items for the mobile navigation drawer. `view` is the underlying home-tab
/// index (matches the `views` list in [AppTabsScreen]).
const _drawerNavItems = [
  (
    view: 0,
    icon: Icons.add_photo_alternate_outlined,
    selectedIcon: Icons.add_photo_alternate_rounded,
    label: 'Create',
  ),
  (
    view: 6,
    icon: Icons.branding_watermark_outlined,
    selectedIcon: Icons.branding_watermark_rounded,
    label: 'Watermark',
  ),
  (
    view: 5,
    icon: Icons.content_cut_outlined,
    selectedIcon: Icons.content_cut_rounded,
    label: 'Remove Silence',
  ),
  (
    view: 7,
    icon: Icons.fast_forward_outlined,
    selectedIcon: Icons.fast_forward_rounded,
    label: 'Speed',
  ),
  (
    view: 8,
    icon: Icons.swap_horiz_outlined,
    selectedIcon: Icons.swap_horiz_rounded,
    label: 'Convert',
  ),
  (
    view: 2,
    icon: Icons.public_outlined,
    selectedIcon: Icons.public_rounded,
    label: 'HTML',
  ),
  (
    view: 4,
    icon: Icons.repeat_rounded,
    selectedIcon: Icons.repeat_on_rounded,
    label: 'Loop images',
  ),
  (
    view: 1,
    icon: Icons.video_library_outlined,
    selectedIcon: Icons.video_library_rounded,
    label: 'Library',
  ),
  (
    view: 3,
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    label: 'Info',
  ),
];

/// Slide-out navigation drawer for phones/tablets (opened by the AppBar ☰).
/// Mirrors the desktop sidebar's brand + nav + privacy footer.
class _AppNavDrawer extends StatelessWidget {
  const _AppNavDrawer({required this.activeView, required this.onSelect});

  final int activeView;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: StilloraColors.surfaceDim,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                StilloraSpacing.md,
                StilloraSpacing.md,
                StilloraSpacing.md,
                StilloraSpacing.sm,
              ),
              child: Row(
                children: [
                  const StilloraMark(size: 30),
                  const SizedBox(width: StilloraSpacing.xs),
                  Text(
                    'Stillora',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: StilloraColors.glassStroke),
            const SizedBox(height: StilloraSpacing.xs),
            // iOS shows every section: Remove Silence (5) & Speed (7) run on
            // its native removeSilence engine, and Watermark (6) is shown too
            // (its export currently messages that it's desktop-only). Android
            // has no native engine for 5/6/7, so those stay hidden there.
            for (final item in _drawerNavItems)
              if (isDesktopPlatform ||
                  isIosPlatform ||
                  (item.view != 5 && item.view != 6 && item.view != 7))
                _DrawerNavTile(
                  selected: item.view == activeView,
                  icon: item.icon,
                  selectedIcon: item.selectedIcon,
                  label: item.label,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelect(item.view);
                  },
                ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(StilloraSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: StilloraColors.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: StilloraSpacing.base + 2),
                  Expanded(
                    child: Text(
                      'Files stay on this device.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
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
    final fg = selected
        ? StilloraColors.onSurface
        : StilloraColors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: StilloraSpacing.base,
        vertical: 2,
      ),
      child: Material(
        color: selected
            ? StilloraColors.accent.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(StilloraRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(StilloraRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StilloraSpacing.snug,
              vertical: StilloraSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 20,
                  color: selected ? StilloraColors.accentText : fg,
                ),
                const SizedBox(width: StilloraSpacing.snug),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: fg,
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
