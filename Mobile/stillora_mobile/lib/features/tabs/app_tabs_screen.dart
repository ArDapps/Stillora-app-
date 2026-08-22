import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/desktop_shell.dart';
import '../../core/widgets/stillora_mark.dart';
import '../compress/compress_screen.dart';
import '../convert/convert_screen.dart';
import '../editor/editor_screen.dart';
import '../gallery/gallery_screen.dart';
import '../html_to_video/html_to_video_screen.dart';
import '../images_to_pdf/images_to_pdf_screen.dart';
import '../loop_images/loop_images_screen.dart';
import '../pro/pro_screen.dart';
import '../settings/settings_screen.dart';
import '../silence/silence_screen.dart';
import '../speed/speed_screen.dart';
import '../text_overlay/text_overlay_screen.dart';
import '../watermark/watermark_screen.dart';
import 'app_sections.dart';

class AppTabsScreen extends ConsumerWidget {
  const AppTabsScreen({super.key});

  static const routePath = kHomeRoute;

  /// Section bodies, indexed by [AppSection.viewIndex].
  static const views = [
    EditorView(),
    GalleryView(),
    HtmlToVideoView(),
    SettingsView(),
    LoopImagesView(),
    SilenceView(),
    WatermarkView(),
    SpeedView(),
    ConvertView(),
    TextOverlayView(),
    CompressView(),
    ImagesToPdfView(),
    ProView(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    final title = AppSection.fromIndex(index).title(context.strings);

    if (useDesktopLayout(context)) {
      return DesktopShell(
        activeIndex: index,
        title: title,
        child: views[index],
      );
    }

    // Mobile / tablet (narrow): navigation lives in a hamburger drawer (the
    // desktop's persistent sidebar is shown via DesktopShell above).
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: AppNavDrawer(
        activeView: index,
        onSelect: (view) => ref.read(homeTabProvider.notifier).state = view,
      ),
      // Each section screen embeds its own ad banner, so no persistent bottom
      // banner here (that showed a duplicate/static ad under every tab).
      body: IndexedStack(index: index, children: views),
    );
  }
}

/// Slide-out navigation drawer for phones/tablets (opened by the AppBar ☰).
/// Mirrors the desktop sidebar's brand + nav + privacy footer.
/// Public so its scroll/overflow behaviour can be widget-tested in isolation
/// (without the whole tab screen's gallery/ad deps).
class AppNavDrawer extends StatelessWidget {
  const AppNavDrawer({
    super.key,
    required this.activeView,
    required this.onSelect,
  });

  final int activeView;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
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
            Divider(height: 1, color: StilloraColors.glassStroke),
            const SizedBox(height: StilloraSpacing.xs),
            // Nav list scrolls so it never overflows on short screens, while the
            // privacy footer below stays pinned to the bottom.
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Same grouping as the desktop sidebar, from the same source
                  // of truth, so the two navigations can't drift apart.
                  for (final group in navGroups)
                    if (group.availableSections.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          StilloraSpacing.md,
                          StilloraSpacing.snug,
                          StilloraSpacing.md,
                          StilloraSpacing.base,
                        ),
                        // Matches the desktop sidebar heading exactly: brand
                        // violet, heavier and a size up, so the group reads as
                        // a heading instead of a greyed-out nav row.
                        child: Text(
                          group.group.label(strings).toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: StilloraColors.accentText,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      for (final section in group.availableSections)
                        _DrawerNavTile(
                          selected: section.viewIndex == activeView,
                          icon: section.icon,
                          selectedIcon: section.selectedIcon,
                          label: section.title(strings),
                          premium: section == AppSection.stilloraPro,
                          onTap: () {
                            Navigator.of(context).pop();
                            onSelect(section.viewIndex);
                          },
                        ),
                    ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(StilloraSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: StilloraColors.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: StilloraSpacing.base + 2),
                  Expanded(
                    child: Text(
                      strings.filesStayOnDevice,
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
    this.premium = false,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  /// Marks the Stillora Pro entry with the premium tint (see the desktop
  /// sidebar's equivalent).
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? StilloraColors.onSurface
        : premium
        ? StilloraColors.brandCyan
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
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: selected || premium
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: fg,
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
