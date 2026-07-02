import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/ad_widget.dart';
import 'convert_state.dart';

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
          ? 'Nothing converted.'
          : 'Converted ${result.converted} → ${result.destination}'
              '${result.failed > 0 ? ' · ${result.failed} failed' : ''}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final convert = ref.watch(convertControllerProvider);
    final controller = ref.read(convertControllerProvider.notifier);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
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
                  const Icon(Icons.add_photo_alternate_rounded,
                      color: StilloraColors.primary, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      convert.hasImages
                          ? 'Add more images'
                          : 'Select images',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: StilloraColors.onSurfaceVariant),
                ],
              ),
            ),

            if (convert.hasImages) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('${convert.paths.length} selected',
                      style: Theme.of(context).textTheme.labelMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _running ? null : controller.clear,
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (var i = 0; i < convert.paths.length; i++)
                _ImageRow(
                  path: convert.paths[i],
                  onRemove:
                      _running ? null : () => controller.removeAt(i),
                ),
              const SizedBox(height: 12),

              // Output format
              Text('Convert to',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ConvertFormat>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                        value: ConvertFormat.jpeg, label: Text('JPEG')),
                    ButtonSegment(
                        value: ConvertFormat.png, label: Text('PNG')),
                  ],
                  selected: {convert.format},
                  onSelectionChanged:
                      _running ? null : (v) => controller.setFormat(v.first),
                ),
              ),
              const SizedBox(height: 12),

              // Export destination
              Text('Export to',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              StilloraGlassCard(
                onTap: _running ? null : controller.pickOutputFolder,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                : 'Default location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            convert.hasOutputDir
                                ? convert.outputDir!
                                : (isDesktopPlatform
                                    ? 'Downloads › Stillora Converted'
                                    : 'Saved to Photos'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: StilloraColors.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (convert.hasOutputDir)
                      IconButton(
                        onPressed:
                            _running ? null : controller.clearOutputFolder,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        tooltip: 'Use default location',
                        color: StilloraColors.onSurfaceVariant,
                      )
                    else
                      const Icon(Icons.chevron_right_rounded,
                          color: StilloraColors.onSurfaceVariant),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              StilloraPrimaryButton(
                onPressed: _running ? null : _run,
                icon: Icons.transform_rounded,
                label: _running
                    ? 'Converting…'
                    : 'Convert ${convert.paths.length} to ${convert.format.label}',
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
            const Icon(Icons.image_outlined,
                size: 20, color: StilloraColors.primary),
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
