import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../courses/student_courses_page.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  static const _stats = [
    (
      label: 'Enrolled Courses',
      value: '5',
      icon: Icons.menu_book_rounded,
      color: AppColors.primary,
      bg: AppColors.primaryLight,
    ),
    (
      label: 'Pending Tasks',
      value: '4',
      icon: Icons.assignment_late_rounded,
      color: AppColors.amber,
      bg: AppColors.amberLight,
    ),
    (
      label: 'Avg. Score',
      value: '88%',
      icon: Icons.insights_rounded,
      color: AppColors.emerald,
      bg: AppColors.emeraldLight,
    ),
    (
      label: 'Completed',
      value: '12',
      icon: Icons.check_circle_rounded,
      color: AppColors.cyan,
      bg: AppColors.cyanLight,
    ),
  ];

  static const _deadlines = [
    (
      title: 'Quiz 2: Core Principles',
      course: 'Mobile Dev · CS401',
      due: 'Apr 10',
      type: 'Quiz',
      color: AppColors.violet,
      bg: AppColors.violetLight,
    ),
    (
      title: 'Assignment 2: Implementation',
      course: 'Machine Learning · CS310',
      due: 'Apr 12',
      type: 'Assignment',
      color: AppColors.emerald,
      bg: AppColors.emeraldLight,
    ),
    (
      title: 'Midterm Review Quiz',
      course: 'Database Systems · CS302',
      due: 'Apr 15',
      type: 'Quiz',
      color: AppColors.violet,
      bg: AppColors.violetLight,
    ),
    (
      title: 'Lab Sheet 3',
      course: 'Computer Networks · CS315',
      due: 'Apr 18',
      type: 'Assignment',
      color: AppColors.emerald,
      bg: AppColors.emeraldLight,
    ),
  ];

  static const _announcements = [
    (
      title: 'Office hours moved to Thursday',
      course: 'Mobile Dev · CS401',
      time: '2h ago',
      isPinned: true,
    ),
    (
      title: 'Assignment 2 deadline extended by 3 days',
      course: 'Machine Learning · CS310',
      time: '5h ago',
      isPinned: false,
    ),
    (
      title: 'Midterm exam schedule published',
      course: 'Database Systems · CS302',
      time: 'Yesterday',
      isPinned: false,
    ),
  ];

  static const _quickActions = [
    (icon: Icons.play_circle_rounded, label: 'Continue Studying', color: AppColors.primary, bg: AppColors.primaryLight),
    (icon: Icons.style_rounded, label: 'Flashcards', color: AppColors.violet, bg: AppColors.violetLight),
    (icon: Icons.quiz_rounded, label: 'Practice Quiz', color: AppColors.emerald, bg: AppColors.emeraldLight),
    (icon: Icons.auto_awesome_rounded, label: 'AI Tutor', color: AppColors.amber, bg: AppColors.amberLight),
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
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildDeadlines()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildAnnouncements()),
              ],
            )
          else ...[
            _buildDeadlines(),
            const SizedBox(height: 28),
            _buildAnnouncements(),
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
          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
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
                  'Good morning, Ahmed!',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'You have 4 pending tasks and 3 new announcements.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentCoursesPage(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Continue Studying'),
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
              child: const Icon(Icons.auto_stories_rounded,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Study Actions'),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentCoursesPage(),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeadlines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Upcoming Deadlines', actionLabel: 'View all', onAction: () {}),
        const SizedBox(height: 12),
        ..._deadlines.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: d.bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        d.type == 'Quiz'
                            ? Icons.quiz_rounded
                            : Icons.assignment_rounded,
                        color: d.color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.title,
                            style: AppTextStyles.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(d.course,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: d.bg,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            d.type,
                            style: AppTextStyles.caption.copyWith(
                              color: d.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Due: ${d.due}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.amber,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildAnnouncements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Recent Announcements', actionLabel: 'View all', onAction: () {}),
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
            itemCount: _announcements.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) {
              final a = _announcements[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: a.isPinned
                        ? AppColors.amberLight
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    a.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.campaign_rounded,
                    color: a.isPinned ? AppColors.amber : AppColors.primary,
                    size: 16,
                  ),
                ),
                title: Text(
                  a.title,
                  style: AppTextStyles.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${a.course} · ${a.time}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
