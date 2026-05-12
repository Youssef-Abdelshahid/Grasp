import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../models/dashboard_models.dart';
import '../../auth/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../content/admin_announcements_page.dart';
import '../content/admin_assessments_page.dart';
import '../content/admin_courses_page.dart';
import '../content/admin_flashcards_page.dart';
import '../content/admin_materials_page.dart';
import '../content/admin_study_notes_page.dart';
import '../profile/admin_profile_page.dart';
import '../users/admin_users_page.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;
    final user = ref.watch(currentUserProvider);

    return ref
        .watch(adminDashboardProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _DashboardErrorState(
            onRetry: () => ref.invalidate(adminDashboardProvider),
          ),
          data: (summary) {
            final stats = [
              (
                label: 'Total Users',
                value: '${summary.totalUsers}',
                icon: Icons.people_rounded,
                color: AppColors.primary,
                bg: AppColors.primaryLight,
              ),
              (
                label: 'Students',
                value: '${summary.studentsCount}',
                icon: Icons.school_rounded,
                color: AppColors.cyan,
                bg: AppColors.cyanLight,
              ),
              (
                label: 'Instructors',
                value: '${summary.instructorsCount}',
                icon: Icons.person_rounded,
                color: AppColors.violet,
                bg: AppColors.violetLight,
              ),
              (
                label: 'Total Courses',
                value: '${summary.totalCourses}',
                icon: Icons.menu_book_rounded,
                color: AppColors.emerald,
                bg: AppColors.emeraldLight,
              ),
              (
                label: 'Materials',
                value: '${summary.totalMaterials}',
                icon: Icons.description_rounded,
                color: AppColors.amber,
                bg: AppColors.amberLight,
              ),
              (
                label: 'Assessments',
                value: '${summary.totalQuizzes + summary.totalAssignments}',
                icon: Icons.assignment_rounded,
                color: AppColors.rose,
                bg: AppColors.roseLight,
              ),
              (
                label: 'Announcements',
                value: '${summary.totalAnnouncements}',
                icon: Icons.campaign_rounded,
                color: AppColors.success,
                bg: AppColors.successLight,
              ),
            ];

            return SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 28 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcome(
                    userName: user?.name ?? 'Admin',
                    totalUsers: summary.totalUsers,
                    alertsCount: summary.recentActivityCount,
                  ),
                  const SizedBox(height: 24),
                  _buildStatsGrid(isWide, stats),
                  const SizedBox(height: 28),
                  _buildQuickActions(context, isWide),
                  const SizedBox(height: 28),
                  _buildAlerts(summary.alerts),
                  const SizedBox(height: 28),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildRecentRegistrations(
                            context,
                            summary.recentRegistrations,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildSystemActivity(summary.systemActivity),
                        ),
                      ],
                    )
                  else ...[
                    _buildRecentRegistrations(
                      context,
                      summary.recentRegistrations,
                    ),
                    const SizedBox(height: 24),
                    _buildSystemActivity(summary.systemActivity),
                  ],
                  const SizedBox(height: 28),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildActivityList(
                            'Recent Courses',
                            summary.recentCourses,
                            Icons.menu_book_rounded,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildActivityList(
                            'Recent Materials',
                            summary.recentMaterials,
                            Icons.description_rounded,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildActivityList(
                            'Recent Assessments',
                            summary.recentAssessments,
                            Icons.assignment_rounded,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildActivityList(
                      'Recent Courses',
                      summary.recentCourses,
                      Icons.menu_book_rounded,
                    ),
                    const SizedBox(height: 24),
                    _buildActivityList(
                      'Recent Materials',
                      summary.recentMaterials,
                      Icons.description_rounded,
                    ),
                    const SizedBox(height: 24),
                    _buildActivityList(
                      'Recent Assessments',
                      summary.recentAssessments,
                      Icons.assignment_rounded,
                    ),
                  ],
                ],
              ),
            );
          },
        );
  }

  Widget _buildWelcome({
    required String userName,
    required int totalUsers,
    required int alertsCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalUsers users are on the platform right now, with $alertsCount admin actions recorded this week.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isWide, List<dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Platform Overview'),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 160,
          ),
          itemCount: stats.length,
          itemBuilder: (_, index) {
            final item = stats[index];
            return StatCard(
              label: item.label,
              value: item.value,
              icon: item.icon,
              color: item.color,
              bgColor: item.bg,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isWide) {
    final actions = [
      (
        icon: Icons.people_rounded,
        label: 'Users',
        color: AppColors.primary,
        bg: AppColors.primaryLight,
        onTap: () => _openAdminTab(context, 1, const AdminUsersPage()),
      ),
      (
        icon: Icons.menu_book_rounded,
        label: 'Courses',
        color: AppColors.emerald,
        bg: AppColors.emeraldLight,
        onTap: () => _openAdminTab(context, 2, const AdminCoursesPage()),
      ),
      (
        icon: Icons.description_rounded,
        label: 'Materials',
        color: AppColors.amber,
        bg: AppColors.amberLight,
        onTap: () => _openAdminTab(context, 3, const AdminMaterialsPage()),
      ),
      (
        icon: Icons.quiz_rounded,
        label: 'Quizzes',
        color: AppColors.violet,
        bg: AppColors.violetLight,
        onTap: () =>
            _openAdminTab(context, 4, const AdminAssessmentsPage.quizzes()),
      ),
      (
        icon: Icons.assignment_rounded,
        label: 'Assignments',
        color: AppColors.rose,
        bg: AppColors.roseLight,
        onTap: () =>
            _openAdminTab(context, 5, const AdminAssessmentsPage.assignments()),
      ),
      (
        icon: Icons.campaign_rounded,
        label: 'Announcements',
        color: AppColors.success,
        bg: AppColors.successLight,
        onTap: () => _openAdminTab(context, 8, const AdminAnnouncementsPage()),
      ),
      (
        icon: Icons.style_rounded,
        label: 'Flashcards',
        color: AppColors.cyan,
        bg: AppColors.cyanLight,
        onTap: () => _openAdminTab(context, 6, const AdminFlashcardsPage()),
      ),
      (
        icon: Icons.note_alt_rounded,
        label: 'Study Notes',
        color: AppColors.violet,
        bg: AppColors.violetLight,
        onTap: () => _openAdminTab(context, 7, const AdminStudyNotesPage()),
      ),
      (
        icon: Icons.account_circle_rounded,
        label: 'Profile',
        color: AppColors.textSecondary,
        bg: AppColors.background,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminProfilePage()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 64,
          ),
          itemCount: actions.length,
          itemBuilder: (_, index) {
            final action = actions[index];
            return _QuickActionCard(
              icon: action.icon,
              label: action.label,
              color: action.color,
              bg: action.bg,
              onTap: action.onTap,
            );
          },
        ),
      ],
    );
  }

  void _openAdminTab(BuildContext context, int index, Widget page) {
    final navigate = onNavigateToTab;
    if (navigate != null) {
      navigate(index);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildAlerts(List<AdminAlertItem> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'System Alerts'),
        const SizedBox(height: 12),
        if (alerts.isEmpty)
          const EmptyState(
            icon: Icons.notifications_active_rounded,
            title: 'No active alerts',
            subtitle: 'System alerts and activity warnings will appear here.',
          )
        else
          ...alerts.map((alert) {
            final isWarning = alert.level == 'warning';
            final color = isWarning ? AppColors.amber : AppColors.primary;
            final bg = isWarning
                ? AppColors.amberLight
                : AppColors.primaryLight;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isWarning ? Icons.warning_rounded : Icons.info_rounded,
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title, style: AppTextStyles.label),
                        const SizedBox(height: 2),
                        Text(alert.body, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRecentRegistrations(
    BuildContext context,
    List<AdminRegistrationItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Registrations',
          actionLabel: 'View Users',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminUsersPage()),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const EmptyState(
            icon: Icons.person_add_alt_1_rounded,
            title: 'No registrations yet',
            subtitle: 'New platform signups will appear here.',
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, index) {
                final item = items[index];
                final isInstructor = item.role == 'Instructor';
                final color = isInstructor ? AppColors.violet : AppColors.cyan;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(item.name, style: AppTextStyles.label),
                  subtitle: Text(item.email, style: AppTextStyles.caption),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(item.role, style: AppTextStyles.caption),
                      const SizedBox(height: 3),
                      Text(item.timeLabel, style: AppTextStyles.caption),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSystemActivity(List<DashboardActivityItem> items) {
    return _buildActivityList(
      'System Activity',
      items,
      Icons.analytics_rounded,
    );
  }

  Widget _buildActivityList(
    String title,
    List<DashboardActivityItem> items,
    IconData emptyIcon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 12),
        if (items.isEmpty)
          EmptyState(
            icon: emptyIcon,
            title: 'No items yet',
            subtitle: 'Recent platform content and activity will appear here.',
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  title: Text(item.title, style: AppTextStyles.label),
                  subtitle: Text(item.subtitle, style: AppTextStyles.caption),
                  trailing: Text(
                    item.timestampLabel,
                    style: AppTextStyles.caption,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40),
            const SizedBox(height: 12),
            Text(
              'Failed to load admin dashboard data.',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the migration has been applied and your account role is set to admin in the profiles table.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
