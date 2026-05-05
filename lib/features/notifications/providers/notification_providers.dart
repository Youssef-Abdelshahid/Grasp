import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/notification_model.dart';

final unreadNotificationsProvider =
    AsyncNotifierProvider<UnreadNotificationsNotifier, int>(
      UnreadNotificationsNotifier.new,
    );

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
      NotificationsNotifier.new,
    );

class UnreadNotificationsNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() {
    return ref.watch(notificationServiceProvider).getUnreadCount();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationServiceProvider).getUnreadCount(),
    );
  }
}

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() {
    return ref.watch(notificationServiceProvider).getNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    await ref.read(notificationServiceProvider).markAsRead(notificationId);
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidateSelf();
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationServiceProvider).markAllAsRead();
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidateSelf();
  }
}
