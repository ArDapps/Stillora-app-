import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/stillora_colors.dart';
import '../../design/stillora_spacing.dart';
import '../../i18n/app_strings.dart';
import 'glass_icon_button.dart';

class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.onToggleSidebar,
  });

  final String? title;

  /// Short descriptive line under the title, so the chrome feels intentional
  /// rather than a bare app-bar. Supplied by the caller (translated) instead of
  /// looked up from the English title.
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    final strings = context.strings;
    // Local copy so the null check below promotes (public fields don't).
    final subtitle = this.subtitle;
    return Container(
      height: StilloraSpacing.desktopTopBarHeight + 8,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: StilloraColors.glassStroke)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: StilloraSpacing.md),
      child: Row(
        children: [
          if (onToggleSidebar != null) ...[
            GlassIconButton(
              icon: Icons.view_sidebar_outlined,
              tooltip: strings.toggleSidebar,
              onTap: onToggleSidebar!,
            ),
            const SizedBox(width: StilloraSpacing.snug),
          ],
          if (canPop) ...[
            GlassIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: strings.back,
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
