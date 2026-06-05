import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../auth/login_screen.dart';
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

    ref.listen(exportControllerProvider, (_, next) {
      if (next.asData?.value != null) {
        context.pushReplacement(PreviewScreen.routePath);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Generating')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              export.hasError
                  ? Icons.error_outline_rounded
                  : Icons.movie_creation_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              export.hasError ? 'Export not ready yet' : 'Generating video...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              export.hasError
                  ? 'The native video engine boundary is in place. H.264 export still needs platform implementation.'
                  : 'Preparing image, generating video, merging audio, and saving locally.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (export.isLoading) const LinearProgressIndicator(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(exportControllerProvider.notifier).cancel();
                if (!context.mounted) {
                  return;
                }
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppTabsScreen.routePath);
                }
              },
              icon: const Icon(Icons.cancel_rounded),
              label: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
