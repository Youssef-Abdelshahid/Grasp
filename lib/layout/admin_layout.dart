import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/user_utils.dart';
import '../core/widgets/top_bar_actions.dart';
import '../features/admin/dashboard/admin_dashboard_page.dart';
import '../features/admin/content/admin_announcements_page.dart';
import '../features/admin/content/admin_assessments_page.dart';
import '../features/admin/content/admin_courses_page.dart';
import '../features/admin/content/admin_flashcards_page.dart';
import '../features/admin/content/admin_materials_page.dart';
import '../features/admin/content/admin_study_notes_page.dart';
import '../features/admin/users/admin_users_page.dart';
import '../features/admin/permissions/admin_permissions_page.dart';
import '../features/admin/ai_controls/admin_ai_controls_page.dart';
import '../features/admin/upload_limits/admin_upload_limits_page.dart';
import '../features/admin/platform/admin_platform_page.dart';
import '../features/admin/profile/admin_profile_page.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/platform_settings/providers/platform_settings_provider.dart';
import '../features/notifications/notifications_page.dart';
import '../widgets/auth/logout_flow.dart';

class AdminLayout extends ConsumerStatefulWidget {
  final int initialIndex;

  const AdminLayout({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  late int _selectedIndex;

  static const _pageTitles = [
    'Dashboard',
    'Users',
    'Courses',
    'Materials',
    'Quizzes',
    'Assignments',
    'Flashcards',
    'Study Notes',
    'Announcements',
    'Permissions',
    'AI Controls',
    'Upload Limits',
    'Platform',
  ];

  List<Widget> get _pages => [
    AdminDashboardPage(onNavigateToTab: _selectTab),
    const AdminUsersPage(),
    const AdminCoursesPage(),
    const AdminMaterialsPage(),
    const AdminAssessmentsPage.quizzes(key: ValueKey('admin-quizzes-page')),
    const AdminAssessmentsPage.assignments(
      key: ValueKey('admin-assignments-page'),
    ),
    const AdminFlashcardsPage(),
    const AdminStudyNotesPage(),
    const AdminAnnouncementsPage(),
    const AdminPermissionsPage(),
    const AdminAiControlsPage(),
    const AdminUploadLimitsPage(),
    const AdminPlatformPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant AdminLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = widget.initialIndex;
    }
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
      MaterialPageRoute(builder: (_) => const AdminProfilePage()),
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _selectTab,
              onProfileTap: _openProfile,
            ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(
                    title: _pageTitles[_selectedIndex],
                    onNotificationsTap: _openNotifications,
                    onProfileTap: _openProfile,
                    initials: UserUtils.initials(user?.name ?? 'Admin'),
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
        child: _AdminSidebar(
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
    final user = ref.watch(currentUserProvider);
    return AppBar(
      backgroundColor: AppColors.surface,
      title: Text(_pageTitles[_selectedIndex]),
      actions: [
        MobileNotificationBadgeButton(onPressed: _openNotifications),
        ProfileAvatarButton(
          initials: UserUtils.initials(user?.name ?? 'Admin'),
          backgroundColor: AppColors.roseLight,
          textColor: AppColors.rose,
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

class _AdminSidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onProfileTap;

  const _AdminSidebar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onProfileTap,
  });

  static const _navItems = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.people_rounded, label: 'Users'),
    (icon: Icons.menu_book_rounded, label: 'Courses'),
    (icon: Icons.description_rounded, label: 'Materials'),
    (icon: Icons.quiz_rounded, label: 'Quizzes'),
    (icon: Icons.assignment_rounded, label: 'Assignments'),
    (icon: Icons.style_rounded, label: 'Flashcards'),
    (icon: Icons.note_alt_rounded, label: 'Study Notes'),
    (icon: Icons.campaign_rounded, label: 'Announcements'),
    (icon: Icons.shield_rounded, label: 'Permissions'),
    (icon: Icons.auto_awesome_rounded, label: 'AI Controls'),
    (icon: Icons.upload_rounded, label: 'Upload Limits'),
    (icon: Icons.settings_rounded, label: 'Platform'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: AppConstants.sidebarWidth,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          _buildLogo(ref),
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
                ...List.generate(
                  _navItems.length,
                  (i) => _NavItem(
                    icon: _navItems[i].icon,
                    label: _navItems[i].label,
                    isSelected: selectedIndex == i,
                    onTap: () => onItemSelected(i),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildLogo(WidgetRef ref) {
    final platformName = ref
        .watch(platformSettingsProvider)
        .valueOrDefaults
        .platformName;
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platformName,
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.rose.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'ADMIN',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.rose,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.sidebarHover)),
      ),
      child: Column(
        children: [
          _NavItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isSelected: false,
            onTap: () => logoutAndReturnToAuthGate(context, ref),
          ),
          const SizedBox(height: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onProfileTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sidebarHover,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.rose.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.rose.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'System Admin',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.sidebarText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'View Profile',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.rose,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: AppColors.sidebarTextMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
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

class _AdminTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final String initials;

  const _AdminTopBar({
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
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.roseLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'ADMIN',
              style: AppTextStyles.overline.copyWith(
                color: AppColors.rose,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          NotificationBadgeButton(
            onPressed: () async => onNotificationsTap?.call(),
          ),
          const SizedBox(width: 12),
          ProfileAvatarButton(
            initials: initials,
            backgroundColor: AppColors.roseLight,
            textColor: AppColors.rose,
            onTap: () => onProfileTap?.call(),
          ),
        ],
      ),
    );
  }
}
