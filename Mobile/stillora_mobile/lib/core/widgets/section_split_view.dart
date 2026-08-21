import 'package:flutter/material.dart';

import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';
import '../platform/platform_info.dart';
import 'start_over_button.dart';
import '../i18n/app_strings.dart';

/// Desktop preview-panel width, scaled to the window so a wide display gets a
/// genuinely useful preview instead of a thumbnail floating in empty space.
double _previewWidth(double maxWidth) {
  if (maxWidth >= 1500) return 520;
  if (maxWidth >= 1240) return 460;
  return 400;
}

/// Below this content width the two-pane split would squeeze the controls, so
/// the section falls back to the stacked single-column layout.
const double _splitMinWidth = 860;

/// Standard section layout for the desktop app: the controls scroll on the
/// LEFT, while a pinned live [preview] panel sits on the RIGHT so every slider,
/// toggle and overlay edit is reflected without scrolling.
///
/// On phones/tablets — or a desktop window too narrow to split — it collapses
/// back to one scrolling column with the preview at the top.
class SectionSplitView extends StatelessWidget {
  const SectionSplitView({
    super.key,
    required this.controls,
    required this.preview,
    this.previewCaption,
    this.previewActions,
    this.onStartOver,
    this.canStartOver = true,
    this.mobilePadding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
  });

  /// Left column children (already spaced by the caller).
  final List<Widget> controls;

  /// Content of the right-hand preview panel.
  final Widget preview;

  /// One-liner under the preview explaining what it shows.
  final String? previewCaption;

  /// Optional controls pinned under the preview (e.g. the export button).
  final Widget? previewActions;

  /// Clears this section's inputs. When set, a "Start over" button is pinned at
  /// the top-right of the controls column — same place on every tab, so it is
  /// always one click away and never scrolls off with the controls.
  final VoidCallback? onStartOver;

  /// False when there is nothing loaded yet, greying the button out.
  final bool canStartOver;

  final EdgeInsets mobilePadding;

  Widget? _startOverBar() {
    final reset = onStartOver;
    if (reset == null) return null;
    return Align(
      alignment: Alignment.centerRight,
      child: StartOverButton(onReset: reset, enabled: canStartOver),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startOver = _startOverBar();
    return LayoutBuilder(
      builder: (context, constraints) {
        final split =
            useDesktopLayout(context) && constraints.maxWidth >= _splitMinWidth;

        if (!split) {
          return ListView(
            padding: mobilePadding,
            children: [
              if (startOver != null) startOver,
              LivePreviewPanel(
                caption: previewCaption,
                actions: previewActions,
                fill: false,
                child: preview,
              ),
              const SizedBox(height: StilloraSpacing.sm),
              ...controls,
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            StilloraSpacing.md,
            StilloraSpacing.sm,
            StilloraSpacing.md,
            StilloraSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pinned above the scroll area so it stays reachable no
                    // matter how far down the controls the user has scrolled.
                    if (startOver != null) startOver,
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(
                          right: StilloraSpacing.xs,
                          bottom: StilloraSpacing.md,
                        ),
                        children: controls,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: StilloraSpacing.md),
              SizedBox(
                width: _previewWidth(constraints.maxWidth),
                child: LivePreviewPanel(
                  caption: previewCaption,
                  actions: previewActions,
                  child: preview,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The right-hand panel chrome: an eyebrow, the live [child] preview centred in
/// the remaining space, an optional caption and optional pinned [actions].
class LivePreviewPanel extends StatelessWidget {
  const LivePreviewPanel({
    super.key,
    required this.child,
    this.caption,
    this.actions,
    this.fill = true,
  });

  final Widget child;
  final String? caption;
  final Widget? actions;

  /// True when the panel has a bounded height (the desktop pane) and the
  /// preview should expand to fill it; false inside a scrolling column.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final centred = Center(child: child);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.visibility_rounded,
              size: 14,
              color: StilloraColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              context.strings.livePreview.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: StilloraSpacing.snug),
        if (fill) Expanded(child: centred) else centred,
        if (caption != null) ...[
          const SizedBox(height: StilloraSpacing.snug),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ],
        if (actions != null) ...[
          const SizedBox(height: StilloraSpacing.sm),
          actions!,
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.sm),
      decoration: BoxDecoration(
        color: StilloraColors.surfaceContainerLow.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(StilloraRadius.xl),
        border: Border.all(color: StilloraColors.glassStroke),
      ),
      child: body,
    );
  }
}
