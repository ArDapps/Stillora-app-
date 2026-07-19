import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/platform/media_actions.dart';
import '../../../core/widgets/render_panel.dart';
import '../loop_images_controller.dart';

class LoopCard extends ConsumerWidget {
  const LoopCard({super.key, required this.item});

  final LoopItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(
      loopImagesControllerProvider.select((s) => s.isRunning),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StilloraColors.surfaceDim,
          border: Border.all(color: StilloraColors.panelBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(item.path), fit: BoxFit.cover),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: LoopStatusBadge(item: item),
                  ),
                  if (!running)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: LoopRoundIcon(
                        icon: Icons.close_rounded,
                        onTap: () => ref
                            .read(loopImagesControllerProvider.notifier)
                            .remove(item.id),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.status == LoopItemStatus.done &&
                      item.resultPath != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      tooltip: 'Share video',
                      onPressed: () =>
                          MediaActions.shareVideo(context, item.resultPath!),
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoopStatusBadge extends StatelessWidget {
  const LoopStatusBadge({super.key, required this.item});

  final LoopItem item;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final String text;
    Widget? leading;
    switch (item.status) {
      case LoopItemStatus.rendering:
        bg = StilloraColors.accent;
        text = 'Rendering';
        leading = const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
      case LoopItemStatus.done:
        bg = const Color(0xff16a34a);
        text = 'Done';
      case LoopItemStatus.error:
        bg = const Color(0xffdc2626);
        text = 'Failed';
      case LoopItemStatus.ready:
        bg = Colors.black.withValues(alpha: 0.6);
        text = 'Ready';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 5)],
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class LoopRoundIcon extends StatelessWidget {
  const LoopRoundIcon({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
