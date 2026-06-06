import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/desktop_shell.dart';
import '../auth/login_screen.dart';
import '../editor/editor_state.dart';
import '../preview/preview_screen.dart';
import '../tabs/app_tabs_screen.dart';
import 'export_controller.dart';

const _staticCompanyBannerImageUrl =
    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe'
    '?auto=format&fit=crop&w=1200&q=80';

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
      final session = ref.read(authControllerProvider).asData?.value;
      if (session == null) {
        context.go(
          '${LoginScreen.routePath}?next=${Uri.encodeComponent(ExportProgressScreen.routePath)}',
        );
        return;
      }
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff0c0718), Color(0xff060611), Color(0xff030309)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
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
        _CompanyAdBanner(compact: compact),
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

class _CompanyAdBanner extends StatelessWidget {
  const _CompanyAdBanner({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StilloraGlowCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(StilloraRadius.full - 1.5),
        child: AspectRatio(
          aspectRatio: compact ? 16 / 4 : 16 / 7,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _staticCompanyBannerImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return const _CompanyAdFallback();
                },
                errorBuilder: (context, error, stackTrace) {
                  return const _CompanyAdFallback();
                },
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0xcc000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(StilloraSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SponsoredPill(),
                    const Spacer(),
                    Text(
                      'TecnoBlocks',
                      style:
                          (compact
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.headlineSmall)
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: StilloraSpacing.base),
                    Text(
                      'Company banner placement',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyAdFallback extends StatelessWidget {
  const _CompanyAdFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: stilloraBrandGradient),
      child: Align(
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.campaign_rounded,
          color: Colors.white.withValues(alpha: 0.24),
          size: 104,
        ),
      ),
    );
  }
}

class _SponsoredPill extends StatelessWidget {
  const _SponsoredPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              'Sponsored',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
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
                          color: const Color(
                            0xff8b5cf6,
                          ).withValues(alpha: 0.36),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Icon(
                hasError
                    ? Icons.error_outline_rounded
                    : Icons.movie_creation_rounded,
                color: Colors.white,
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
