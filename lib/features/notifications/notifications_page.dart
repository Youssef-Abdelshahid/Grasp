import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedFilter = 0;

  static const _filters = ['All', 'Unread', 'Assignments', 'Quizzes', 'Announcements'];

  static final _notifications = [
    _Notif(
      icon: Icons.assignment_rounded,
      color: AppColors.emerald,
      bg: AppColors.emeraldLight,
      title: 'Assignment 2 due in 2 days',
      body: 'Mobile Dev · CS401 — Submit your implementation before Apr 10.',
      time: '2h ago',
      read: false,
      type: 'Assignments',
    ),
    _Notif(
      icon: Icons.quiz_rounded,
      color: AppColors.violet,
      bg: AppColors.violetLight,
      title: 'Quiz 2 is now available',
      body: 'Machine Learning · CS310 — Quiz closes April 12 at 11:59 PM.',
      time: '4h ago',
      read: false,
      type: 'Quizzes',
    ),
    _Notif(
      icon: Icons.campaign_rounded,
      color: AppColors.cyan,
      bg: AppColors.cyanLight,
      title: 'New announcement in CS302',
      body: 'Dr. Ahmed posted: Office hours have been moved to Thursday.',
      time: '5h ago',
      read: false,
      type: 'Announcements',
    ),
    _Notif(
      icon: Icons.auto_awesome_rounded,
      color: AppColors.amber,
      bg: AppColors.amberLight,
      title: 'AI Flashcards ready',
      body: 'Your flashcard set for Database Systems is ready to review.',
      time: 'Yesterday',
      read: false,
      type: 'All',
    ),
    _Notif(
      icon: Icons.assignment_turned_in_rounded,
      color: AppColors.primary,
      bg: AppColors.primaryLight,
      title: 'Assignment 1 graded',
      body: 'You scored 88/100 on Assignment 1 in Mobile Dev · CS401.',
      time: '2 days ago',
      read: true,
      type: 'Assignments',
    ),
    _Notif(
      icon: Icons.quiz_rounded,
      color: AppColors.violet,
      bg: AppColors.violetLight,
      title: 'Quiz 1 results published',
      body: 'Quiz 1 results are now available. Score: 9/10.',
      time: '3 days ago',
      read: true,
      type: 'Quizzes',
    ),
    _Notif(
      icon: Icons.people_rounded,
      color: AppColors.rose,
      bg: AppColors.roseLight,
      title: 'Welcome to CS315',
      body: 'You have been successfully enrolled in Computer Networks.',
      time: '1 week ago',
      read: true,
      type: 'Announcements',
    ),
    _Notif(
      icon: Icons.upload_file_rounded,
      color: AppColors.cyan,
      bg: AppColors.cyanLight,
      title: 'New material uploaded',
      body: 'Lecture 5 slides are now available in Mobile Dev · CS401.',
      time: '1 week ago',
      read: true,
      type: 'Announcements',
    ),
  ];

  List<_Notif> get _filtered {
    switch (_selectedFilter) {
      case 1:
        return _notifications.where((n) => !n.read).toList();
      case 2:
        return _notifications.where((n) => n.type == 'Assignments').toList();
      case 3:
        return _notifications.where((n) => n.type == 'Quizzes').toList();
      case 4:
        return _notifications.where((n) => n.type == 'Announcements').toList();
      default:
        return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.read).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) =>
                        _buildNotificationTile(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      leading: const BackButton(color: AppColors.textPrimary),
      title: Row(
        children: [
          Text('Notifications', style: AppTextStyles.h2),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$_unreadCount',
                style: AppTextStyles.caption.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {}),
          child: Text(
            'Mark all read',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filters.length, (i) {
            final isSelected = _selectedFilter == i;
            final showBadge = i == 1 && _unreadCount > 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _filters[i],
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
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
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

  Widget _buildNotificationTile(_Notif n) {
    return Material(
      color: n.read
          ? AppColors.surface
          : AppColors.primaryLight.withValues(alpha: 0.35),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: n.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(n.icon, color: n.color, size: 18),
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
                            n.title,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: n.read
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(n.body,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(n.time, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
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
            decoration: const BoxDecoration(
                color: AppColors.background, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_off_rounded,
                size: 32, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text('No notifications', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('You\'re all caught up!', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _Notif {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String body;
  final String time;
  final bool read;
  final String type;

  const _Notif({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
    required this.type,
  });
}
