import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => NotificationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (response as List<dynamic>).length;
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
}
