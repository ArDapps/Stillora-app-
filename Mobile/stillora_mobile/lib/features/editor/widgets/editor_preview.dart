import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_glow.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../color/color_graded_preview.dart';
import '../editor_state.dart';
import '../video_styles.dart';

class PreviewCard extends StatelessWidget {
  const PreviewCard({
    super.key,
    required this.editor,
    this.maxPreviewHeight = 320,
    this.maxPreviewWidth = 420,
  });

  final EditorState editor;
  final double maxPreviewHeight;
  final double maxPreviewWidth;

  double get _aspectRatio {
    final preset = editor.preset;
    if (preset.width <= 0 || preset.height <= 0) {
      return 9 / 16;
    }
    return preset.width / preset.height;
  }

  @override
  Widget build(BuildContext context) {
    final fitLabel = editor.resizeMode == ResizeMode.fit ? 'Fit' : 'Fill';

    return StilloraGlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.smart_display_rounded,
                color: StilloraColors.primary,
                size: 20,
              ),
              const SizedBox(width: StilloraSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MP4 Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${editor.preset.ratioLabel} · ${editor.totalDurationSeconds}s · $fitLabel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxPreviewHeight,
                maxWidth: maxPreviewWidth,
              ),
              child: AspectRatio(
                aspectRatio: _aspectRatio,
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
                    child: EditorPreviewStage(editor: editor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMedia extends StatelessWidget {
  const _PreviewMedia({required this.media, required this.resizeMode});

  final MediaItem? media;
  final ResizeMode resizeMode;

  @override
  Widget build(BuildContext context) {
    final item = media;
    if (item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(StilloraSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: StilloraColors.primary,
                size: 36,
              ),
              const SizedBox(height: StilloraSpacing.xs),
              Text(
                'Upload media to begin',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: StilloraSpacing.xs),
              Text(
                'The preview matches your final video frame.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (item.kind == MediaKind.image) {
      return Image.file(
        File(item.path),
        fit: resizeMode == ResizeMode.fit ? BoxFit.contain : BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Show the video's real first frame so the preview (and any colour grade
    // over it) reflects the actual footage, not just a placeholder icon.
    return _VideoFramePreview(
      key: ValueKey(item.path),
      path: item.path,
      resizeMode: resizeMode,
    );
  }
}

/// Renders the first frame of a video clip, scaled to fill the preview area.
/// Used inside the Create preview so a colour grade is visible over real
/// footage (mirrors the poster approach in [VideoThumbnail]).
class _VideoFramePreview extends StatefulWidget {
  const _VideoFramePreview({
    super.key,
    required this.path,
    required this.resizeMode,
  });

  final String path;
  final ResizeMode resizeMode;

  @override
  State<_VideoFramePreview> createState() => _VideoFramePreviewState();
}

class _VideoFramePreviewState extends State<_VideoFramePreview> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final file = File(widget.path);
    if (!file.existsSync()) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      await controller.seekTo(Duration.zero);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_ready && controller != null) {
      return FittedBox(
        fit: widget.resizeMode == ResizeMode.fit
            ? BoxFit.contain
            : BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }
    return Center(
      child: _failed
          ? const Icon(
              Icons.movie_outlined,
              color: StilloraColors.onSurfaceVariant,
              size: 36,
            )
          : const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
    );
  }
}

/// Chooses how to render the preview: an auto-playing [SlideshowPreview] that
/// animates the transition between each image asset when there are multiple
/// images, otherwise the static [_PreviewMedia] wrapped in [StyledMedia].
class EditorPreviewStage extends StatelessWidget {
  const EditorPreviewStage({super.key, required this.editor});

  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    // Grade the whole preview live so the editor shows how the exported (graded)
    // video will look, matching the Speed/Watermark/Silence sections.
    return ColorGradedPreview(adjust: editor.color, child: _buildStage());
  }

  Widget _buildStage() {
    if (editor.exportsImageSlideshow && editor.media.length > 1) {
      return SlideshowPreview(
        media: editor.media,
        transition: editor.transition,
        effect: editor.effect,
        resizeMode: editor.resizeMode,
      );
    }
    return StyledMedia(
      effect: editor.effect,
      transition: editor.transition,
      child: _PreviewMedia(
        media: editor.selectedMedia,
        resizeMode: editor.resizeMode,
      ),
    );
  }
}

/// Auto-advancing preview of a multi-image slideshow. Each clip is shown for its
/// own duration and the selected [transition] plays on every asset-to-asset
/// handoff, so the preview reflects how the exported video moves between images.
class SlideshowPreview extends StatefulWidget {
  const SlideshowPreview({
    super.key,
    required this.media,
    required this.transition,
    required this.effect,
    required this.resizeMode,
  });

  final List<MediaItem> media;
  final FrameTransition transition;
  final ClipEffect effect;
  final ResizeMode resizeMode;

  @override
  State<SlideshowPreview> createState() => _SlideshowPreviewState();
}

class _SlideshowPreviewState extends State<SlideshowPreview> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant SlideshowPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart cycling when the clip list changes (count/order/paths or timing).
    if (!_sameClips(oldWidget.media, widget.media)) {
      _index = _index.clamp(0, widget.media.length - 1);
      _schedule();
    }
  }

  bool _sameClips(List<MediaItem> a, List<MediaItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].path != b[i].path ||
          a[i].durationSeconds != b[i].durationSeconds) {
        return false;
      }
    }
    return true;
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.media.length < 2) return;
    final index = _index.clamp(0, widget.media.length - 1);
    final secs = widget.media[index].durationSeconds.clamp(1, 60);
    _timer = Timer(Duration(seconds: secs), _advance);
  }

  void _advance() {
    if (!mounted || widget.media.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.media.length);
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return _PreviewMedia(media: null, resizeMode: widget.resizeMode);
    }
    final index = _index.clamp(0, widget.media.length - 1);
    final item = widget.media[index];
    return AnimatedSwitcher(
      duration: frameTransitionDuration(widget.transition),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          frameTransitionBuilder(widget.transition, child, animation),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, ?currentChild],
      ),
      child: KeyedSubtree(
        key: ValueKey('slide_$index@${item.path}'),
        child: EffectAnimator(
          effect: widget.effect,
          child: _PreviewMedia(media: item, resizeMode: widget.resizeMode),
        ),
      ),
    );
  }
}
