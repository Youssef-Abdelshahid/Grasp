import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../users/admin_users_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  static const _stats = [
    (label: 'Total Users', value: '312', icon: Icons.people_rounded, color: AppColors.primary, bg: AppColors.primaryLight),
    (label: 'Students', value: '247', icon: Icons.school_rounded, color: AppColors.cyan, bg: AppColors.cyanLight),
    (label: 'Instructors', value: '18', icon: Icons.person_rounded, color: AppColors.violet, bg: AppColors.violetLight),
    (label: 'Total Courses', value: '42', icon: Icons.menu_book_rounded, color: AppColors.emerald, bg: AppColors.emeraldLight),
    (label: 'Active Courses', value: '31', icon: Icons.play_circle_rounded, color: AppColors.amber, bg: AppColors.amberLight),
    (label: 'AI Tasks Today', value: '47', icon: Icons.auto_awesome_rounded, color: AppColors.rose, bg: AppColors.roseLight),
  ];

  static const _registrations = [
    (name: 'Ahmad Karim', email: 'ahmad.karim@student.edu', role: 'Student', time: 'Today, 9:41 AM', color: AppColors.cyan),
    (name: 'Prof. Sara Mansour', email: 's.mansour@faculty.edu', role: 'Instructor', time: 'Yesterday', color: AppColors.violet),
    (name: 'Nada Omar', email: 'nada.omar@student.edu', role: 'Student', time: '2 days ago', color: AppColors.cyan),
    (name: 'Khaled Ibrahim', email: 'k.ibrahim@student.edu', role: 'Student', time: '2 days ago', color: AppColors.cyan),
    (name: 'Dr. Mohammed Farid', email: 'm.farid@faculty.edu', role: 'Instructor', time: '3 days ago', color: AppColors.violet),
  ];

  static const _activities = [
    (icon: Icons.add_circle_rounded, color: AppColors.emerald, bg: AppColors.emeraldLight, title: 'New course created', subtitle: '"Advanced AI" by Dr. Sara Mansour', time: '30m ago'),
    (icon: Icons.people_rounded, color: AppColors.cyan, bg: AppColors.cyanLight, title: '12 students enrolled', subtitle: 'Mobile Dev · CS401', time: '1h ago'),
    (icon: Icons.auto_awesome_rounded, color: AppColors.violet, bg: AppColors.violetLight, title: 'AI generated 8 items', subtitle: 'Across 3 courses', time: '2h ago'),
    (icon: Icons.quiz_rounded, color: AppColors.amber, bg: AppColors.amberLight, title: 'Quiz published', subtitle: '"Midterm Review" in CS411', time: '3h ago'),
    (icon: Icons.person_add_rounded, color: AppColors.primary, bg: AppColors.primaryLight, title: '5 new registrations', subtitle: 'Platform-wide', time: 'Yesterday'),
  ];

  static const _alerts = [
    (icon: Icons.info_rounded, color: AppColors.primary, bg: AppColors.primaryLight, title: 'Server maintenance scheduled', body: 'Planned downtime on Apr 15 from 2–4 AM. Notify users in advance.'),
    (icon: Icons.warning_rounded, color: AppColors.amber, bg: AppColors.amberLight, title: 'High AI usage detected', body: 'AI task queue reached 85% capacity. Consider scaling resources.'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;
    final padding = EdgeInsets.all(isWide ? 28 : 16);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcome(context),
          const SizedBox(height: 24),
          _buildStatsGrid(isWide),
          const SizedBox(height: 28),
          _buildAlerts(),
          const SizedBox(height: 28),
          _buildQuickActions(context, isWide),
          const SizedBox(height: 28),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRecentRegistrations(context)),
                const SizedBox(width: 20),
                Expanded(child: _buildRecentActivity()),
              ],
            )
          else ...[
            _buildRecentRegistrations(context),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 400;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.rose.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'ADMIN',
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.rose,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Good morning, Admin!',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '5 new registrations today · 47 AI tasks processed · 2 alerts',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.sidebarBg,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('View Reports'),
                ),
              ],
            ),
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 30),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isWide) {
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
          itemCount: _stats.length,
          itemBuilder: (_, i) {
            final s = _stats[i];
            return StatCard(
              label: s.label,
              value: s.value,
              icon: s.icon,
              color: s.color,
              bgColor: s.bg,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'System Alerts', actionLabel: 'Dismiss all', onAction: () {}),
        const SizedBox(height: 12),
        ..._alerts.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: a.color.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: a.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(a.icon, color: a.color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: AppTextStyles.label),
                        const SizedBox(height: 2),
                        Text(a.body, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isWide) {
    final actions = [
      (icon: Icons.people_rounded, label: 'Manage Users', color: AppColors.primary, bg: AppColors.primaryLight,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersPage()))),
      (icon: Icons.menu_book_rounded, label: 'View Courses', color: AppColors.emerald, bg: AppColors.emeraldLight, onTap: () {}),
      (icon: Icons.bar_chart_rounded, label: 'Reports', color: AppColors.violet, bg: AppColors.violetLight, onTap: () {}),
      (icon: Icons.settings_rounded, label: 'Platform Settings', color: AppColors.amber, bg: AppColors.amberLight, onTap: () {}),
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
          itemBuilder: (_, i) {
            final a = actions[i];
            return _QuickActionCard(
              icon: a.icon,
              label: a.label,
              color: a.color,
              bg: a.bg,
              onTap: a.onTap,
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentRegistrations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Registrations',
          actionLabel: 'View all',
          onAction: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AdminUsersPage())),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _registrations.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) {
              final r = _registrations[i];
              final isInstructor = r.role == 'Instructor';
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: r.color.withValues(alpha: 0.15),
                  child: Text(
                    r.name.split(' ').map((w) => w[0]).take(2).join(),
                    style: AppTextStyles.caption.copyWith(
                      color: r.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(r.name,
                    style: AppTextStyles.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(r.email,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isInstructor
                            ? AppColors.violetLight
                            : AppColors.cyanLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        r.role,
                        style: AppTextStyles.caption.copyWith(
                          color:
                              isInstructor ? AppColors.violet : AppColors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(r.time, style: AppTextStyles.caption),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'System Activity', actionLabel: 'View logs', onAction: () {}),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) {
              final a = _activities[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: a.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(a.icon, color: a.color, size: 18),
                ),
                title: Text(a.title,
                    style: AppTextStyles.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(a.subtitle,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: Text(a.time, style: AppTextStyles.caption),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

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
