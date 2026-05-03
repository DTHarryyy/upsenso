final class AppEnv {
  const AppEnv._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const oauthRedirectUrl = String.fromEnvironment(
    'SUPABASE_OAUTH_REDIRECT_URL',
    defaultValue: 'posauth://login-callback/',
  );
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const logLevel = String.fromEnvironment('LOG_LEVEL', defaultValue: 'debug');
  static const enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS');

  static bool get isDev => flavor == 'dev';
  static bool get isStaging => flavor == 'staging';
  static bool get isProd => flavor == 'prod';

  static void assertValid() {
    if (supabaseUrl.isEmpty) {
      throw Exception(
        'SUPABASE_URL is not set. '
        'Run with: flutter run --dart-define-from-file=flavors/dev.json',
      );
    }
    if (supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY is not set. '
        'Run with: flutter run --dart-define-from-file=flavors/dev.json',
      );
    }
  }
}
