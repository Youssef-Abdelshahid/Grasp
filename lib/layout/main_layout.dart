import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/user_utils.dart';
import '../core/widgets/top_bar_actions.dart';
import '../features/dashboard/pages/instructor_dashboard_page.dart';
import '../features/profile/instructor_profile_page.dart';
import '../features/courses/pages/courses_page.dart';
import '../features/calendar/instructor_calendar_page.dart';
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

  static const _pageTitles = ['Dashboard', 'Courses', 'Calendar', 'Settings'];

  List<Widget> get _pages => [
    InstructorDashboardPage(onNavigateToTab: _selectTab),
    const CoursesPage(),
    const InstructorCalendarPage(),
    const InstructorSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
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

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
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
              onItemSelected: _selectTab,
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
            _selectTab(i);
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
        MobileNotificationBadgeButton(onPressed: _openNotifications),
        ProfileAvatarButton(
          initials: UserUtils.initials(user?.name ?? 'Instructor'),
          backgroundColor: AppColors.primaryLight,
          textColor: AppColors.primary,
          radius: 16,
          padding: const EdgeInsets.only(right: 16, left: 4),
          onTap: _openProfile,
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
          NotificationBadgeButton(
            onPressed: () async => onNotificationsTap?.call(),
          ),
          const SizedBox(width: 12),
          ProfileAvatarButton(
            initials: initials,
            backgroundColor: AppColors.primaryLight,
            textColor: AppColors.primary,
            onTap: () => onProfileTap?.call(),
          ),
        ],
      ),
    );
  }
}
