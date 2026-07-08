import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import 'editor_state.dart' show formatFileSize;
import 'reel_state.dart';
import 'video_preset.dart';

const _reelAudioExtensions = ['mp3', 'm4a', 'aac', 'wav', 'ogg'];

class ReelView extends ConsumerWidget {
  const ReelView({super.key});

  Future<void> _pickAudio(WidgetRef ref) async {
    final result = await pickImportFiles(
      type: FileType.custom,
      allowedExtensions: _reelAudioExtensions,
    );
    final path = result?.files.single.path;
    if (path != null) {
      await ref.read(reelControllerProvider.notifier).setAudioPath(path);
    }
  }

  Future<void> _runExport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await ref
          .read(reelControllerProvider.notifier)
          .exportBase();
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? 'Add an app video before exporting.'
                : 'Saved to Library - ${result.width}x${result.height}',
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reel = ref.watch(reelControllerProvider);
    final controller = ref.read(reelControllerProvider.notifier);
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _ModeSection(reel: reel, controller: controller),
            const SizedBox(height: 16),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 420,
                  maxWidth: 460,
                ),
                child: AspectRatio(
                  aspectRatio: reel.aspectRatio,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: StilloraColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(StilloraRadius.full),
                      border: Border.all(
                        color: StilloraColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(StilloraRadius.full),
                      child: _ReelPreview(
                        reel: reel,
                        onPick: controller.addMedia,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (reel.hasMedia) ...[
              _DurationBanner(reel: reel),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: controller.addMedia,
                icon: const Icon(Icons.video_call_rounded),
                label: Text(
                  reel.isMockupMode ? 'Replace app video' : 'Replace media',
                ),
              ),
              const SizedBox(height: 12),
              _AudioRow(
                reel: reel,
                onPick: () => _pickAudio(ref),
                onRemove: controller.removeAudio,
              ),
              const SizedBox(height: 16),
              _FormatExportSection(
                reel: reel,
                controller: controller,
                onExport: () => _runExport(context, ref),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.reset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Clear reel'),
                ),
              ),
            ] else
              _PickCard(onPick: controller.addMedia, mockup: reel.mockup),
          ],
        ),
      ),
    );
  }
}

class _ModeSection extends StatelessWidget {
  const _ModeSection({required this.reel, required this.controller});

  final ReelState reel;
  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3D video reel', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final mockup in ReelMockup.values) ...[
                  _Chip(
                    label: mockup.label,
                    selected: reel.mockup == mockup,
                    onTap: () => controller.setMockup(mockup),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelPreview extends StatefulWidget {
  const _ReelPreview({required this.reel, required this.onPick});

  final ReelState reel;
  final VoidCallback onPick;

  @override
  State<_ReelPreview> createState() => _ReelPreviewState();
}

class _ReelPreviewState extends State<_ReelPreview>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  String? _path;
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _ReelPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final path = widget.reel.base?.path;
    if (path == _path) return;
    _path = path;
    final old = _controller;
    _controller = null;
    old?.dispose();
    if (path == null || widget.reel.base?.isVideo != true) {
      setState(() {});
      return;
    }
    final controller = VideoPlayerController.file(File(path));
    _controller = controller;
    controller
        .initialize()
        .then((_) {
          controller
            ..setLooping(true)
            ..setVolume(0)
            ..play();
          if (mounted) setState(() {});
        })
        .catchError((_) {});
    setState(() {});
  }

