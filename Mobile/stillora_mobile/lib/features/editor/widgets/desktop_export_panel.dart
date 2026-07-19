import 'package:flutter/material.dart';

import '../../../core/format/duration_label.dart';
import '../../../core/design/stillora_colors.dart';
import '../../../core/design/stillora_glow.dart';
import '../../../core/design/stillora_spacing.dart';
import '../../../core/design/stillora_surface.dart';
import '../editor_state.dart';
import 'editor_shared.dart';

class DesktopExportPanel extends StatelessWidget {
  const DesktopExportPanel({
    super.key,
    required this.editor,
    required this.isSignedIn,
    required this.onConvert,
    required this.onReset,
    this.compact = false,
  });

  final EditorState editor;
  final bool isSignedIn;
  final VoidCallback onConvert;
  final VoidCallback onReset;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StilloraGlowCard(
      padding: EdgeInsets.all(compact ? 12 : StilloraSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 36 : 44,
                height: compact ? 36 : 44,
                decoration: BoxDecoration(
                  gradient: stilloraBrandGradient,
                  borderRadius: BorderRadius.circular(StilloraRadius.full),
                ),
                child: const Icon(
                  Icons.movie_creation_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: StilloraSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editor.canExport ? 'Ready to export' : 'Set up export',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      editor.canExport
                          ? 'Review the desktop preview before converting.'
                          : 'Choose media to unlock conversion.',
                      style:
                          (compact
                                  ? Theme.of(context).textTheme.bodySmall
                                  : Theme.of(context).textTheme.bodyMedium)
                              ?.copyWith(
                                color: StilloraColors.onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          _DesktopExportStat(
            icon: Icons.perm_media_rounded,
            label: 'Assets',
            value: editor.media.isEmpty
                ? 'None selected'
                : '${editor.media.length} item${editor.media.length == 1 ? '' : 's'}',
            compact: compact,
          ),
          _DesktopExportStat(
            icon: Icons.aspect_ratio_rounded,
            label: 'Preset',
            value: '${editor.preset.label} · ${editor.preset.ratioLabel}',
            compact: compact,
          ),
          _DesktopExportStat(
            icon: Icons.high_quality_rounded,
            label: 'Quality',
            value:
                '${editor.exportQuality.label} · '
                '${editor.outputResolution.width}×${editor.outputResolution.height}',
            compact: compact,
          ),
          _DesktopExportStat(
            icon: Icons.sd_storage_rounded,
            label: 'Est. size',
            value: '≈ ${formatFileSize(editor.estimatedExportBytes)}',
            compact: compact,
          ),
          _DesktopExportStat(
            icon: Icons.timer_rounded,
            label: 'Duration',
            value: formatDurationClock(editor.totalDurationSeconds),
            compact: compact,
          ),
          _DesktopExportStat(
            icon: isSignedIn
                ? Icons.verified_user_rounded
                : Icons.person_outline_rounded,
            label: 'Account',
            value: isSignedIn ? 'Signed in' : 'Guest',
            compact: compact,
          ),
          SizedBox(height: compact ? 10 : StilloraSpacing.sm),
          StilloraPrimaryButton(
            onPressed: editor.canExport ? onConvert : null,
            icon: Icons.auto_fix_high_rounded,
            label: 'Convert to MP4',
          ),
          if (canReset(editor)) ...[
            const SizedBox(height: StilloraSpacing.xs),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Start over'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DesktopExportStat extends StatelessWidget {
  const _DesktopExportStat({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StilloraSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StilloraColors.surfaceContainerLow.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(StilloraRadius.full),
          border: Border.all(color: StilloraColors.glassStroke),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : StilloraSpacing.sm,
            vertical: compact ? 6 : StilloraSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: compact ? 15 : 18,
                color: StilloraColors.primary,
              ),
              SizedBox(width: compact ? 6 : StilloraSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: StilloraSpacing.xs),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
