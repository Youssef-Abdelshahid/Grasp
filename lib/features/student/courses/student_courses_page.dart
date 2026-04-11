import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/course_model.dart';
import '../course_workspace/student_course_workspace_page.dart';

class StudentCoursesPage extends StatelessWidget {
  const StudentCoursesPage({super.key});

  static const _courses = [
    CourseModel(
      id: '1',
      title: 'Mobile Device Programming',
      code: 'CS401',
      studentsCount: 42,
      lecturesCount: 12,
      instructor: 'Dr. Ahmed Ali',
      description:
          'An in-depth course covering modern mobile development with Flutter, iOS, and Android development principles.',
    ),
    CourseModel(
      id: '2',
      title: 'Machine Learning Basics',
      code: 'CS310',
      studentsCount: 35,
      lecturesCount: 10,
      instructor: 'Dr. Sara Nour',
      description:
          'Foundations of machine learning algorithms, supervised and unsupervised learning, neural networks.',
    ),
    CourseModel(
      id: '3',
      title: 'Database Systems',
      code: 'CS302',
      studentsCount: 51,
      lecturesCount: 15,
      instructor: 'Dr. Khalid Omar',
      description:
          'Relational databases, SQL, normalization, transactions, and modern NoSQL approaches.',
    ),
    CourseModel(
      id: '4',
      title: 'Computer Networks',
      code: 'CS315',
      studentsCount: 28,
      lecturesCount: 8,
      instructor: 'Dr. Mona Hassan',
      description:
          'Network protocols, TCP/IP stack, routing algorithms, and network security fundamentals.',
    ),
    CourseModel(
      id: '5',
      title: 'Software Engineering',
      code: 'CS411',
      studentsCount: 39,
      lecturesCount: 14,
      instructor: 'Dr. Ahmed Ali',
      description:
          'Software development lifecycle, agile methodologies, design patterns, and project management.',
    ),
  ];

  static const _courseColors = [
    AppColors.primary,
    AppColors.cyan,
    AppColors.violet,
    AppColors.emerald,
    AppColors.amber,
  ];

  static const _progress = [0.72, 0.45, 0.60, 0.30, 0.88];

  static const _nextDeadlines = [
    'Quiz 2 · Apr 10',
    'Assignment 2 · Apr 12',
    'Midterm Quiz · Apr 15',
    'Lab Sheet 3 · Apr 18',
    'Final Project · May 15',
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
          _buildHeader(isWide),
          const SizedBox(height: 20),
          _buildList(context, isWide),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Courses', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text(
          '${_courses.length} enrolled courses this semester',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, bool isWide) {
    if (!isWide) {
      return Column(
        children: List.generate(_courses.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _StudentCourseCard(
              course: _courses[i],
              accentColor: _courseColors[i % _courseColors.length],
              progress: _progress[i % _progress.length],
              nextDeadline: _nextDeadlines[i % _nextDeadlines.length],
              onTap: () => _openWorkspace(context, i),
            ),
          );
        }),
      );
    }

    final cols = MediaQuery.of(context).size.width >= 1200 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 248,
      ),
      itemCount: _courses.length,
      itemBuilder: (context, i) {
        return _StudentCourseCard(
          course: _courses[i],
          accentColor: _courseColors[i % _courseColors.length],
          progress: _progress[i % _progress.length],
          nextDeadline: _nextDeadlines[i % _nextDeadlines.length],
          onTap: () => _openWorkspace(context, i),
        );
      },
    );
  }

  void _openWorkspace(BuildContext context, int i) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentCourseWorkspacePage(
          course: _courses[i],
          accentColor: _courseColors[i % _courseColors.length],
          progress: _progress[i % _progress.length],
        ),
      ),
    );
  }
}

class _StudentCourseCard extends StatelessWidget {
  final CourseModel course;
  final Color accentColor;
  final double progress;
  final String nextDeadline;
  final VoidCallback onTap;

  const _StudentCourseCard({
    required this.course,
    required this.accentColor,
    required this.progress,
    required this.nextDeadline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.code,
                          style: AppTextStyles.buttonSmall
                              .copyWith(color: accentColor),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '$percent%',
                          style: AppTextStyles.caption.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    course.title,
                    style: AppTextStyles.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.instructor,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.background,
                      color: accentColor,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 12, color: AppColors.amber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Next: $nextDeadline',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: onTap,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Open'),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded, size: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
