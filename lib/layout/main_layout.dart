import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/user_utils.dart';
import '../features/dashboard/pages/instructor_dashboard_page.dart';
import '../features/profile/instructor_profile_page.dart';
import '../features/courses/pages/courses_page.dart';
import '../features/calendar/instructor_calendar_page.dart';
import '../features/ai_review/ai_review_page.dart';
import '../features/profile/instructor_settings_page.dart';
import '../features/notifications/notifications_page.dart';
import '../services/auth_service.dart';
import 'app_sidebar.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  static const _pageTitles = [
    'Dashboard',
    'Courses',
    'Calendar',
    'AI Review',
    'Settings',
  ];

  static const _pages = [
    InstructorDashboardPage(),
    CoursesPage(),
    InstructorCalendarPage(),
    AiReviewPage(),
    InstructorSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InstructorProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (i) => setState(() => _selectedIndex = i),
              onProfileTap: _openProfile,
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: _pageTitles[_selectedIndex],
                    onMenuTap: null,
                    onNotificationsTap: _openNotifications,
                    onProfileTap: _openProfile,
                    initials: UserUtils.initials(user?.name ?? 'Instructor'),
                  ),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildMobileAppBar(),
      drawer: Drawer(
        child: AppSidebar(
          selectedIndex: _selectedIndex,
          onItemSelected: (i) {
            setState(() => _selectedIndex = i);
            Navigator.pop(context);
          },
          onProfileTap: () {
            Navigator.pop(context);
            _openProfile();
          },
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  AppBar _buildMobileAppBar() {
    final user = AuthService.instance.currentUser;
    return AppBar(
      backgroundColor: AppColors.surface,
      title: Text(_pageTitles[_selectedIndex]),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
          onPressed: _openNotifications,
        ),
        GestureDetector(
          onTap: _openProfile,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                UserUtils.initials(user?.name ?? 'Instructor'),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final String initials;

  const _TopBar({
    required this.title,
    this.onMenuTap,
    this.onNotificationsTap,
    this.onProfileTap,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (onMenuTap != null)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: onMenuTap,
            ),
          Text(title, style: AppTextStyles.h2),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Search...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onNotificationsTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                initials,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
