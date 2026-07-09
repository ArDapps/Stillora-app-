import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';
import '../platform/platform_info.dart';
import 'ad_widget.dart';
import 'stillora_mark.dart';

/// Route that hosts the main tabbed home. Kept here so the shell can navigate
/// to it without importing the tabs screen (avoids an import cycle).
const kHomeRoute = '/home';

/// Currently selected home tab. Lets other screens jump to a specific tab
/// before navigating back to the home shell.
final homeTabProvider = StateProvider<int>((ref) => 0);

/// Whether the desktop sidebar is collapsed to an icon-only rail (macOS style).
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Sidebar widths for the expanded vs. collapsed (icon-only) states.
const double _sidebarCollapsedWidth = 76;

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
    index: 6,
    label: 'Watermark',
    icon: Icons.branding_watermark_outlined,
    selectedIcon: Icons.branding_watermark_rounded,
  ),
  (
    index: 5,
    label: 'Remove Silence',
    icon: Icons.content_cut_outlined,
    selectedIcon: Icons.content_cut_rounded,
  ),
  (
    index: 8,
    label: 'Convert',
    icon: Icons.swap_horiz_outlined,
    selectedIcon: Icons.swap_horiz_rounded,
  ),
  (
    index: 4,
    label: 'Loop images',
    icon: Icons.repeat_rounded,
    selectedIcon: Icons.repeat_on_rounded,
  ),
  (
    index: 2,
    label: 'HTML',
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
    label: 'Info',
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
    final collapsed = ref.watch(sidebarCollapsedProvider);
    void toggleSidebar() =>
        ref.read(sidebarCollapsedProvider.notifier).state = !collapsed;
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
              // Collapses to an icon-only rail (macOS style).
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: collapsed
                    ? _sidebarCollapsedWidth
                    : StilloraSpacing.desktopSidebarWidth,
                decoration: BoxDecoration(
                  color: StilloraColors.surfaceContainerLow.withValues(
                    alpha: 0.55,
                  ),
                  border: const Border(
                    right: BorderSide(color: StilloraColors.glassStroke),
                  ),
                ),
                child: ClipRect(
                  child: _DesktopSidebar(
                    activeIndex: activeIndex,
                    collapsed: collapsed,
                    onToggle: toggleSidebar,
                    onSelect: (index) => _select(context, ref, index),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _DesktopTopBar(
                      title: title,
                      trailing: trailing,
                      onToggleSidebar: toggleSidebar,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          StilloraSpacing.md,
                          StilloraSpacing.xs,
                          StilloraSpacing.md,
                          StilloraSpacing.md,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            StilloraRadius.xl,
                          ),
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

/// Drop-in [Scaffold] replacement for full-screen sub-pages that must keep the
/// desktop sidebar visible. On desktop the [body] is hosted inside
/// [DesktopShell] (titled with [desktopTitle], with an automatic back button);
/// on mobile it behaves like an ordinary Scaffold with [appBar] + [body].
class SidebarScaffold extends StatelessWidget {
  const SidebarScaffold({
    super.key,
    required this.desktopTitle,
    this.appBar,
    this.body,
    this.desktopTrailing,
  });

  final String desktopTitle;
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? desktopTrailing;

  @override
  Widget build(BuildContext context) {
    if (useDesktopLayout(context)) {
      return DesktopShell(
        title: desktopTitle,
        trailing: desktopTrailing,
        child: body ?? const SizedBox.shrink(),
      );
    }
    return Scaffold(appBar: appBar, body: body);
  }
}

class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar({
    required this.activeIndex,
    required this.onSelect,
    required this.collapsed,
    required this.onToggle,
  });

  final int activeIndex;
  final ValueChanged<int> onSelect;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hPad = collapsed ? StilloraSpacing.base : StilloraSpacing.snug;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPad,
        StilloraSpacing.sm,
        hPad,
        StilloraSpacing.snug,
      ),
      child: Column(
        crossAxisAlignment: collapsed
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          // Brand + collapse toggle.
          if (collapsed)
            Column(
              children: [
                const StilloraMark(size: 28),
                const SizedBox(height: StilloraSpacing.base),
                _GlassIconButton(
                  icon: Icons.keyboard_double_arrow_right_rounded,
                  tooltip: 'Expand sidebar',
                  onTap: onToggle,
                ),
              ],
            )
          else
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
                  _GlassIconButton(
                    icon: Icons.keyboard_double_arrow_left_rounded,
                    tooltip: 'Collapse sidebar',
                    onTap: onToggle,
                  ),
                ],
              ),
            ),
          const SizedBox(height: StilloraSpacing.md),
          if (!collapsed) ...[
            const _SidebarLabel('Workspace'),
            const SizedBox(height: StilloraSpacing.xs),
          ],
          for (final item in _navItems)
            _DesktopNavItem(
              selected: item.index == activeIndex,
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: item.label,
              collapsed: collapsed,
              onTap: () => onSelect(item.index),
            ),
          const Spacer(),
          if (!collapsed) ...[
            const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
            const SizedBox(height: StilloraSpacing.snug),
            Row(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: StilloraColors.secondary,
                  size: 15,
                ),
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
          ] else
            const Icon(
              Icons.shield_rounded,
              color: StilloraColors.secondary,
              size: 16,
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
    this.collapsed = false,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  State<_DesktopNavItem> createState() => _DesktopNavItemState();
}

