import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/preview_metrics.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/section_split_view.dart';
import 'convert_state.dart';
import '../../core/i18n/app_strings.dart';

/// Standalone "Convert" section: pick a batch of images (HEIC, WebP, TIFF, …)
/// and convert them all to JPEG or PNG. Saved to Photos on mobile and to a
/// "Stillora Converted" folder on desktop.
class ConvertView extends ConsumerStatefulWidget {
  const ConvertView({super.key});

  @override
  ConsumerState<ConvertView> createState() => _ConvertViewState();
}

class _ConvertViewState extends ConsumerState<ConvertView> {
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      final result = await ref.read(convertControllerProvider.notifier).run();
      if (!mounted) return;
      final msg = result.converted == 0
          ? context.strings.cvNothingConverted
          : '${context.strings.cvConvertedCount} ${result.converted} → ${result.destination}'
                '${result.failed > 0 ? ' · ${result.failed} ${context.strings.cvFailedCount}' : ''}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final convert = ref.watch(convertControllerProvider);
    final controller = ref.read(convertControllerProvider.notifier);

    // Desktop: the file list and format controls scroll on the left while the
    // picked images stay visible in the right-hand pane, so the batch being
    // converted is always in sight. Phones show the same grid on top.
    return DecoratedBox(
      decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: SectionSplitView(
          onStartOver: controller.clear,
          canStartOver: convert.hasImages && !_running,
          hasPreview: convert.hasImages,
          previewCaption: convert.hasImages
              ? '${convert.paths.length} image'
                    '${convert.paths.length == 1 ? '' : 's'} → '
                    '${convert.format.label}'
              : null,
          preview: _ConvertPreview(paths: convert.paths),
          controls: [
            Text(
              'Pick images in any format (HEIC, WebP, TIFF, BMP…) and convert '
              'them all to JPEG or PNG.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Add images
            StilloraGlassCard(
              onTap: _running ? null : controller.pickImages,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.add_photo_alternate_rounded,
                    color: StilloraColors.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      convert.hasImages
                          ? context.strings.cvAddMoreImages
                          : context.strings.cvSelectImages,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),

            if (convert.hasImages) ...[
              const SizedBox(height: 12),
              // Clearing the whole batch is the shared "Start over" control
              // pinned above the controls column.
              Text(
                '${convert.paths.length} selected',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              for (var i = 0; i < convert.paths.length; i++)
                _ImageRow(
                  path: convert.paths[i],
                  onRemove: _running ? null : () => controller.removeAt(i),
                ),
              const SizedBox(height: 12),

              // Output format
              Text(
                context.strings.cvConvertTo,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ConvertFormat>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ConvertFormat.jpeg,
                      label: Text('JPEG'),
                    ),
                    ButtonSegment(value: ConvertFormat.png, label: Text('PNG')),
                  ],
                  selected: {convert.format},
                  onSelectionChanged: _running
                      ? null
                      : (v) => controller.setFormat(v.first),
                ),
              ),
              const SizedBox(height: 12),

              // Export destination
              Text(
                context.strings.cvExportTo,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              StilloraGlassCard(
                onTap: _running ? null : controller.pickOutputFolder,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      convert.hasOutputDir
                          ? Icons.folder_rounded
                          : Icons.folder_outlined,
                      size: 20,
                      color: StilloraColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            convert.hasOutputDir
                                ? convert.outputDirName!
                                : context.strings.cvDefaultLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            convert.hasOutputDir
                                ? convert.outputDir!
                                : (isDesktopPlatform
                                      ? 'Downloads › Stillora Converted'
                                      : context.strings.cvSavedToPhotos),
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
                    if (convert.hasOutputDir)
                      IconButton(
                        onPressed: _running
                            ? null
                            : controller.clearOutputFolder,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        tooltip: context.strings.cvUseDefaultLocation,
                        color: StilloraColors.onSurfaceVariant,
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: StilloraColors.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              StilloraPrimaryButton(
                onPressed: _running ? null : _run,
                icon: Icons.transform_rounded,
                label: _running
                    ? context.strings.loopConverting
                    : '${context.strings.cvConvertTo2} ${convert.paths.length} '
                          '${context.strings.cvTo} ${convert.format.label}',
              ),
              if (_running) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
            const SizedBox(height: 16),
            const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
          ],
        ),
      ),
    );
  }
}

/// Live preview for the Convert section: a thumbnail grid of everything queued
/// up. Sources like HEIC that Flutter can't decode fall back to a file icon, so
/// the tile count still mirrors the batch exactly.
class _ConvertPreview extends StatelessWidget {
  const _ConvertPreview({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: StilloraColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(StilloraRadius.card),
          border: Border.all(color: StilloraColors.glassStroke),
        ),
        child: SizedBox(
          // The placeholder never needs the full preview budget — keep it the
          // shorter of the two so an empty section stays compact.
          height: math.min(220.0, mobilePreviewMaxHeight(context)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 34,
                    color: StilloraColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.strings.cvEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StilloraColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final grid = GridView.builder(
      shrinkWrap: true,
      primary: false,
      padding: EdgeInsets.zero,
      itemCount: paths.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, i) => ClipRRect(
        borderRadius: BorderRadius.circular(StilloraRadius.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: StilloraColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(StilloraRadius.md),
          ),
          child: Image.file(
            File(paths[i]),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(
              child: Icon(
                Icons.image_outlined,
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );

    // Stacked layout: a fifty-image batch would otherwise grow the thumbnail
    // grid past the bottom of the screen. Cap it and let it scroll in place —
    // in the desktop pane the height is already bounded.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? grid
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: mobilePreviewMaxHeight(context),
              ),
              child: grid,
            ),
    );
  }
}

class _ImageRow extends StatelessWidget {
  const _ImageRow({required this.path, required this.onRemove});

  final String path;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final name = path.split(RegExp(r'[/\\]')).last;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: StilloraGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.image_outlined, size: 20, color: StilloraColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              color: StilloraColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
