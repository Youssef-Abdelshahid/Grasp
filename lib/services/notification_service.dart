import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => NotificationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('is_read', false);
  }
}
