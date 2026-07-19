import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/widgets/desktop_shell.dart';
import 'editor_state.dart';

class UploadMediaScreen extends ConsumerWidget {
  const UploadMediaScreen({super.key});

  static const routePath = '/upload-media';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);

    return SidebarScaffold(
      desktopTitle: 'Upload Media',
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) =>
              stilloraBrandGradient.createShader(bounds),
          child: const Text(
            'Stillora',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: stilloraBackgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  children: [
                    Text(
                      'Upload Media',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add photos, images, or a short clip to get started.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _UploadDropZone(
                      onTap: () async {
                        if (editor.hasMedia) {
                          await controller.addMedia();
                        } else {
                          await controller.pickMedia();
                        }
                      },
                    ),
                    if (editor.hasMedia) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Selected Media (${editor.media.length})',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: controller.pickMedia,
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _MediaThumbnailRow(
                        media: editor.media,
                        controller: controller,
                      ),
                    ],
                    const SizedBox(height: 20),
                    const _PrivacyNote(
                      text:
                          'Your media stays on your device and is only used to create your video.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: StilloraPrimaryButton(
                  onPressed: editor.hasMedia ? () => context.pop() : null,
                  icon: Icons.arrow_forward_rounded,
                  label: 'Continue',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadDropZone extends StatelessWidget {
  const _UploadDropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: StilloraColors.surfaceContainerLowest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(StilloraRadius.full),
          border: Border.all(
            color: StilloraColors.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_rounded,
              size: 52,
              color: StilloraColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to upload\nor drag and drop',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Photos, images, or short clips',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
            Text(
              'JPG, PNG, HEIC, MOV, MP4',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaThumbnailRow extends StatelessWidget {
  const _MediaThumbnailRow({required this.media, required this.controller});

  final List<MediaItem> media;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: media.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = media[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(StilloraRadius.full),
                child: item.kind == MediaKind.image
                    ? Image.file(
                        File(item.path),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: StilloraColors.surfaceContainerLowest,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            color: StilloraColors.primary,
                          ),
                        ),
                      ),
              ),
              if (item.kind == MediaKind.video)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _fmt(item.durationSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => controller.removeMediaAt(index),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m == 0 ? '${seconds}s' : '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.verified_user_rounded,
          color: StilloraColors.brandCyan,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
