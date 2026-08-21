import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/analytics/usage_tracker.dart';
import '../core/pro/pro_gate.dart';
import '../features/editor/add_audio_screen.dart';
import '../features/editor/choose_preset_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/editor/pre_export_preview_screen.dart';
import '../features/editor/upload_media_screen.dart';
import '../features/editor/voice_narration_screen.dart';
import '../features/export/export_progress_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/preview/preview_screen.dart';
import '../features/pro/pro_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/tabs/app_tabs_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashScreen.routePath,
    // Side-effect only: report the visited path for analytics, never redirect.
    // `screen()` de-dupes, so repeated calls for one navigation are harmless.
    redirect: (context, state) {
      unawaited(ref.read(usageTrackerProvider).screen(state.uri.path));
      return null;
    },
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: OnboardingScreen.routePath,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppTabsScreen.routePath,
        builder: (context, state) => const AppTabsScreen(),
      ),
      GoRoute(
        path: EditorScreen.routePath,
        builder: (context, state) => const EditorScreen(),
      ),
      GoRoute(
        path: ExportProgressScreen.routePath,
        builder: (context, state) => const ExportProgressScreen(),
      ),
      GoRoute(
        path: PreviewScreen.routePath,
        builder: (context, state) => const PreviewScreen(),
      ),
      GoRoute(
        path: UploadMediaScreen.routePath,
        builder: (context, state) => const UploadMediaScreen(),
      ),
      GoRoute(
        path: ChoosePresetScreen.routePath,
        builder: (context, state) => const ChoosePresetScreen(),
      ),
      GoRoute(
        path: AddAudioScreen.routePath,
        builder: (context, state) => const AddAudioScreen(),
      ),
      GoRoute(
        path: VoiceNarrationScreen.routePath,
        builder: (context, state) => const VoiceNarrationScreen(),
      ),
      GoRoute(
        path: PreExportPreviewScreen.routePath,
        builder: (context, state) => const PreExportPreviewScreen(),
      ),
      GoRoute(
        path: GalleryScreen.routePath,
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: SettingsScreen.routePath,
        builder: (context, state) => const SettingsScreen(),
      ),
      // Contextual paywall. Pushed (never redirected to) by gated controls,
      // which pass the triggering feature as `extra` so the page can say why
      // it opened.
      GoRoute(
        path: ProScreen.routePath,
        builder: (context, state) => ProScreen(
          reason: state.extra is ProFeature
              ? state.extra! as ProFeature
              : ProFeature.proMenu,
        ),
      ),
    ],
  );
});
