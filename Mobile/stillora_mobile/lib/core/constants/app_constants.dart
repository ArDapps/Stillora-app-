class AppConstants {
  const AppConstants._();

  static const apiBaseUrl = String.fromEnvironment(
    'STILLORA_API_BASE_URL',
    defaultValue: 'https://stillora.loopara.app',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '718272031198-kr3vqn6j3cchpo0vqp7usajm3734ignb.apps.googleusercontent.com',
  );
  static const googleMacosClientId = String.fromEnvironment(
    'GOOGLE_MACOS_CLIENT_ID',
    defaultValue:
        '718272031198-kr3vqn6j3cchpo0vqp7usajm3734ignb.apps.googleusercontent.com',
  );
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '718272031198-jcl994t1b9ucib32k08hb3rc5v29ngur.apps.googleusercontent.com',
  );

  /// Google Cloud "Desktop app" OAuth client used by the Linux/Windows
  /// loopback + PKCE sign-in flow. Supply via
  /// `--dart-define=GOOGLE_DESKTOP_CLIENT_ID=...` and
  /// `--dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=...` at build time. The same
  /// client id must be listed in the backend's GOOGLE_NATIVE_CLIENT_IDS.
  static const googleDesktopClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
    defaultValue: '',
  );
  static const googleDesktopClientSecret = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_SECRET',
    defaultValue: '',
  );
  /// Apple "Services ID" used for Sign in with Apple on non-Apple platforms
  /// (Android/web). On iOS/macOS the native flow uses the app's bundle id as the
  /// token audience, so this is only required for the Android web-redirect flow.
  static const appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: 'app.loopara.stillora.signin',
  );

  /// Redirect URI registered with Apple for the Android/web sign-in flow. Must
  /// point at a backend endpoint that forwards the result back to the app.
  static const appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: 'https://stillora.loopara.app/api/auth/apple/callback',
  );

  static const privacyUrl = 'https://stillora.loopara.app/privacy';
  static const termsUrl = 'https://stillora.loopara.app/terms';

  /// Where to send users to leave a review on platforms without a native
  /// in-app review dialog (Linux/Windows, or when the store flow is
  /// unavailable). Point this at the store listing once it exists.
  static const reviewUrl = 'https://stillora.loopara.app';
}
