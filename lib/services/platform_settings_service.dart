import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/platform_settings_model.dart';

class PlatformSettingsService {
  PlatformSettingsService._();

  static final instance = PlatformSettingsService._();

  static const publicRegistrationDisabledMessage =
      'Public registration is currently disabled.';
  static const passwordChangeDisabledMessage =
      'Password changes are currently disabled by the administrator.';
  static const forceLogoutMessage =
      'Your session has expired. Please sign in again.';

  SupabaseClient get _client => Supabase.instance.client;

  Future<PlatformSettingsConfig> getAdminSettings() async {
    try {
      final response = await _client.rpc('get_admin_platform_settings');
      return PlatformSettingsConfig.fromJson(_map(response));
    } catch (error) {
      throw PlatformSettingsException(_friendlyMessage(error));
    }
  }

  Future<PlatformSettingsConfig> getEffectiveSettings() async {
    try {
      final response = await _client.rpc('get_effective_platform_settings');
      return PlatformSettingsConfig.fromJson(_map(response));
    } catch (error) {
      throw PlatformSettingsException(_friendlyMessage(error));
    }
  }

  Future<PlatformSettingsConfig> getPublicSettings() async {
    try {
      final response = await _client.rpc('get_public_platform_settings');
      return PlatformSettingsConfig.fromJson(_map(response));
    } catch (_) {
      return PlatformSettingsConfig.defaults();
    }
  }

  Future<PlatformSettingsConfig> updateAdminSettings(
    PlatformSettingsConfig settings,
  ) async {
    try {
      final response = await _client.rpc(
        'update_admin_platform_settings',
        params: {'p_settings': settings.toJson()},
      );
      return PlatformSettingsConfig.fromJson(_map(response));
    } catch (error) {
      throw PlatformSettingsException(_friendlyMessage(error));
    }
  }

  Future<PlatformSettingsConfig> resetAdminSettings() async {
    try {
      final response = await _client.rpc('reset_admin_platform_settings');
      return PlatformSettingsConfig.fromJson(_map(response));
    } catch (error) {
      throw PlatformSettingsException(_friendlyMessage(error));
    }
  }

  Future<DateTime?> forceLogoutAllUsers() async {
    try {
      final response = await _client.rpc('force_logout_all_users');
      final invalidatedAt = _map(response)['platform_session_invalidated_at'];
      return invalidatedAt == null
          ? null
          : DateTime.tryParse(invalidatedAt.toString())?.toUtc();
    } catch (error) {
      throw PlatformSettingsException(_friendlyMessage(error));
    }
  }

  Future<void> ensurePasswordChangeAllowed(String password) async {
    try {
      await _client.rpc(
        'ensure_password_change_allowed',
        params: {'p_password': password},
      );
    } catch (error) {
      throw PlatformSettingsException(_friendlyMessage(error));
    }
  }

  String? strongPasswordError(String password, PlatformSettingsConfig settings) {
    if (settings.requireStrongPasswords) {
      if (password.length < 8 ||
          !RegExp('[A-Z]').hasMatch(password) ||
          !RegExp('[a-z]').hasMatch(password) ||
          !RegExp('[0-9]').hasMatch(password) ||
          !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
        return 'Password must be at least 8 characters and include uppercase, lowercase, number, and special character.';
      }
      return null;
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  bool sessionWasInvalidated({
    required String accessToken,
    required DateTime? invalidatedAt,
  }) {
    if (invalidatedAt == null || accessToken.isEmpty) return false;
    final issuedAt = _jwtIssuedAt(accessToken);
    if (issuedAt == null) return false;
    return issuedAt.isBefore(invalidatedAt);
  }

  Map<String, dynamic> _map(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    throw const PlatformSettingsException('Platform settings are unavailable.');
  }

  DateTime? _jwtIssuedAt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = String.fromCharCodes(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final match = RegExp(r'"iat"\s*:\s*(\d+)').firstMatch(payload);
      final seconds = int.tryParse(match?.group(1) ?? '');
      if (seconds == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  String _friendlyMessage(Object error) {
    if (error is PlatformSettingsException) return error.message;
    if (error is PostgrestException) {
      final lower = error.message.toLowerCase();
      if (lower.contains('public registration')) {
        return publicRegistrationDisabledMessage;
      }
      if (lower.contains('password changes')) {
        return passwordChangeDisabledMessage;
      }
      if (lower.contains('at least one active admin')) {
        return 'At least one active admin account must remain.';
      }
      if (lower.contains('admin user creation')) {
        return 'Admin user creation is currently disabled.';
      }
      if (lower.contains('password')) {
        return error.message;
      }
      if (lower.contains('admin access') || error.code == '42501') {
        return 'Admin access required.';
      }
      if (lower.contains('invalid') || lower.contains('unknown')) {
        return 'Platform settings are invalid. Refresh and try again.';
      }
    }
    return 'Platform settings could not be loaded. Please try again.';
  }
}

class PlatformSettingsException implements Exception {
  const PlatformSettingsException(this.message);

  final String message;

  @override
  String toString() => message;
}
