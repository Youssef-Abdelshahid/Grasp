import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/course_model.dart';
import '../../course_workspace/pages/course_workspace_page.dart';
import 'create_course_page.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

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
      instructor: 'Dr. Ahmed Ali',
      description:
          'Foundations of machine learning algorithms, supervised and unsupervised learning, neural networks.',
    ),
    CourseModel(
      id: '3',
      title: 'Database Systems',
      code: 'CS302',
      studentsCount: 51,
      lecturesCount: 15,
      instructor: 'Dr. Ahmed Ali',
      description:
          'Relational databases, SQL, normalization, transactions, and modern NoSQL approaches.',
    ),
    CourseModel(
      id: '4',
      title: 'Computer Networks',
      code: 'CS315',
      studentsCount: 28,
      lecturesCount: 8,
      instructor: 'Dr. Ahmed Ali',
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
    CourseModel(
      id: '6',
      title: 'Operating Systems',
      code: 'CS308',
      studentsCount: 44,
      lecturesCount: 11,
      instructor: 'Dr. Ahmed Ali',
      description:
          'Process management, memory management, file systems, and concurrency in modern operating systems.',
    ),
  ];

  static const _courseColors = [
    AppColors.primary,
    AppColors.cyan,
    AppColors.violet,
    AppColors.emerald,
    AppColors.amber,
    AppColors.rose,
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
          _buildHeader(context, isWide),
          const SizedBox(height: 20),
          _buildList(context, isWide),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isWide) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Courses', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text(
                '${_courses.length} active courses this semester',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        isWide
            ? ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Course'),
              )
            : ElevatedButton(
                onPressed: () => _showCreateDialog(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('+ Create'),
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
            child: _CourseCard(
              course: _courses[i],
              accentColor: _courseColors[i % _courseColors.length],
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
        mainAxisExtent: 230,
      ),
      itemCount: _courses.length,
      itemBuilder: (context, i) {
        return _CourseCard(
          course: _courses[i],
          accentColor: _courseColors[i % _courseColors.length],
          onTap: () => _openWorkspace(context, i),
        );
      },
    );
  }

  void _openWorkspace(BuildContext context, int i) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseWorkspacePage(
          course: _courses[i],
          accentColor: _courseColors[i % _courseColors.length],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCoursePage()),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final Color accentColor;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.accentColor,
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
                      Icon(Icons.more_horiz_rounded,
                          color: AppColors.textMuted, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    course.title,
                    style: AppTextStyles.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.description,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _InfoChip(
                              icon: Icons.people_rounded,
                              label: '${course.studentsCount} students',
                              color: accentColor,
                            ),
                            _InfoChip(
                              icon: Icons.book_rounded,
                              label: '${course.lecturesCount} lectures',
                              color: AppColors.textSecondary,
                            ),
                          ],
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.caption,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
