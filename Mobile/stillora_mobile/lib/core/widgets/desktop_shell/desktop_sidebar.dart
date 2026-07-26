import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/stillora_colors.dart';
import '../../design/stillora_spacing.dart';
import '../ad_widget.dart';
import '../stillora_mark.dart';
import 'glass_icon_button.dart';

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
    index: 9,
    label: 'Text',
    icon: Icons.text_fields_outlined,
    selectedIcon: Icons.text_fields_rounded,
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
    index: 7,
    label: 'Speed',
    icon: Icons.fast_forward_outlined,
    selectedIcon: Icons.fast_forward_rounded,
  ),
  (
    index: 10,
    label: 'Compress',
    icon: Icons.compress_outlined,
    selectedIcon: Icons.compress_rounded,
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
    index: 11,
    label: 'PDF Converter',
    icon: Icons.picture_as_pdf_outlined,
    selectedIcon: Icons.picture_as_pdf_rounded,
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

class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({
    super.key,
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
                GlassIconButton(
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
                  GlassIconButton(
                    icon: Icons.keyboard_double_arrow_left_rounded,
                    tooltip: 'Collapse sidebar',
                    onTap: onToggle,
                  ),
                ],
              ),
            ),
          const SizedBox(height: StilloraSpacing.md),
          if (!collapsed) ...[
            const SidebarLabel('Workspace'),
            const SizedBox(height: StilloraSpacing.xs),
          ],
          // Scrolls when the window is short or the item list grows, so the
          // nav never overflows and the ad + footer stay pinned below. A
          // SingleChildScrollView (not ListView) builds every item even when
          // off-screen, so all nav destinations stay reachable/testable.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: collapsed
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  for (final item in _navItems)
                    DesktopNavItem(
                      selected: item.index == activeIndex,
                      icon: item.icon,
                      selectedIcon: item.selectedIcon,
                      label: item.label,
                      collapsed: collapsed,
                      onTap: () => onSelect(item.index),
                    ),
                ],
              ),
            ),
          ),
          if (!collapsed) ...[
            const AdSlotWidget(
              placement: 'USER_DASHBOARD_LEFT',
              campaignKey: 'stilloraside',
            ),
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

class SidebarLabel extends StatelessWidget {
  const SidebarLabel(this.text, {super.key});
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

class DesktopNavItem extends StatefulWidget {
  const DesktopNavItem({
    super.key,
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
  State<DesktopNavItem> createState() => _DesktopNavItemState();
}

class _DesktopNavItemState extends State<DesktopNavItem> {
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
