import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/widgets/desktop_shell.dart';
import '../../core/widgets/stillora_video_player_panel.dart';
import '../export/export_controller.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  static const routePath = '/preview';

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  VideoPlayerController? _controller;
  String? _outputPath;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    final result = ref.read(exportControllerProvider).asData?.value;
    final path = result?.outputPath;
    if (path != null && File(path).existsSync()) {
      _outputPath = path;
      _setUpController(path);
    } else {
      _initializing = false;
    }
  }

  Future<void> _setUpController(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
    } catch (_) {
      // Leave the controller uninitialised; the UI falls back to a message.
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _initializing = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final path = _outputPath;
    if (path == null) {
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'video/mp4')],
        text: 'Made with Stillora',
      ),
    );
  }

  void _openTab(int index) {
    ref.read(homeTabProvider.notifier).state = index;
    context.go(kHomeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : _outputPath == null
          ? _EmptyPreview(onOpenEditor: () => _openTab(0))
          : _ReadyPreview(
              controller: _controller,
              onShare: _share,
              onCreateAnother: () => _openTab(0),
              onLibrary: () => _openTab(1),
            ),
    );
  }
}

class _ReadyPreview extends StatelessWidget {
  const _ReadyPreview({
    required this.controller,
    required this.onShare,
    required this.onCreateAnother,
    required this.onLibrary,
  });

  final VideoPlayerController? controller;
  final Future<void> Function() onShare;
  final VoidCallback onCreateAnother;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized;

    return ListView(
      padding: const EdgeInsets.all(StilloraSpacing.sm),
      children: [
        Text(
          'Final Preview',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          'Review the timing, scrub the video, then save or share.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StilloraSpacing.sm),
        StilloraVideoPlayerPanel(controller: controller),
        const SizedBox(height: StilloraSpacing.xs),
        OutlinedButton.icon(
          onPressed: ready ? () => onShare() : null,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Save or Share'),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        OutlinedButton.icon(
          onPressed: onCreateAnother,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Another Video'),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        TextButton.icon(
          onPressed: onLibrary,
          icon: const Icon(Icons.video_library_outlined),
          label: const Text('Go to Library'),
        ),
      ],
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.onOpenEditor});

  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.movie_filter_outlined,
              size: 56,
              color: StilloraColors.onSurfaceVariant,
            ),
            const SizedBox(height: StilloraSpacing.sm),
            Text(
              'No video to preview yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: StilloraSpacing.xs),
            Text(
              'Convert a photo in the editor to see it here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: StilloraSpacing.sm),
            FilledButton.icon(
              onPressed: onOpenEditor,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Open editor'),
            ),
          ],
        ),
      ),
    );
  }
}
