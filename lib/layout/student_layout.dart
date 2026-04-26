import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/user_utils.dart';
import '../routing/app_router.dart';
import '../features/student/profile/student_profile_page.dart';
import '../features/student/dashboard/student_dashboard_page.dart';
import '../features/student/courses/student_courses_page.dart';
import '../features/student/calendar/student_calendar_page.dart';
import '../features/student/profile/student_settings_page.dart';
import '../features/notifications/notifications_page.dart';
import '../services/auth_service.dart';

class StudentLayout extends StatefulWidget {
  final int initialIndex;

  const StudentLayout({super.key, this.initialIndex = 0});

  @override
  State<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends State<StudentLayout> {
  late int _selectedIndex;

  static const _pageTitles = [
    'Dashboard',
    'My Courses',
    'Calendar',
    'Settings',
  ];

  static final _pages = [
    const StudentDashboardPage(),
    const StudentCoursesPage(),
    const StudentCalendarPage(),
    const StudentSettingsPage(),
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
      MaterialPageRoute(builder: (_) => const StudentProfilePage()),
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
            _StudentSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (i) => setState(() => _selectedIndex = i),
              onProfileTap: _openProfile,
            ),
            Expanded(
              child: Column(
                children: [
                  _StudentTopBar(
                    title: _pageTitles[_selectedIndex],
                    onNotificationsTap: _openNotifications,
                    onProfileTap: _openProfile,
                    initials: UserUtils.initials(user?.name ?? 'Student'),
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
        child: _StudentSidebar(
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
              backgroundColor: AppColors.cyanLight,
              child: Text(
                UserUtils.initials(user?.name ?? 'Student'),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.cyan,
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

class _StudentSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onProfileTap;

  const _StudentSidebar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onProfileTap,
  });

  static const _navItems = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.menu_book_rounded, label: 'My Courses'),
    (icon: Icons.calendar_month_rounded, label: 'Calendar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.sidebarWidth,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
                  child: Text(
                    'NAVIGATION',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.sidebarTextMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...List.generate(_navItems.length, (i) {
                  return _SidebarNavItem(
                    icon: _navItems[i].icon,
                    label: _navItems[i].label,
                    isSelected: selectedIndex == i,
                    onTap: () => onItemSelected(i),
                  );
                }),
              ],
            ),
          ),
          _buildBottomSection(context),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.sidebarHover)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            AppConstants.appName,
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = user?.name ?? 'Student';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.sidebarHover)),
      ),
      child: Column(
        children: [
          _SidebarNavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            isSelected: selectedIndex == 3,
            onTap: () => onItemSelected(3),
          ),
          _SidebarNavItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isSelected: false,
            onTap: () async {
              await AuthService.instance.logout();
              if (!context.mounted) {
                return;
              }
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.landing,
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedIndex == 3
                    ? AppColors.sidebarActive
                    : AppColors.sidebarHover,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.cyan,
                    child: Text(
                      UserUtils.initials(name),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.sidebarText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.role.label ?? 'Student',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.sidebarTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.sidebarTextMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: isSelected ? Colors.white : AppColors.sidebarText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final String initials;

  const _StudentTopBar({
    required this.title,
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
              backgroundColor: AppColors.cyanLight,
              child: Text(
                initials,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.cyan,
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
