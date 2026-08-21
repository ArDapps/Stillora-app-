import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/desktop_shell.dart';
import '../../core/widgets/ad_widget.dart';
import '../editor/editor_state.dart';
import '../preview/preview_screen.dart';
import '../tabs/app_tabs_screen.dart';
import 'export_controller.dart';

class ExportProgressScreen extends ConsumerStatefulWidget {
  const ExportProgressScreen({super.key});

  static const routePath = '/export';

  @override
  ConsumerState<ExportProgressScreen> createState() =>
      _ExportProgressScreenState();
}

class _ExportProgressScreenState extends ConsumerState<ExportProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Export is available to everyone — guests included. No login gate here.
      final editor = ref.read(editorControllerProvider);
      ref.read(exportControllerProvider.notifier).start(editor);
    });
  }

  @override
  Widget build(BuildContext context) {
    final export = ref.watch(exportControllerProvider);
    final isRunning = export.isLoading;
    final isDesktop = useDesktopLayout(context);

    ref.listen(exportControllerProvider, (_, next) {
      if (next.asData?.value != null) {
        context.pushReplacement(PreviewScreen.routePath);
      }
    });

    Future<void> leaveExport() async {
      if (isRunning) {
        await ref.read(exportControllerProvider.notifier).cancel();
      }
      if (!context.mounted) {
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppTabsScreen.routePath);
      }
    }

    final body = DecoratedBox(
      decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
      child: _ExportProgressContent(
        export: export,
        message: _messageFor(export),
        isRunning: isRunning,
        compact: isDesktop,
        onLeave: leaveExport,
      ),
    );

    if (isDesktop) {
      return DesktopShell(title: 'Export', child: body);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Generating')),
      body: body,
    );
  }

  String _messageFor(AsyncValue<Object?> export) {
    final error = export.error;
    if (error is PlatformException) {
      return error.message ?? 'The selected media could not be exported.';
    }
    if (error is FileSystemException) {
      return error.message;
    }
    if (export.hasError) {
      return 'The selected media could not be exported.';
    }
    return 'Preparing media, generating video, merging audio, and saving locally.';
  }
}

class _ExportProgressContent extends StatelessWidget {
  const _ExportProgressContent({
    required this.export,
    required this.message,
    required this.isRunning,
    required this.compact,
    required this.onLeave,
  });

  final AsyncValue<Object?> export;
  final String message;
  final bool isRunning;
  final bool compact;
  final Future<void> Function() onLeave;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : StilloraSpacing.mobileMargin,
        compact ? 12 : StilloraSpacing.sm,
        compact ? 16 : StilloraSpacing.mobileMargin,
        compact ? 16 : StilloraSpacing.lg,
      ),
      children: [
        AdSlotWidget(
          placement: compact ? 'USER_DASHBOARD_LEFT' : 'HOME_BANNER',
        ),
        SizedBox(height: compact ? 10 : StilloraSpacing.sm),
        _ExportStatusCard(export: export, message: message, compact: compact),
        SizedBox(height: compact ? 10 : StilloraSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => onLeave(),
          icon: Icon(
            isRunning ? Icons.cancel_rounded : Icons.arrow_back_rounded,
          ),
          label: Text(isRunning ? 'Cancel export' : 'Back to editor'),
        ),
      ],
    );

    return SafeArea(
      top: false,
      child: compact
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: content,
              ),
            )
          : content,
    );
  }
}

class _ExportStatusCard extends StatelessWidget {
  const _ExportStatusCard({
    required this.export,
    required this.message,
    this.compact = false,
  });

  final AsyncValue<Object?> export;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasError = export.hasError;

    return StilloraGlassCard(
      padding: EdgeInsets.all(compact ? 16 : StilloraSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: compact ? 44 : 68,
              height: compact ? 44 : 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: hasError ? null : stilloraBrandGradient,
                color: hasError ? StilloraColors.errorContainer : null,
                borderRadius: BorderRadius.circular(StilloraRadius.full),
                boxShadow: hasError
                    ? null
                    : [
                        BoxShadow(
                          color: StilloraColors.accent.withValues(alpha: 0.36),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Icon(
                hasError
                    ? Icons.error_outline_rounded
                    : Icons.movie_creation_rounded,
                color: hasError
                    ? StilloraColors.onErrorContainer
                    : Colors.white,
                size: compact ? 24 : 34,
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : StilloraSpacing.sm),
          Text(
            hasError ? 'Export not ready yet' : 'Generating video...',
            style:
                (compact
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineSmall)
                    ?.copyWith(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: compact ? 4 : StilloraSpacing.xs),
          Text(
            message,
            style:
                (compact
                        ? Theme.of(context).textTheme.bodySmall
                        : Theme.of(context).textTheme.bodyMedium)
                    ?.copyWith(color: StilloraColors.onSurfaceVariant),
          ),
          if (export.isLoading) ...[
            SizedBox(height: compact ? 10 : StilloraSpacing.sm),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
