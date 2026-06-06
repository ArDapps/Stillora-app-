import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/export/export_progress_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/preview/preview_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/tabs/app_tabs_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashScreen.routePath,
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) =>
            LoginScreen(nextPath: state.uri.queryParameters['next']),
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
    ],
  );
});