class _DesktopNavItemState extends State<_DesktopNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    // Selected items get a bright brand-gradient pill with white text; the rest
    // stay muted, brightening only on hover.
    final fg = selected
        ? Colors.white
        : (_hovered
              ? StilloraColors.onSurface
              : StilloraColors.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.only(bottom: StilloraSpacing.base),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(StilloraRadius.md),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(StilloraRadius.md),
            child: Ink(
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          StilloraColors.brandMagenta,
                          StilloraColors.accent,
                        ],
                      )
                    : null,
                color: selected
                    ? null
                    : (_hovered
                          ? StilloraColors.onSurface.withValues(alpha: 0.06)
                          : Colors.transparent),
                borderRadius: BorderRadius.circular(StilloraRadius.md),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: StilloraColors.accent.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: SizedBox(
                height: StilloraSpacing.desktopNavItemHeight,
                child: widget.collapsed
                    ? Tooltip(
                        message: widget.label,
                        waitDuration: const Duration(milliseconds: 400),
                        child: Center(
                          child: Icon(
                            selected ? widget.selectedIcon : widget.icon,
                            size: 20,
                            color: fg,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          const SizedBox(width: StilloraSpacing.base + 2),
                          Icon(
                            selected ? widget.selectedIcon : widget.icon,
                            size: 19,
                            color: fg,
                          ),
                          const SizedBox(width: StilloraSpacing.xs + 2),
                          Expanded(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: selected
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
        ),
      ),
    );
  }
}

/// Short descriptive subtitle per section, shown under the title in the desktop
/// header so the chrome feels intentional rather than a bare app-bar.
const _sectionSubtitles = {
  'Create': 'Turn images into video, on this device',
  'Watermark': 'Add a logo or overlay onto a video',
  'Library': 'Every render you\'ve made',
  'HTML': 'Capture any web page as a clip',
  'Remove Silence': 'Auto-cut the quiet gaps from a video',
  'Speed': 'Speed up a video 1x–4x, mute or add audio',
  'Convert': 'Batch-convert HEIC & others to JPEG/PNG',
  'Loop images': 'Batch loops & slideshows',
  'Info': 'Account & subscription',
};

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.title,
    required this.trailing,
    this.onToggleSidebar,
  });

  final String? title;
  final Widget? trailing;
  final VoidCallback? onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    final subtitle = _sectionSubtitles[title];
    return Container(
      height: StilloraSpacing.desktopTopBarHeight + 8,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: StilloraColors.glassStroke)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: StilloraSpacing.md),
      child: Row(
        children: [
          if (onToggleSidebar != null) ...[
            _GlassIconButton(
              icon: Icons.view_sidebar_outlined,
              tooltip: 'Toggle sidebar',
              onTap: onToggleSidebar!,
            ),
            const SizedBox(width: StilloraSpacing.snug),
          ],
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
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
