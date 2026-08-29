import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/preview_metrics.dart';
import '../../../core/design/render_components.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/i18n/app_strings.dart';
import '../store_screenshots_state.dart';

/// The live preview: the picked screens as a thumbnail grid, each shown inside
/// the shape of the first selected size so the letterboxing (or the crop) is
/// visible before anything is rendered.
class ShotQueuePanel extends ConsumerWidget {
  const ShotQueuePanel({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeScreenshotsControllerProvider);
    final controller = ref.read(storeScreenshotsControllerProvider.notifier);

    if (!state.hasImages) {
      return RenderDropZone(
        icon: Icons.add_photo_alternate_outlined,
        title: context.strings.ssDropHint,
        hint: context.strings.ssEmpty,
        onTap: onAdd,
      );
    }

    // Shape every tile like the first selected size, so a 9:16 phone shot and
    // a 16:10 Mac shot preview differently — which is the whole question the
    // user is asking of this panel.
    final targets = state.selectedTargets;
    final ratio = targets.isEmpty
        ? 9 / 16
        : () {
            final size = targets.first.resolve(landscape: state.landscape);
            return size.width / size.height;
          }();

    final grid = GridView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: ratio.clamp(0.4, 2.4),
      ),
      itemCount: state.paths.length,
      itemBuilder: (context, i) => _ShotTile(
        path: state.paths[i],
        index: i,
        fit: state.fit,
        background: state.background,
        onRemove: () => controller.removeAt(i),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            RenderTagPill(context.strings.ssImageCount(state.paths.length)),
            const SizedBox(width: StilloraSpacing.xs),
            Expanded(
              child: Text(
                context.strings.ssOutputCount(
                  state.outputCount,
                  state.selectedTargetIds.length,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: StilloraColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: StilloraSpacing.xs),
        // Stacked on a phone the grid has no height limit of its own, so a
        // 20-screen queue would push every control off the bottom. It caps out
        // and scrolls inside itself instead, like the PDF page list.
        LayoutBuilder(
          builder: (context, constraints) => constraints.hasBoundedHeight
              ? grid
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: mobilePreviewBoxHeight(context, chrome: 40),
                  ),
                  child: SingleChildScrollView(child: grid),
                ),
        ),
      ],
    );
  }
}

class _ShotTile extends StatelessWidget {
  const _ShotTile({
    required this.path,
    required this.index,
    required this.fit,
    required this.background,
    required this.onRemove,
  });

  final String path;
  final int index;
  final ShotFit fit;
  final ShotBackground background;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final rgb = background.rgb;
    return ClipRRect(
      borderRadius: BorderRadius.circular(StilloraRadius.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // The same opaque fill the exporter flattens onto, so the preview
          // shows the bars the user will actually get.
          color: Color.fromARGB(255, rgb.r, rgb.g, rgb.b),
          borderRadius: BorderRadius.circular(StilloraRadius.md),
          border: Border.all(color: StilloraColors.glassStroke),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: fit == ShotFit.fit ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (context, _, _) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: StilloraColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            Positioned(left: 4, top: 4, child: _Chip(label: '${index + 1}')),
            Positioned(
              right: 2,
              top: 2,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 14),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(24, 24),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(StilloraRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Progress line shown while the renderer is working through the matrix.
class ShotProgressBar extends StatelessWidget {
  const ShotProgressBar({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : math.min(1.0, done / total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(StilloraRadius.pill),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: StilloraColors.surfaceDim,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.strings.ssProgress(done, total),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
