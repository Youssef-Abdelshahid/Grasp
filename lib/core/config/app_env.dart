import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static const _placeholderUrl = 'YOUR_SUPABASE_URL_HERE';
  static const _placeholderAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

  static String get supabaseUrl =>
      dotenv.maybeGet('SUPABASE_URL')?.trim() ?? _placeholderUrl;

  static String get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY')?.trim() ?? _placeholderAnonKey;

  static bool get isSupabaseConfigured {
    final url = supabaseUrl;
    final anonKey = supabaseAnonKey;
    return url.isNotEmpty &&
        anonKey.isNotEmpty &&
        url != _placeholderUrl &&
        anonKey != _placeholderAnonKey;
  }
}
