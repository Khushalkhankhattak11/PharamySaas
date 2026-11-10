import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String _get(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    return dotenv.env[key] ?? fallback;
  }

  static String get supabaseUrl =>
      _get('SUPABASE_URL', 'https://your-project.supabase.co');

  static String get supabaseAnonKey =>
      _get('SUPABASE_ANON_KEY', 'your-supabase-anon-key');

  static String get appName =>
      _get('APP_NAME', 'PharmaCare SaaS');

  static String get appEnv =>
      _get('APP_ENV', 'development');

  static String get supportEmail =>
      _get('SUPPORT_EMAIL', 'support@pharmacare-saas.com');
}
