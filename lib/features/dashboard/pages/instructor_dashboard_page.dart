import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../course_workspace/pages/quiz_builder_page.dart';
import '../../course_workspace/pages/assignment_builder_page.dart';
import '../../courses/pages/create_course_page.dart';

class InstructorDashboardPage extends StatelessWidget {
  const InstructorDashboardPage({super.key});

  static const _stats = [
    (
      label: 'Total Courses',
      value: '6',
      icon: Icons.menu_book_rounded,
      color: AppColors.primary,
      bg: AppColors.primaryLight,
    ),
    (
      label: 'Total Students',
      value: '247',
      icon: Icons.people_rounded,
      color: AppColors.cyan,
      bg: AppColors.cyanLight,
    ),
    (
      label: 'AI Pending',
      value: '3',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.amber,
      bg: AppColors.amberLight,
    ),
    (
      label: 'Avg. Score',
      value: '84%',
      icon: Icons.insights_rounded,
      color: AppColors.emerald,
      bg: AppColors.emeraldLight,
    ),
  ];

  static const _quickActions = [
    (icon: Icons.upload_file_rounded, label: 'Upload Material', color: AppColors.primary, bg: AppColors.primaryLight),
    (icon: Icons.quiz_rounded, label: 'Create Quiz', color: AppColors.violet, bg: AppColors.violetLight),
    (icon: Icons.assignment_rounded, label: 'Create Assignment', color: AppColors.emerald, bg: AppColors.emeraldLight),
    (icon: Icons.auto_awesome_rounded, label: 'AI Generate', color: AppColors.amber, bg: AppColors.amberLight),
  ];

  static const _activities = [
    (icon: Icons.upload_file_rounded, color: AppColors.primary, bg: AppColors.primaryLight, title: 'Lecture 5 uploaded', subtitle: 'Mobile Development · CS401', time: '2h ago'),
    (icon: Icons.auto_awesome_rounded, color: AppColors.violet, bg: AppColors.violetLight, title: 'AI Quiz generated', subtitle: 'Machine Learning · CS310', time: '4h ago'),
    (icon: Icons.people_rounded, color: AppColors.cyan, bg: AppColors.cyanLight, title: '8 new students enrolled', subtitle: 'Database Systems · CS302', time: 'Yesterday'),
    (icon: Icons.assignment_rounded, color: AppColors.emerald, bg: AppColors.emeraldLight, title: 'Assignment published', subtitle: 'Software Engineering · CS411', time: 'Yesterday'),
    (icon: Icons.quiz_rounded, color: AppColors.amber, bg: AppColors.amberLight, title: 'Quiz results ready', subtitle: 'Computer Networks · CS315', time: '2 days ago'),
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
          _buildQuickActions(context, isWide),
          const SizedBox(height: 28),
          SectionHeader(title: 'Recent Activity', actionLabel: 'View all', onAction: () {}),
          const SizedBox(height: 16),
          _buildActivityList(),
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
          colors: [AppColors.primary, Color(0xFF6366F1)],
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
                Text(
                  'Good morning, Dr. Ahmed!',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'You have 3 pending AI tasks and 2 quizzes to review.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Review Pending'),
                ),
              ],
            ),
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded,
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
        const SectionHeader(title: 'Overview'),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
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

  Widget _buildQuickActions(BuildContext context, bool isWide) {
    final callbacks = [
      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCoursePage())),
      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizBuilderPage())),
      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentBuilderPage())),
      () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open a course to use AI generation')),
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
          itemCount: _quickActions.length,
          itemBuilder: (_, i) {
            final a = _quickActions[i];
            return _QuickActionCard(
              icon: a.icon,
              label: a.label,
              color: a.color,
              bg: a.bg,
              onTap: callbacks[i],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityList() {
    return Container(
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
            title: Text(
              a.title,
              style: AppTextStyles.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              a.subtitle,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(a.time, style: AppTextStyles.caption),
          );
        },
      ),
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
