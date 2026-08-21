import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/format/duration_label.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_glow.dart';
import '../../../core/design/stillora_spacing.dart';
import '../editor_state.dart';
import 'clip_duration_sheet.dart';
import 'editor_shared.dart';

class MediaTimeline extends StatelessWidget {
  const MediaTimeline({
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
    return SizedBox(
      height: compact ? 96 : 124,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, _, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + animation.value * 0.04,
                child: Material(color: Colors.transparent, child: child),
              );
            },
            child: child,
          );
        },
        onReorder: controller.reorderMedia,
        itemCount: editor.media.length,
        itemBuilder: (context, index) {
          final item = editor.media[index];
          return Padding(
            key: ValueKey(item.path),
            padding: const EdgeInsets.only(right: StilloraSpacing.xs),
            child: SizedBox(
              width: compact ? 76 : 96,
              child: _MediaThumb(
                index: index,
                item: item,
                durationLabel: formatDurationClock(item.durationSeconds),
                selected: index == editor.selectedIndex,
                onTap: () => controller.selectMedia(index),
                onRemove: () => controller.removeMediaAt(index),
                onEditDuration: () => _editClipDuration(context, index, item),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editClipDuration(
    BuildContext context,
    int index,
    MediaItem item,
  ) async {
    controller.selectMedia(index);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StilloraColors.surfaceContainerLow,
      showDragHandle: true,
      builder: (sheetContext) => ClipDurationSheet(
        clipNumber: index + 1,
        isVideo: item.kind == MediaKind.video,
        initialSeconds: item.durationSeconds,
        initialVolume: item.volume,
        onChanged: (seconds) => controller.setClipDuration(index, seconds),
        onVolumeChanged: (volume) => controller.setClipVolume(index, volume),
      ),
    );
  }
}

class _TimelineBadge extends StatelessWidget {
  const _TimelineBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: stilloraBrandGradient,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: SizedBox.square(
        dimension: 22,
        child: Center(
          child: Text(
            '${index + 1}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({
    required this.index,
    required this.item,
    required this.durationLabel,
    required this.selected,
    required this.onTap,
    required this.onRemove,
    required this.onEditDuration,
  });

  final int index;
  final MediaItem item;
  final String durationLabel;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onEditDuration;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(StilloraRadius.full);
    final durationForeground = selected
        ? Colors.white
        : StilloraColors.onSurfaceVariant;

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: selected
                          ? StilloraColors.primary
                          : StilloraColors.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: item.kind == MediaKind.image
                        ? Image.file(File(item.path), fit: BoxFit.cover)
                        : ColoredBox(
                            color: StilloraColors.surfaceContainerLowest,
                            child: Center(
                              child: Icon(
                                Icons.play_circle_outline_rounded,
                                color: StilloraColors.primary,
                                size: 32,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (item.kind == MediaKind.video)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Icon(
                    Icons.videocam_rounded,
                    size: 16,
                    color: StilloraColors.onSurface,
                  ),
                ),
              if (item.kind == MediaKind.video && item.isMuted)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    Icons.volume_off_rounded,
                    size: 16,
                    color: StilloraColors.onSurface,
                  ),
                ),
              Positioned(
                left: 4,
                bottom: 4,
                child: _TimelineBadge(index: index),
              ),
              Positioned(
                right: 4,
                top: 30,
                child: ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: StilloraColors.surfaceContainerLowest.withValues(
                        alpha: 0.75,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 16,
                      color: StilloraColors.onSurface,
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: StilloraColors.primary,
                  ),
                ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: StilloraColors.surfaceContainerLowest.withValues(
                        alpha: 0.7,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: StilloraColors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEditDuration,
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                gradient: selected ? stilloraBrandGradient : null,
                color: selected
                    ? null
                    : StilloraColors.surfaceContainerLowest.withValues(
                        alpha: 0.8,
                      ),
                borderRadius: BorderRadius.circular(StilloraRadius.full),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.24)
                      : StilloraColors.glassStroke,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: durationForeground,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      durationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: durationForeground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.edit_rounded, size: 11, color: durationForeground),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
