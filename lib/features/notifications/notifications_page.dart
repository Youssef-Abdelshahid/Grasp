import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/file_utils.dart';
import '../../models/notification_model.dart';
import 'providers/notification_providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  int _selectedFilter = 0;

  static const _filters = [
    'All',
    'Unread',
    'Assignments',
    'Quizzes',
    'Announcements',
  ];

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return notificationsAsync.when(
      loading: () => _buildScaffold(
        notifications: const [],
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) =>
          _buildScaffold(notifications: const [], body: _buildErrorState()),
      data: (notifications) {
        final filtered = _filterNotifications(notifications);
        return _buildScaffold(
          notifications: notifications,
          body: filtered.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, index) => _NotificationTile(
                      notification: filtered[index],
                      onTap: () => _handleTap(filtered[index]),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildScaffold({
    required List<NotificationModel> notifications,
    required Widget body,
  }) {
    final unreadCount = notifications.where((item) => !item.isRead).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: BackButton(color: AppColors.textPrimary),
        title: Row(
          children: [
            Text('Notifications', style: AppTextStyles.h2),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$unreadCount',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: unreadCount == 0 ? null : _markAllRead,
            child: Text(
              'Mark all read',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(unreadCount),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildFilters(int unreadCount) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filters.length, (index) {
            final isSelected = _selectedFilter == index;
            final showBadge = index == 1 && unreadCount > 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _filters[index],
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 32,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text('No notifications', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('You\'re all caught up!', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 40),
          const SizedBox(height: 12),
          Text('Unable to load notifications', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
  ) {
    switch (_selectedFilter) {
      case 1:
        return notifications.where((item) => !item.isRead).toList();
      case 2:
        return notifications
            .where((item) => item.category.contains('assignment'))
            .toList();
      case 3:
        return notifications
            .where((item) => item.category.contains('quiz'))
            .toList();
      case 4:
        return notifications
            .where((item) => item.category.contains('announcement'))
            .toList();
      default:
        return notifications;
    }
  }

  Future<void> _handleTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await ref
          .read(notificationsProvider.notifier)
          .markAsRead(notification.id);
    }
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationsProvider.notifier).markAllAsRead();
  }

  Future<void> _refresh() async {
    await ref.read(notificationsProvider.notifier).refresh();
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleForCategory(notification.category);
    return Material(
      color: notification.isRead
          ? AppColors.surface
          : AppColors.primaryLight.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(style.icon, color: style.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FileUtils.formatDateTime(notification.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _NotificationVisualStyle _styleForCategory(String category) {
    if (category.contains('assignment')) {
      return _NotificationVisualStyle(
        icon: Icons.assignment_rounded,
        color: AppColors.emerald,
        background: AppColors.emeraldLight,
      );
    }
    if (category.contains('quiz')) {
      return _NotificationVisualStyle(
        icon: Icons.quiz_rounded,
        color: AppColors.violet,
        background: AppColors.violetLight,
      );
    }
    if (category.contains('announcement')) {
      return _NotificationVisualStyle(
        icon: Icons.campaign_rounded,
        color: AppColors.cyan,
        background: AppColors.cyanLight,
      );
    }
    return _NotificationVisualStyle(
      icon: Icons.notifications_rounded,
      color: AppColors.primary,
      background: AppColors.primaryLight,
    );
  }
}

class _NotificationVisualStyle {
  const _NotificationVisualStyle({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;
}
