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
    final response = await _client.rpc(
      'update_current_user_settings',
      params: {'p_settings': settings.toJson()},
    );
    return UserSettingsEnvelope.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
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
