import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';
import 'stillora_mark.dart';

/// Route that hosts the main tabbed home. Kept here so the shell can navigate
/// to it without importing the tabs screen (avoids an import cycle).
const kHomeRoute = '/home';

/// Currently selected home tab. Lets other screens jump to a specific tab
/// before navigating back to the home shell.
final homeTabProvider = StateProvider<int>((ref) => 0);

const _navItems = [
  (
    label: 'Create',
    icon: Icons.add_photo_alternate_outlined,
    selectedIcon: Icons.add_photo_alternate_rounded,
  ),
  (
    label: 'Library',
    icon: Icons.video_library_outlined,
    selectedIcon: Icons.video_library_rounded,
  ),
  (
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
            colors: [Color(0xff090613), Color(0xff050610), Color(0xff030309)],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: 204,
                child: _DesktopSidebar(
                  activeIndex: activeIndex,
                  onSelect: (index) => _select(context, ref, index),
                ),
              ),
              Container(width: 1, color: StilloraColors.glassStroke),
              Expanded(
                child: Column(
                  children: [
                    _DesktopTopBar(title: title, trailing: trailing),
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
  const _DesktopSidebar({required this.activeIndex, required this.onSelect});

  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              StilloraMark(size: 34),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stillora',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < _navItems.length; i++)
            _DesktopNavItem(
              selected: i == activeIndex,
              icon: _navItems[i].icon,
              selectedIcon: _navItems[i].selectedIcon,
              label: _navItems[i].label,
              onTap: () => onSelect(i),
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
                    size: 18,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Local desktop workspace',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Files stay on this computer while you build exports.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                  size: 20,
                  color: selected
                      ? StilloraColors.primary
                      : StilloraColors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
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
  const _DesktopTopBar({required this.title, required this.trailing});

  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (canPop) ...[
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
              const SizedBox(width: StilloraSpacing.xs),
            ],
            Expanded(
              child: Text(
                title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
