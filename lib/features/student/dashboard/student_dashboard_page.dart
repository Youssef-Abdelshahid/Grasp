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
import '../courses/student_courses_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  late Future<StudentDashboardSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = DashboardService.instance.getStudentSummary();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;
    final user = AuthService.instance.currentUser;

    return FutureBuilder<StudentDashboardSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _DashboardErrorState(
            onRetry: () {
              setState(() {
                _summaryFuture = DashboardService.instance.getStudentSummary();
              });
            },
          );
        }

        final summary = snapshot.data!;
        final stats = [
          (
            label: 'Enrolled Courses',
            value: '${summary.enrolledCourses}',
            icon: Icons.menu_book_rounded,
            color: AppColors.primary,
            bg: AppColors.primaryLight,
          ),
          (
            label: 'Pending Tasks',
            value: '${summary.pendingTasks}',
            icon: Icons.assignment_late_rounded,
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
          (
            label: 'Completed',
            value: '${summary.completedSubmissions}',
            icon: Icons.check_circle_rounded,
            color: AppColors.cyan,
            bg: AppColors.cyanLight,
          ),
        ];

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcome(
                userName: user?.name ?? 'Student',
                pendingTasks: summary.pendingTasks,
                onContinue: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentCoursesPage()),
                ),
              ),
              const SizedBox(height: 24),
              _buildStatsGrid(isWide, stats),
              const SizedBox(height: 28),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildDeadlines(summary.upcomingDeadlines),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildAnnouncements(summary.recentAnnouncements),
                    ),
                  ],
                )
              else ...[
                _buildDeadlines(summary.upcomingDeadlines),
                const SizedBox(height: 28),
                _buildAnnouncements(summary.recentAnnouncements),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcome({
    required String userName,
    required int pendingTasks,
    required VoidCallback onContinue,
  }) {
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
                  'You currently have $pendingTasks pending tasks across your courses.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Continue Studying'),
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
            child: const Icon(Icons.auto_stories_rounded,
                color: Colors.white, size: 30),
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

  Widget _buildDeadlines(List<StudentDeadlineItem> deadlines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Upcoming Deadlines'),
        const SizedBox(height: 12),
        if (deadlines.isEmpty)
          const EmptyState(
            icon: Icons.assignment_turned_in_rounded,
            title: 'No upcoming deadlines',
            subtitle: 'You are currently caught up on assignments and quizzes.',
          )
        else
          ...deadlines.map((deadline) {
            final isQuiz = deadline.type == 'Quiz';
            final color = isQuiz ? AppColors.violet : AppColors.emerald;
            final bg = isQuiz ? AppColors.violetLight : AppColors.emeraldLight;

            return Padding(
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
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isQuiz ? Icons.quiz_rounded : Icons.assignment_rounded,
                        color: color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(deadline.title, style: AppTextStyles.label),
                          const SizedBox(height: 2),
                          Text(deadline.course, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(deadline.type, style: AppTextStyles.caption),
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${deadline.dueLabel}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAnnouncements(List<StudentAnnouncementItem> announcements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Announcements',
          actionLabel: 'Refresh',
          onAction: () {
            setState(() {
              _summaryFuture = DashboardService.instance.getStudentSummary();
            });
          },
        ),
        const SizedBox(height: 12),
        if (announcements.isEmpty)
          const EmptyState(
            icon: Icons.campaign_rounded,
            title: 'No announcements yet',
            subtitle: 'Announcements from your enrolled courses will show up here.',
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
              itemCount: announcements.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, index) {
                final item = announcements[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.isPinned
                          ? AppColors.amberLight
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.campaign_rounded,
                      color: item.isPinned ? AppColors.amber : AppColors.primary,
                      size: 16,
                    ),
                  ),
                  title: Text(item.title, style: AppTextStyles.label),
                  subtitle: Text(
                    '${item.course} - ${item.timeLabel}',
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

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.onRetry,
  });

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
              'Failed to load student dashboard data.',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure your Supabase migration has been applied and your student account is enrolled in at least one course.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
