import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_settings_model.dart';

class UserSettingsService {
  UserSettingsService._();

  static final instance = UserSettingsService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<UserSettingsEnvelope> getCurrentSettings() async {
    final response = await _client.rpc('get_current_user_settings');
    return UserSettingsEnvelope.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<UserSettingsEnvelope> updateCurrentSettings(
    UserSettings settings,
  ) async {
    final payload = settings.toJson();
    try {
      final response = await _client.rpc(
        'update_current_user_settings',
        params: {'p_settings': payload},
      );
      return UserSettingsEnvelope.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } on PostgrestException catch (error) {
      if (!_themeModeUnsupported(error)) {
        rethrow;
      }
      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('theme_mode');
      final response = await _client.rpc(
        'update_current_user_settings',
        params: {'p_settings': fallbackPayload},
      );
      final envelope = UserSettingsEnvelope.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      return _withRequestedTheme(envelope, settings);
    }
  }

  Future<UserSettingsEnvelope> resetCurrentSettings() async {
    final response = await _client.rpc('reset_current_user_settings');
    return UserSettingsEnvelope.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<UserSettings?> getCurrentSettingsOrNull() async {
    try {
      return (await getCurrentSettings()).settings;
    } catch (_) {
      return null;
    }
  }
}

bool _themeModeUnsupported(PostgrestException error) {
  final message = error.message.toLowerCase();
  return message.contains('invalid student settings field') ||
      message.contains('invalid instructor settings field') ||
      message.contains('theme mode');
}

UserSettingsEnvelope _withRequestedTheme(
  UserSettingsEnvelope envelope,
  UserSettings requested,
) {
  final requestedTheme = switch (requested) {
    StudentSettings() => requested.themeMode,
    InstructorSettings() => requested.themeMode,
  };
  final settings = switch (envelope.settings) {
    StudentSettings settings => settings.copyWith(themeMode: requestedTheme),
    InstructorSettings settings => settings.copyWith(
      themeMode: requestedTheme,
    ),
  };
  return UserSettingsEnvelope(
    userId: envelope.userId,
    role: envelope.role,
    settings: settings,
    defaults: envelope.defaults,
  );
}
