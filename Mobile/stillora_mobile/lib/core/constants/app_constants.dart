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

/// AdMob (Google Mobile Ads) configuration. Defaults are Google's official TEST
/// unit IDs so banners render immediately during development without risking
/// policy strikes. Replace with your real IDs (publisher pub-2861157663948368)
/// via --dart-define or by editing the defaults before release.
///
/// Ads only show to NON-Pro users on iOS/Android. Pro subscribers and desktop
/// see no ads.
class AdConfig {
  const AdConfig._();

  // Google sample/test IDs — safe to ship in debug, must be replaced for release.
  static const _testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const _testAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';

  /// AdMob App ID. Must ALSO be set in ios/Runner/Info.plist (GADApplicationIdentifier)
  /// and android AndroidManifest. Real format: ca-app-pub-2861157663948368~XXXXXXXXXX
  static const iosAppId = String.fromEnvironment(
    'ADMOB_IOS_APP_ID',
    defaultValue: 'ca-app-pub-2861157663948368~5737899649',
  );
  static const androidAppId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_ID',
    defaultValue: _testAndroidAppId,
  );

  /// Banner ad unit IDs. iOS = real "banner stillora" unit.
  static const iosBannerUnitId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
    defaultValue: 'ca-app-pub-2861157663948368/2754467489',
  );
  static const androidBannerUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: _testAndroidBanner,
  );
}
