class AppConstants {
  const AppConstants._();

  static const apiBaseUrl = String.fromEnvironment(
    'STILLORA_API_BASE_URL',
    defaultValue: 'https://stillora.loopara.app',
  );
  static const privacyUrl = 'https://stillora.loopara.app/privacy';
  static const termsUrl = 'https://stillora.loopara.app/terms';
}
