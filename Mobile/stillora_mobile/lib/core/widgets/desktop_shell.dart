import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';
import '../platform/platform_info.dart';
import 'desktop_shell/desktop_sidebar.dart';
import 'desktop_shell/desktop_top_bar.dart';

export 'desktop_shell/desktop_sidebar.dart';
export 'desktop_shell/desktop_top_bar.dart';
export 'desktop_shell/glass_icon_button.dart';

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
                  child: DesktopSidebar(
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
                    DesktopTopBar(
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
