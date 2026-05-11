import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';
import '../models/user_settings_model.dart';
import 'auth_service.dart';
import 'platform_settings_service.dart';
import 'user_settings_service.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    if (AuthService.instance.currentUser?.role.value == 'admin') {
      final platform = await PlatformSettingsService.instance
          .getEffectiveSettings();
      if (!platform.adminNotifications) return const [];
    }
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final notifications = (response as List<dynamic>)
        .map(
          (item) => NotificationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    return _filterByPreferences(notifications);
  }

  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;
    if (AuthService.instance.currentUser?.role.value == 'admin') {
      final platform = await PlatformSettingsService.instance
          .getEffectiveSettings();
      if (!platform.adminNotifications) return 0;
    }
    final response = await _client
        .from('notifications')
        .select('id, category')
        .eq('user_id', userId)
        .eq('is_read', false);
    final notifications = (response as List<dynamic>)
        .map(
          (item) => NotificationModel(
            id: item['id'] as String,
            userId: userId,
            title: '',
            body: '',
            category: item['category'] as String? ?? 'general',
            isRead: false,
            createdAt: DateTime.now(),
          ),
        )
        .toList();
    return (await _filterByPreferences(notifications)).length;
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<List<NotificationModel>> _filterByPreferences(
    List<NotificationModel> notifications,
  ) async {
    final settings = await UserSettingsService.instance
        .getCurrentSettingsOrNull();
    if (settings == null) return notifications;
    return notifications
        .where((item) => _categoryEnabled(item.category, settings))
        .toList();
  }

  bool _categoryEnabled(String category, UserSettings settings) {
    return switch (settings) {
      StudentSettings() => switch (category) {
        'quiz' => settings.quizAlerts,
        'assignment' => settings.assignmentAlerts,
        'announcement' => settings.announcementAlerts,
        _ => true,
      },
      InstructorSettings() => switch (category) {
        'quiz_submission' => settings.quizSubmissionAlerts,
        'assignment_submission' => settings.assignmentSubmissionAlerts,
        'announcement' => settings.announcementAlerts,
        _ => true,
      },
    };
  }
}
