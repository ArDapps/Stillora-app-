import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../export/export_progress_screen.dart';
import 'editor_state.dart';

class PreExportPreviewScreen extends ConsumerWidget {
  const PreExportPreviewScreen({super.key});

  static const routePath = '/pre-export-preview';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorControllerProvider);
    final aspectRatio =
        (editor.preset.width > 0 && editor.preset.height > 0)
            ? editor.preset.width / editor.preset.height
            : 9.0 / 16.0;
    final fitLabel = editor.resizeMode == ResizeMode.fit ? 'Fit' : 'Fill';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: null,
            tooltip: 'Export first to share',
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff0c0718), Color(0xff060611), Color(0xff030309)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 360,
                          maxWidth: 240,
                        ),
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(StilloraRadius.full),
                            child: _PreviewContent(editor: editor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PlaybackBar(
                      durationSeconds: editor.totalDurationSeconds,
                    ),
                    const SizedBox(height: 16),
                    StilloraGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Project Summary',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            icon: Icons.timer_outlined,
                            label: 'Duration',
                            value: '${editor.totalDurationSeconds}s',
                          ),
                          _SummaryRow(
                            icon: Icons.fit_screen_rounded,
                            label: 'Fit',
                            value: fitLabel,
                          ),
                          _SummaryRow(
                            icon: Icons.photo_size_select_actual_outlined,
                            label: 'Resolution',
                            value: editor.preset.ratioLabel,
                          ),
                          _SummaryRow(
                            icon: Icons.insert_drive_file_outlined,
                            label: 'File Type',
                            value: 'MP4',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: StilloraPrimaryButton(
                  onPressed: () => context.push(ExportProgressScreen.routePath),
                  icon: Icons.ios_share_rounded,
                  label: 'Export MP4',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({required this.editor});

  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    final media = editor.selectedMedia;
    if (media == null) {
      return const ColoredBox(
        color: StilloraColors.surfaceContainerLowest,
        child: Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            color: StilloraColors.primary,
            size: 36,
          ),
        ),
      );
    }
    if (media.kind == MediaKind.image) {
      return Image.file(
        File(media.path),
        fit: editor.resizeMode == ResizeMode.fit ? BoxFit.contain : BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return const ColoredBox(
      color: StilloraColors.surfaceContainerLowest,
      child: Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          color: StilloraColors.primary,
          size: 52,
        ),
      ),
    );
  }
}

class _PlaybackBar extends StatelessWidget {
  const _PlaybackBar({required this.durationSeconds});

  final int durationSeconds;

  String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return m == 0 ? '0:${r.toString().padLeft(2, '0')}' : '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.play_arrow_rounded, size: 28),
        const SizedBox(width: 6),
        Text(
          '0:00',
          style: const TextStyle(
            fontSize: 13,
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.0,
              backgroundColor: StilloraColors.surfaceContainerHigh,
              color: StilloraColors.primary,
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _fmt(durationSeconds),
          style: const TextStyle(
            fontSize: 13,
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.fullscreen_rounded,
          size: 20,
          color: StilloraColors.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: StilloraColors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 0, color: StilloraColors.glassStroke),
      ],
    );
  }
}
