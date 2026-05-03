import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../models/dashboard_models.dart';
import '../../../services/auth_service.dart';
import '../../../services/dashboard_service.dart';
import '../../courses/pages/create_course_page.dart';
import '../../courses/pages/courses_page.dart';

class InstructorDashboardPage extends StatefulWidget {
  const InstructorDashboardPage({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  State<InstructorDashboardPage> createState() =>
      _InstructorDashboardPageState();
}

class _InstructorDashboardPageState extends State<InstructorDashboardPage> {
  late Future<InstructorDashboardSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = DashboardService.instance.getInstructorSummary();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;
    final user = AuthService.instance.currentUser;

    return FutureBuilder<InstructorDashboardSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _DashboardErrorState(
            onRetry: () {
              setState(() {
                _summaryFuture = DashboardService.instance
                    .getInstructorSummary();
              });
            },
          );
        }

        final summary = snapshot.data!;
        final stats = [
          (
            label: 'Total Courses',
            value: '${summary.coursesCount}',
            icon: Icons.menu_book_rounded,
            color: AppColors.primary,
            bg: AppColors.primaryLight,
          ),
          (
            label: 'Total Students',
            value: '${summary.studentsCount}',
            icon: Icons.people_rounded,
            color: AppColors.cyan,
            bg: AppColors.cyanLight,
          ),
          (
            label: 'AI Pending',
            value: '${summary.pendingAiDrafts}',
            icon: Icons.auto_awesome_rounded,
            color: AppColors.amber,
            bg: AppColors.amberLight,
          ),
          (
            label: 'Avg. Score',
            value: '${summary.averageScore.toStringAsFixed(1)}%',
            icon: Icons.insights_rounded,
            color: AppColors.emerald,
            bg: AppColors.emeraldLight,
          ),
        ];

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcome(
                userName: user?.name ?? 'Instructor',
                pendingAiDrafts: summary.pendingAiDrafts,
              ),
              const SizedBox(height: 24),
              _buildStatsGrid(isWide, stats),
              const SizedBox(height: 28),
              _buildQuickActions(context, isWide),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Recent Activity',
                actionLabel: 'Refresh',
                onAction: () {
                  setState(() {
                    _summaryFuture = DashboardService.instance
                        .getInstructorSummary();
                  });
                },
              ),
              const SizedBox(height: 16),
              if (summary.recentActivity.isEmpty)
                const EmptyState(
                  icon: Icons.timeline_rounded,
                  title: 'No activity yet',
                  subtitle:
                      'Create a course, enroll students, or upload materials to start seeing instructor activity.',
                )
              else
                _buildActivityList(summary.recentActivity),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcome({
    required String userName,
    required int pendingAiDrafts,
  }) {
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
                  'You currently have $pendingAiDrafts pending AI drafts awaiting review.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
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
        icon: Icons.add_circle_rounded,
        label: 'Create Course',
        color: AppColors.primary,
        bg: AppColors.primaryLight,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateCoursePage()),
        ),
      ),
      (
        icon: Icons.quiz_rounded,
        label: 'Create Quiz',
        color: AppColors.violet,
        bg: AppColors.violetLight,
        onTap: () => _openCoursesTab(context),
      ),
      (
        icon: Icons.assignment_rounded,
        label: 'Create Assignment',
        color: AppColors.emerald,
        bg: AppColors.emeraldLight,
        onTap: () => _openCoursesTab(context),
      ),
      (
        icon: Icons.upload_file_rounded,
        label: 'Upload Material',
        color: AppColors.amber,
        bg: AppColors.amberLight,
        onTap: () => _openCoursesTab(context),
      ),
      (
        icon: Icons.campaign_rounded,
        label: 'Post Announcement',
        color: AppColors.rose,
        bg: AppColors.roseLight,
        onTap: () => _openCoursesTab(context),
      ),
      (
        icon: Icons.menu_book_rounded,
        label: 'Courses',
        color: AppColors.cyan,
        bg: AppColors.cyanLight,
        onTap: () => _openCoursesTab(context),
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
            crossAxisCount: isWide ? 3 : 2,
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

  void _openCoursesTab(BuildContext context) {
    final navigate = widget.onNavigateToTab;
    if (navigate != null) {
      navigate(1);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoursesPage()),
    );
  }

  Widget _buildActivityList(List<DashboardActivityItem> activity) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activity.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, index) {
          final item = activity[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            title: Text(item.title, style: AppTextStyles.label),
            subtitle: Text(item.subtitle, style: AppTextStyles.caption),
            trailing: Text(item.timestampLabel, style: AppTextStyles.caption),
          );
        },
      ),
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
            const Icon(Icons.cloud_off_rounded, size: 40),
            const SizedBox(height: 12),
            Text(
              'Failed to load instructor dashboard data.',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure your Supabase migration has been applied and your account has instructor access.',
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
