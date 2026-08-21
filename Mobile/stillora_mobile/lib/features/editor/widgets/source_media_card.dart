import 'package:flutter/material.dart';

import '../../../core/format/duration_label.dart';
import '../../../core/design/render_components.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../editor_state.dart';
import 'editor_shared.dart';
import 'media_timeline.dart';
import '../../../core/i18n/app_strings.dart';

class SourceMediaCard extends StatelessWidget {
  const SourceMediaCard({
    super.key,
    required this.editor,
    required this.controller,
    this.compact = false,
  });

  final EditorState editor;
  final EditorController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RenderStepCard(
      number: '1',
      title: context.strings.edSourceMedia,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!editor.hasMedia)
            _MediaDropZone(onTap: controller.pickMedia, compact: compact)
          else ...[
            MediaTimeline(
              editor: editor,
              controller: controller,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : StilloraSpacing.sm),
            Text(
              _mediaSummary(editor),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: compact ? 8 : StilloraSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.addMedia,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.strings.edAddMore),
                  ),
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickMedia,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.strings.edReplace),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _mediaSummary(EditorState editor) {
    final totalCount = editor.media.length;
    final totalDuration = formatDurationClock(editor.totalDurationSeconds);
    if (editor.exportsMixedTimeline) {
      return '$totalCount assets · $totalDuration total. Tap a clip’s time to trim it, drag to reorder.';
    }
    if (editor.exportsImageSlideshow && totalCount > 1) {
      return '$totalCount images · $totalDuration total. Tap a clip’s time to trim it, drag to reorder.';
    }
    if (editor.exportsVideoSource) {
      return 'Selected video exports as a $totalDuration MP4. Tap the clip time to change its length.';
    }
    return 'Selected $totalCount item${totalCount == 1 ? '' : 's'} · $totalDuration total.';
  }
}

class _MediaDropZone extends StatelessWidget {
  const _MediaDropZone({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: StilloraColors.surfaceContainerLowest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        border: Border.all(
          color: StilloraColors.outlineVariant,
          width: compact ? 1 : 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : StilloraSpacing.md),
          child: compact
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.perm_media_rounded,
                      color: StilloraColors.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.strings.edChooseMedia,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            context.strings.edDragToReorder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: StilloraColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.perm_media_rounded,
                      color: StilloraColors.primary,
                      size: 48,
                    ),
                    const SizedBox(height: StilloraSpacing.xs),
                    Text(
                      context.strings.edChooseMedia,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: StilloraSpacing.xs),
                    Text(
                      context.strings.edSelectThenReorder,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StilloraRadius.full),
      child: compact
          ? SizedBox(height: 116, child: content)
          : AspectRatio(aspectRatio: 1.6, child: content),
    );
  }
}
