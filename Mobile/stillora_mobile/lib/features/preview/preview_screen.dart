import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/platform/media_actions.dart';
import '../../core/widgets/desktop_shell.dart';
import '../export/export_controller.dart';
import '../rating/rating_prompt.dart';
import '../tabs/app_tabs_screen.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  static const routePath = '/preview';

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  bool _sharing = false;
  bool _saving = false;

  bool get _busy => _sharing || _saving;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final outputPath = ref
          .read(exportControllerProvider)
          .asData
          ?.value
          ?.outputPath;
      if (outputPath != null && File(outputPath).existsSync()) {
        maybePromptForReview(ref);
      }
    });
  }

  String? get _outputPath =>
      ref.read(exportControllerProvider).asData?.value?.outputPath;

  void _snack(String message, {bool offerSettings = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: offerSettings
            ? SnackBarAction(label: 'Settings', onPressed: openAppSettings)
            : null,
      ),
    );
  }

  Future<void> _share() async {
    final path = _outputPath;
    if (path == null || _busy) return;
    setState(() => _sharing = true);
    try {
      final ok = await MediaActions.shareVideo(context, path);
      if (!ok) {
        _snack('That video is no longer available. Please export again.');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _save() async {
    final path = _outputPath;
    if (path == null || _busy) return;
    setState(() => _saving = true);
    try {
      final outcome = await MediaActions.saveToCameraRoll(path);
      switch (outcome) {
        case SaveOutcome.saved:
          _snack('Saved to your Camera Roll.');
        case SaveOutcome.missingFile:
          _snack('That video is no longer available. Please export again.');
        case SaveOutcome.permissionDenied:
          _snack('Allow photo access to save your video.', offerSettings: true);
        case SaveOutcome.failed:
          _snack('Could not save the video. Please try again.');
        case SaveOutcome.cancelled:
          break; // Camera-roll save has no cancellable dialog.
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(exportControllerProvider).asData?.value;
    final outputPath = result?.outputPath;
    final fileExists = outputPath != null && File(outputPath).existsSync();

    void openEditor() {
      ref.read(homeTabProvider.notifier).state = 0;
      context.go(AppTabsScreen.routePath);
    }

    if (!fileExists) {
      return Scaffold(
        appBar: AppBar(title: const Text('Export Complete')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(StilloraSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.movie_filter_outlined,
                  size: 56,
                  color: StilloraColors.onSurfaceVariant,
                ),
                const SizedBox(height: StilloraSpacing.sm),
                Text(
                  'No video yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: StilloraSpacing.xs),
                FilledButton.icon(
                  onPressed: openEditor,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create a video'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Export Complete')),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              _SuccessHeader(),
              const SizedBox(height: 24),
              _VideoCard(outputPath: outputPath),
              const SizedBox(height: 24),
              Text(
                'Share to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _PlatformRow(onShare: _busy ? null : _share),
              const SizedBox(height: 24),
              StilloraPrimaryButton(
                onPressed: _busy ? null : _share,
                icon: Icons.ios_share_rounded,
                label: _sharing ? 'Preparing…' : 'Save & Share',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(_saving ? 'Saving…' : 'Save to Camera Roll'),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: openEditor,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Another Video'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StilloraPulse(
          builder: (context, t) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Glow ring
                Container(
                  width: 88 + t * 8,
                  height: 88 + t * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: stilloraBrandGradient,
                    boxShadow: [
                      BoxShadow(
                        color: StilloraColors.accent.withValues(
                          alpha: 0.3 + t * 0.3,
                        ),
                        blurRadius: 24 + t * 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                // Sparkle dots
                ..._sparklePositions.map(
                  (pos) => Transform.translate(
                    offset: pos * (48 + t * 6),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 10 + t * 4,
                      color: Colors.white.withValues(alpha: 0.5 + t * 0.5),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Export Complete!',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Your video is ready to share.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static const _sparklePositions = [
    Offset(0, -1),
    Offset(0.7, -0.7),
    Offset(-0.7, -0.7),
    Offset(0.7, 0.7),
  ];
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.outputPath});

  final String outputPath;

  String get _fileName {
    final slash = outputPath.lastIndexOf(RegExp(r'[/\\]'));
    final name = slash == -1 ? outputPath : outputPath.substring(slash + 1);
    final dot = name.lastIndexOf('.');
    return dot == -1 ? name : name.substring(0, dot);
  }

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(StilloraRadius.xl),
            child: Container(
              width: 80,
              height: 80,
              color: StilloraColors.surfaceContainerLowest,
              child: Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: StilloraColors.primary,
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '1080p · MP4',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: StilloraColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(StilloraRadius.xl),
                  ),
                  child: Text(
                    'MP4',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: StilloraColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.onShare});

  final Future<void> Function()? onShare;

  @override
  Widget build(BuildContext context) {
    final platforms = [
      (FontAwesomeIcons.instagram, 'Reels', const Color(0xffe1306c)),
      (FontAwesomeIcons.tiktok, 'TikTok', StilloraColors.onSurface),
      (FontAwesomeIcons.facebook, 'Stories', const Color(0xff1877f2)),
      (FontAwesomeIcons.youtube, 'Shorts', const Color(0xffff0000)),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ...platforms.map(
          (p) => _PlatformButton(
            icon: p.$1,
            label: p.$2,
            color: p.$3,
            onTap: onShare,
          ),
        ),
        _PlatformButton(
          icon: Icons.more_horiz_rounded,
          label: 'More',
          color: StilloraColors.onSurfaceVariant,
          onTap: onShare,
          isMaterial: true,
        ),
      ],
    );
  }
}

class _PlatformButton extends StatelessWidget {
  const _PlatformButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isMaterial = false,
  });

  final dynamic icon;
  final String label;
  final Color color;
  final Future<void> Function()? onTap;
  final bool isMaterial;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: StilloraColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(StilloraRadius.full),
              border: Border.all(color: StilloraColors.glassStroke),
            ),
            child: Center(
              child: isMaterial
                  ? Icon(icon as IconData, color: color, size: 24)
                  : FaIcon(icon as FaIconData, color: color, size: 22),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
