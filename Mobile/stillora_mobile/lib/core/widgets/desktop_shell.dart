import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';
import 'ad_widget.dart';
import 'stillora_mark.dart';

/// Route that hosts the main tabbed home. Kept here so the shell can navigate
/// to it without importing the tabs screen (avoids an import cycle).
const kHomeRoute = '/home';

/// Currently selected home tab. Lets other screens jump to a specific tab
/// before navigating back to the home shell.
final homeTabProvider = StateProvider<int>((ref) => 0);

// Display order for the desktop sidebar. `index` is the underlying home tab
// (matches app_tabs_screen views), so the list can be reordered for display
// without changing which screen each item opens. Library sits directly before
// Profile on desktop.
const _navItems = [
  (
    index: 0,
    label: 'Create',
    icon: Icons.add_photo_alternate_outlined,
    selectedIcon: Icons.add_photo_alternate_rounded,
  ),
  (
    index: 4,
    label: 'Loop images',
    icon: Icons.repeat_rounded,
    selectedIcon: Icons.repeat_on_rounded,
  ),
  (
    index: 2,
    label: 'HTML → Video',
    icon: Icons.html_outlined,
    selectedIcon: Icons.html_rounded,
  ),
  (
    index: 1,
    label: 'Library',
    icon: Icons.video_library_outlined,
    selectedIcon: Icons.video_library_rounded,
  ),
  (
    index: 3,
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
];

/// Persistent desktop chrome: a sidebar that is always visible plus a top bar
/// with an automatic back button. Wrap any desktop screen body with this so the
/// navigation never disappears on sub-pages (sign-in, settings, export, etc.).
class DesktopShell extends ConsumerWidget {
  const DesktopShell({
    super.key,
    required this.child,
    this.title,
    this.activeIndex = -1,
    this.trailing,
  });

  final Widget child;
  final String? title;

  /// Index of the highlighted nav item, or -1 when on a sub-page.
  final int activeIndex;
  final Widget? trailing;

  void _select(BuildContext context, WidgetRef ref, int index) {
    ref.read(homeTabProvider.notifier).state = index;
    if (GoRouterState.of(context).matchedLocation != kHomeRoute) {
      context.go(kHomeRoute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff0d0820), Color(0xff070611), Color(0xff030309)],
          ),
        ),
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sidebar sits on its own slightly-raised glass surface so the
              // navigation reads as desktop chrome, not a stretched phone.
              Container(
                width: StilloraSpacing.desktopSidebarWidth,
                decoration: BoxDecoration(
                  color: StilloraColors.surfaceContainerLow.withValues(alpha: 0.55),
                  border: const Border(
                    right: BorderSide(color: StilloraColors.glassStroke),
                  ),
                ),
                child: _DesktopSidebar(
                  activeIndex: activeIndex,
                  onSelect: (index) => _select(context, ref, index),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _DesktopTopBar(title: title, trailing: trailing),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          StilloraSpacing.md,
                          StilloraSpacing.xs,
                          StilloraSpacing.md,
                          StilloraSpacing.md,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(StilloraRadius.xl),
                          child: child,
                        ),
                      ),
                    ),
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

class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar({required this.activeIndex, required this.onSelect});

  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StilloraSpacing.snug,
        StilloraSpacing.sm,
        StilloraSpacing.snug,
        StilloraSpacing.snug,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand lockup.
          Padding(
            padding: const EdgeInsets.only(left: StilloraSpacing.base),
            child: Row(
              children: [
                const StilloraMark(size: 30),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: Text(
                    'Stillora',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: StilloraSpacing.md),
          const _SidebarLabel('Workspace'),
          const SizedBox(height: StilloraSpacing.xs),
          for (final item in _navItems)
            _DesktopNavItem(
              selected: item.index == activeIndex,
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: item.label,
              onTap: () => onSelect(item.index),
            ),
          const Spacer(),
          const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
          const SizedBox(height: StilloraSpacing.snug),
          Row(
            children: [
              const Icon(Icons.shield_rounded,
                  color: StilloraColors.secondary, size: 15),
              const SizedBox(width: StilloraSpacing.base + 2),
              Expanded(
                child: Text(
                  'Files stay on this computer.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: StilloraSpacing.snug),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
      ),
    );
  }
}

class _DesktopNavItem extends StatefulWidget {
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
  State<_DesktopNavItem> createState() => _DesktopNavItemState();
}

class _DesktopNavItemState extends State<_DesktopNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final fg = selected
        ? StilloraColors.onSurface
        : (_hovered ? StilloraColors.onSurface : StilloraColors.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.only(bottom: StilloraSpacing.base),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: selected
              ? StilloraColors.accent.withValues(alpha: 0.16)
              : (_hovered
                  ? StilloraColors.onSurface.withValues(alpha: 0.05)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(StilloraRadius.md),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(StilloraRadius.md),
            child: SizedBox(
              height: StilloraSpacing.desktopNavItemHeight,
              child: Row(
                children: [
                  // Active accent bar.
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: selected ? StilloraColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(StilloraRadius.pill),
                    ),
                  ),
                  const SizedBox(width: StilloraSpacing.snug - 3),
                  Icon(
                    selected ? widget.selectedIcon : widget.icon,
                    size: 19,
                    color: selected ? StilloraColors.accentText : fg,
                  ),
                  const SizedBox(width: StilloraSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected ? StilloraColors.onSurface : fg,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Short descriptive subtitle per section, shown under the title in the desktop
/// header so the chrome feels intentional rather than a bare app-bar.
const _sectionSubtitles = {
  'Create': 'Turn images into video, on this device',
  'Library': 'Every render you\'ve made',
  'HTML → Video': 'Capture any web page as a clip',
  'Loop images': 'Batch loops & slideshows',
  'Profile': 'Account & subscription',
};

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.title, required this.trailing});

  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    final subtitle = _sectionSubtitles[title];
    return Container(
      height: StilloraSpacing.desktopTopBarHeight + 8,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: StilloraColors.glassStroke),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: StilloraSpacing.md),
      child: Row(
        children: [
          if (canPop) ...[
            _GlassIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onTap: () => context.pop(),
            ),
            const SizedBox(width: StilloraSpacing.snug),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: StilloraColors.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: StilloraColors.surfaceContainer.withValues(alpha: 0.6),
      shape: const CircleBorder(
        side: BorderSide(color: StilloraColors.glassStroke),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: StilloraColors.onSurface),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}
