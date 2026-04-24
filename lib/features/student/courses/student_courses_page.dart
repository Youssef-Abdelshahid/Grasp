import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/course_model.dart';
import '../../../services/course_service.dart';
import '../course_workspace/student_course_workspace_page.dart';

class StudentCoursesPage extends StatefulWidget {
  const StudentCoursesPage({super.key});

  @override
  State<StudentCoursesPage> createState() => _StudentCoursesPageState();
}

class _StudentCoursesPageState extends State<StudentCoursesPage> {
  late Future<List<CourseModel>> _coursesFuture;

  static const _courseColors = [
    AppColors.primary,
    AppColors.cyan,
    AppColors.violet,
    AppColors.emerald,
    AppColors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _coursesFuture = CourseService.instance.getStudentCourses();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;
    final padding = EdgeInsets.all(isWide ? 28 : 16);

    return FutureBuilder<List<CourseModel>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final courses = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Courses', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text(
                    '${courses.length} enrolled courses this semester',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (courses.isEmpty)
                const EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: 'No enrolled courses',
                  subtitle:
                      'Once an instructor enrolls you in a course, it will appear here.',
                )
              else
                _buildList(context, isWide, courses),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    bool isWide,
    List<CourseModel> courses,
  ) {
    if (!isWide) {
      return Column(
        children: List.generate(courses.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _StudentCourseCard(
              course: courses[index],
              accentColor: _courseColors[index % _courseColors.length],
              onTap: () => _openWorkspace(context, courses[index], index),
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
        mainAxisExtent: 220,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _StudentCourseCard(
          course: courses[index],
          accentColor: _courseColors[index % _courseColors.length],
          onTap: () => _openWorkspace(context, courses[index], index),
        );
      },
    );
  }

  void _openWorkspace(BuildContext context, CourseModel course, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentCourseWorkspacePage(
          courseId: course.id,
          initialCourse: course,
          accentColor: _courseColors[index % _courseColors.length],
        ),
      ),
    );
  }
}

class _StudentCourseCard extends StatelessWidget {
  const _StudentCourseCard({
    required this.course,
    required this.accentColor,
    required this.onTap,
  });

  final CourseModel course;
  final Color accentColor;
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
                  const SizedBox(height: 10),
                  Text(
                    course.semester.isEmpty ? 'Semester not set' : course.semester,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.book_rounded, size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '${course.lecturesCount} materials',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.people_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${course.studentsCount} students',
                        style: AppTextStyles.caption,
                      ),
                      const Spacer(),
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
