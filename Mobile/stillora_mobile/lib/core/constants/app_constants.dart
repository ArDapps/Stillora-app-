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
  static const privacyUrl = 'https://stillora.loopara.app/privacy';
  static const termsUrl = 'https://stillora.loopara.app/terms';
}
