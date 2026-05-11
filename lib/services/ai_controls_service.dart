import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_controls_model.dart';

class AiControlsService {
  AiControlsService._();

  static final instance = AiControlsService._();

  static const aiDisabledMessage =
      'AI features are currently disabled by the administrator.';
  static const blockedMessage =
      'You do not currently have permission to use this AI feature.';
  static const dailyLimitMessage =
      'You have reached your daily AI generation limit.';

  SupabaseClient get _client => Supabase.instance.client;

  Future<AiControlsConfig> getAdminConfig() async {
    try {
      final response = await _client.rpc('get_admin_ai_controls_config');
      return AiControlsConfig.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (error) {
      throw AiControlsException(_friendlyMessage(error));
    }
  }

  Future<AiControlsConfig> getEffectiveConfig() async {
    try {
      final response = await _client.rpc('get_effective_ai_controls');
      return AiControlsConfig.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (error) {
      throw AiControlsException(_friendlyMessage(error));
    }
  }

  Future<AiControlsConfig> updateAdminConfig(AiControlsConfig config) async {
    try {
      final response = await _client.rpc(
        'update_admin_ai_controls_config',
        params: {'p_config': config.toJson()},
      );
      return AiControlsConfig.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (error) {
      throw AiControlsException(_friendlyMessage(error));
    }
  }

  Future<AiControlsConfig> resetAdminConfig() async {
    try {
      final response = await _client.rpc('reset_admin_ai_controls_config');
      return AiControlsConfig.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (error) {
      throw AiControlsException(_friendlyMessage(error));
    }
  }

  Future<AiUsageStats> getUsageStats() async {
    try {
      final response = await _client.rpc('get_admin_ai_usage_stats');
      return AiUsageStats.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (error) {
      throw AiControlsException(_friendlyMessage(error));
    }
  }

  Future<AiGenerationReservation> beginGeneration({
    required String featureType,
    int? requestedCount,
  }) async {
    try {
      final response = await _client.rpc(
        'begin_ai_generation_request',
        params: {
          'p_feature_type': featureType,
          'p_requested_count': requestedCount,
        },
      );
      return AiGenerationReservation.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (error) {
      throw AiControlsException(_friendlyMessage(error));
    }
  }

  Future<void> finishGeneration({
    required String logId,
    required bool success,
    String? modelUsed,
    bool fallbackUsed = false,
    String? errorCategory,
  }) async {
    if (logId.isEmpty) return;
    try {
      await _client.rpc(
        'finish_ai_generation_request',
        params: {
          'p_log_id': logId,
          'p_model_used': modelUsed,
          'p_fallback_used': fallbackUsed,
          'p_success': success,
          'p_error_category': errorCategory,
        },
      );
    } catch (_) {
      // Logging must not mask the original generation result.
    }
  }

  String _friendlyMessage(Object error) {
    if (error is AiControlsException) return error.message;
    if (error is PostgrestException) {
      final lower = error.message.toLowerCase();
      if (lower.contains('disabled by the administrator')) {
        return aiDisabledMessage;
      }
      if (lower.contains('daily ai generation limit')) {
        return dailyLimitMessage;
      }
      if (lower.contains('permission') ||
          lower.contains('feature') ||
          error.code == '42501') {
        return blockedMessage;
      }
      if (lower.contains('question limit')) {
        return 'The requested quiz exceeds the configured AI question limit.';
      }
      if (lower.contains('card limit')) {
        return 'The requested flashcard set exceeds the configured AI card limit.';
      }
      if (lower.contains('invalid') || lower.contains('unknown')) {
        return 'The AI controls configuration is invalid. Refresh and try again.';
      }
    }
    return 'Unable to use AI right now. Please try again.';
  }
}

class AiControlsException implements Exception {
  const AiControlsException(this.message);

  final String message;

  @override
  String toString() => message;
}