  @override
  void dispose() {
    _motion.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.reel.base;
    final video = _controller;
    if (base == null) {
      return _EmptyPreview(onPick: widget.onPick, mockup: widget.reel.mockup);
    }
    if (!base.isVideo) {
      return Image.file(File(base.path), fit: BoxFit.cover);
    }
    if (video == null || !video.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!widget.reel.isMockupMode) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: video.value.size.width,
          height: video.value.size.height,
          child: VideoPlayer(video),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, _) {
        final t = _motion.value * math.pi * 2;
        final android = widget.reel.mockup == ReelMockup.androidGraphite;
        final tilt = (android ? 0.14 : -0.14) + math.sin(t) * 0.07;
        final lift = math.sin(t * 1.18) * 9;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff11071f), Color(0xff05131d), Color(0xff08080d)],
            ),
          ),
          child: Center(
            child: FractionallySizedBox(
              heightFactor: 0.78,
              child: AspectRatio(
                aspectRatio: android ? 0.5 : 0.48,
                child: Transform.translate(
                  offset: Offset(0, lift),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(tilt)
                      ..rotateX(math.sin(t * 0.7) * 0.05)
                      ..rotateZ(math.sin(t * 0.65) * 0.025),
                    child: _PhoneFrame(
                      mockup: widget.reel.mockup,
                      controller: video,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.mockup, required this.controller});

  final ReelMockup mockup;
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final android = mockup == ReelMockup.androidGraphite;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(android ? 34 : 44),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: android
              ? const [Color(0xff1f2937), Color(0xff020617)]
              : const [Color(0xff475569), Color(0xff0f172a)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          android ? 13 : 14,
          android ? 16 : 18,
          android ? 13 : 14,
          android ? 15 : 16,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(android ? 26 : 34),
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: android ? 10 : 82,
                height: android ? 10 : 22,
                margin: EdgeInsets.only(top: android ? 9 : 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationBanner extends StatelessWidget {
  const _DurationBanner({required this.reel});

  final ReelState reel;

  @override
  Widget build(BuildContext context) {
    final seconds = reel.outputDurationSeconds;
    return StilloraGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            color: StilloraColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              seconds > 0
                  ? 'Output ${_formatDuration(seconds)} - ${reel.hasAudio ? 'matches audio' : 'matches app video'}'
                  : 'Measuring length...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioRow extends StatelessWidget {
  const _AudioRow({
    required this.reel,
    required this.onPick,
    required this.onRemove,
  });

  final ReelState reel;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      onTap: reel.hasAudio ? null : onPick,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.music_note_rounded,
            color: StilloraColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reel.hasAudio
                  ? 'Audio added - sets reel length'
                  : 'Add audio (optional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (reel.hasAudio)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              tooltip: 'Remove audio',
            )
          else
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _FormatExportSection extends StatelessWidget {
  const _FormatExportSection({
    required this.reel,
    required this.controller,
    required this.onExport,
  });

  final ReelState reel;
  final ReelController controller;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final res = reel.outputResolution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Format & export', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in videoPresets) ...[
                _Chip(
                  label: '${preset.label} - ${preset.ratioLabel}',
                  selected: preset.id == reel.preset.id,
                  onTap: () => controller.setPreset(preset),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ExportQuality>(
            showSelectedIcon: false,
            segments: [
              for (final quality in ExportQuality.values)
                ButtonSegment(value: quality, label: Text(quality.label)),
            ],
            selected: {reel.exportQuality},
            onSelectionChanged: (value) =>
                controller.setExportQuality(value.first),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${res.width} x ${res.height} - about ${formatFileSize(reel.estimatedExportBytes)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        StilloraPrimaryButton(
          onPressed: onExport,
          icon: Icons.movie_filter_rounded,
          label: 'Export MP4',
        ),
      ],
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({required this.onPick, required this.mockup});

  final VoidCallback onPick;
  final ReelMockup mockup;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      onTap: onPick,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        children: [
          const Icon(
            Icons.video_call_rounded,
            color: StilloraColors.primary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            mockup == ReelMockup.none
                ? 'Add video or image'
                : 'Upload app video',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            mockup == ReelMockup.none
                ? 'Create a simple reel from your media.'
                : 'Your screen recording is placed inside the selected 3D device.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.onPick, required this.mockup});

  final VoidCallback onPick;
  final ReelMockup mockup;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Center(
        child: Icon(
          mockup == ReelMockup.androidGraphite
              ? Icons.phone_android_rounded
              : Icons.phone_iphone_rounded,
          color: StilloraColors.primary,
          size: 44,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? StilloraColors.primary.withValues(alpha: 0.9)
          : StilloraColors.surfaceContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : StilloraColors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return rest == 0 ? '${minutes}m' : '${minutes}m ${rest}s';
}
