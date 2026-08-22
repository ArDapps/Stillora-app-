import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/tabs/app_sections.dart';
import '../../design/stillora_colors.dart';
import '../../design/stillora_spacing.dart';
import '../../i18n/app_strings.dart';
import '../ad_widget.dart';
import '../stillora_mark.dart';
import 'glass_icon_button.dart';

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
    final strings = context.strings;
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
                  tooltip: strings.expandSidebar,
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
                    tooltip: strings.collapseSidebar,
                    onTap: onToggle,
                  ),
                ],
              ),
            ),
          const SizedBox(height: StilloraSpacing.md),
          // Tools, grouped under quiet headings (CREATE / VIDEO TOOLS /
          // DOCUMENT TOOLS / YOUR CONTENT). Scrolls when the window is short or
          // the list grows, so the nav never overflows and the ACCOUNT / APP
          // footer, ad and privacy line stay pinned below. A
          // SingleChildScrollView (not ListView) builds every item even when
          // off-screen, so all nav destinations stay reachable/testable.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: collapsed
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  for (final group in navToolGroups)
                    if (group.availableSections.isNotEmpty) ...[
                      if (!collapsed) ...[
                        SidebarLabel(group.group.label(strings)),
                        const SizedBox(height: StilloraSpacing.xs),
                      ],
                      for (final section in group.availableSections)
                        DesktopNavItem(
                          selected: section.viewIndex == activeIndex,
                          icon: section.icon,
                          selectedIcon: section.selectedIcon,
                          label: section.title(strings),
                          collapsed: collapsed,
                          onTap: () => onSelect(section.viewIndex),
                        ),
                      SizedBox(
                        height: collapsed
                            ? StilloraSpacing.xs
                            : StilloraSpacing.base,
                      ),
                    ],
                ],
              ),
            ),
          ),
          // ACCOUNT / APP: Stillora Pro + Info, pinned above the privacy line.
          if (!collapsed) ...[
            SidebarLabel(navFooterGroup.group.label(strings)),
            const SizedBox(height: StilloraSpacing.xs),
          ],
          for (final section in navFooterGroup.availableSections)
            DesktopNavItem(
              selected: section.viewIndex == activeIndex,
              icon: section.icon,
              selectedIcon: section.selectedIcon,
              label: section.title(strings),
              collapsed: collapsed,
              premium: section == AppSection.stilloraPro,
              onTap: () => onSelect(section.viewIndex),
            ),
          if (!collapsed) ...[
            const SizedBox(height: StilloraSpacing.base),
            const AdSlotWidget(
              placement: 'USER_DASHBOARD_LEFT',
              campaignKey: 'stilloraside',
            ),
            const SizedBox(height: StilloraSpacing.snug),
            Row(
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: StilloraColors.secondary,
                  size: 15,
                ),
                const SizedBox(width: StilloraSpacing.base + 2),
                Expanded(
                  child: Text(
                    strings.filesStayOnComputer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StilloraColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Icon(
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
        // Brand violet rather than the nav-item grey: the heading has to read
        // as a *heading*, not as another (disabled-looking) destination. Sized
        // and weighted up for the same reason.
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: StilloraColors.accentText,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w900,
          fontSize: 12,
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
    this.premium = false,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;
  final bool collapsed;

  /// Marks the Stillora Pro entry. It gets a warm premium tint instead of the
  /// muted nav grey — enough to read as special, not enough to look like an ad.
  final bool premium;

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
        : widget.premium
        ? StilloraColors.brandCyan
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
                    ? LinearGradient(
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
                          : widget.premium
                          ? StilloraColors.brandCyan.withValues(alpha: 0.07)
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
                                    fontWeight: selected || widget.premium
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
