import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static const _placeholderUrl = 'YOUR_SUPABASE_URL_HERE';
  static const _placeholderAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  static const _placeholderGeminiKey = 'YOUR_GEMINI_API_KEY_HERE';
  static const _defaultGeminiPrimaryModel = 'gemini-3-flash-preview';
  static const _defaultGeminiFallbackModel1 = 'gemini-2.5-flash';
  static const _defaultGeminiFallbackModel2 = 'gemini-2.5-flash-lite';

  static String _envOrDefault(String key, String fallback) {
    final value = dotenv.maybeGet(key)?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }

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

  static String get geminiApiKey =>
      dotenv.maybeGet('GEMINI_API_KEY')?.trim() ?? _placeholderGeminiKey;

  static String get geminiPrimaryModel =>
      _envOrDefault('GEMINI_PRIMARY_MODEL', _defaultGeminiPrimaryModel);

  static String get geminiFallbackModel1 =>
      _envOrDefault('GEMINI_FALLBACK_MODEL_1', _defaultGeminiFallbackModel1);

  static String get geminiFallbackModel2 =>
      _envOrDefault('GEMINI_FALLBACK_MODEL_2', _defaultGeminiFallbackModel2);

  static bool get isGeminiConfigured {
    final key = geminiApiKey;
    return key.isNotEmpty && key != _placeholderGeminiKey;
  }
}
