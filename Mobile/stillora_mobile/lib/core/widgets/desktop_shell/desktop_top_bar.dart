import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/stillora_colors.dart';
import '../../design/stillora_spacing.dart';
import 'glass_icon_button.dart';

/// Short descriptive subtitle per section, shown under the title in the desktop
/// header so the chrome feels intentional rather than a bare app-bar.
const _sectionSubtitles = {
  'Create': 'Turn images into video, on this device',
  'Text': 'Add animated captions & titles onto a video',
  'Watermark': 'Add a logo or overlay onto a video',
  'Library': 'Every render you\'ve made',
  'HTML': 'Capture any web page as a clip',
  'Remove Silence': 'Auto-cut the quiet gaps from a video',
  'Speed': 'Speed up a video 1x–4x, mute or add audio',
  'Compress': 'Shrink a video to a smaller MP4',
  'Convert': 'Batch-convert HEIC & others to JPEG/PNG',
  'Loop images': 'Batch loops & slideshows',
  'Info': 'Account & subscription',
};

class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
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
            GlassIconButton(
              icon: Icons.view_sidebar_outlined,
              tooltip: 'Toggle sidebar',
              onTap: onToggleSidebar!,
            ),
            const SizedBox(width: StilloraSpacing.snug),
          ],
          if (canPop) ...[
            GlassIconButton(
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
