import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/design/stillora_colors.dart';
import '../reel_state.dart';

class ReelPreview extends StatefulWidget {
  const ReelPreview({super.key, required this.reel, required this.onPick});

  final ReelState reel;
  final VoidCallback onPick;

  @override
  State<ReelPreview> createState() => _ReelPreviewState();
}

class _ReelPreviewState extends State<ReelPreview>
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
  void didUpdateWidget(covariant ReelPreview oldWidget) {
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
      return ReelEmptyPreview(
        onPick: widget.onPick,
        mockup: widget.reel.mockup,
      );
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
                    child: ReelPhoneFrame(
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

class ReelPhoneFrame extends StatelessWidget {
  const ReelPhoneFrame({
    super.key,
    required this.mockup,
    required this.controller,
  });

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

class ReelEmptyPreview extends StatelessWidget {
  const ReelEmptyPreview({
    super.key,
    required this.onPick,
    required this.mockup,
  });

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
