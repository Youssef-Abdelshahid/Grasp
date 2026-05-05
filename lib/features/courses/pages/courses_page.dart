import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/course_model.dart';
import '../../../services/course_service.dart';
import '../../course_workspace/pages/course_workspace_page.dart';
import '../providers/course_providers.dart';
import 'create_course_page.dart';

class CoursesPage extends ConsumerStatefulWidget {
  const CoursesPage({super.key});

  @override
  ConsumerState<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends ConsumerState<CoursesPage> {
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

    return ref
        .watch(instructorCoursesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(onRetry: _refresh),
          data: (courses) {
            return SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isWide, courses.length),
                  const SizedBox(height: 20),
                  if (courses.isEmpty)
                    EmptyState(
                      icon: Icons.menu_book_rounded,
                      title: 'No courses yet',
                      subtitle:
                          'Create your first course to start adding materials, announcements, and student enrollments.',
                      actionLabel: 'Create Course',
                      onAction: () => _openCreate(context),
                    )
                  else
                    _buildList(context, isWide, courses),
                ],
              ),
            );
          },
        );
  }

  Widget _buildHeader(BuildContext context, bool isWide, int count) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Courses', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text(
                '$count active courses in your workspace',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        isWide
            ? ElevatedButton.icon(
                onPressed: () => _openCreate(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Course'),
              )
            : ElevatedButton(
                onPressed: () => _openCreate(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('+ Create'),
              ),
      ],
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
            child: _CourseCard(
              course: courses[index],
              accentColor: _courseColors[index % _courseColors.length],
              onOpen: () => _openWorkspace(context, courses[index], index),
              onEdit: () => _openEdit(context, courses[index]),
              onArchive: () => _archiveCourse(courses[index]),
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
        mainAxisExtent: 250,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _CourseCard(
          course: courses[index],
          accentColor: _courseColors[index % _courseColors.length],
          onOpen: () => _openWorkspace(context, courses[index], index),
          onEdit: () => _openEdit(context, courses[index]),
          onArchive: () => _archiveCourse(courses[index]),
        );
      },
    );
  }

  Future<void> _openWorkspace(
    BuildContext context,
    CourseModel course,
    int index,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseWorkspacePage(
          courseId: course.id,
          initialCourse: course,
          accentColor: _courseColors[index % _courseColors.length],
        ),
      ),
    );
    _refresh();
  }

  Future<void> _openCreate(BuildContext context) async {
    final created = await Navigator.push<CourseModel>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCoursePage()),
    );
    if (created != null) {
      _refresh();
    }
  }

  Future<void> _openEdit(BuildContext context, CourseModel course) async {
    final updated = await Navigator.push<CourseModel>(
      context,
      MaterialPageRoute(builder: (_) => CreateCoursePage(course: course)),
    );
    if (updated != null) {
      _refresh();
    }
  }

  Future<void> _archiveCourse(CourseModel course) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Archive Course'),
            content: Text(
              'Archive "${course.title}"? Students will no longer see it in active course lists.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Archive'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await CourseService.instance.archiveCourse(course.id);
      _refresh();
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    }
  }

  void _refresh() {
    ref.invalidate(instructorCoursesProvider);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.accentColor,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
  });

  final CourseModel course;
  final Color accentColor;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.code,
                          style: AppTextStyles.buttonSmall.copyWith(
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: course.isVisible
                              ? AppColors.emeraldLight
                              : AppColors.amberLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.isVisible ? 'Published' : 'Draft',
                          style: AppTextStyles.caption.copyWith(
                            color: course.isVisible
                                ? AppColors.emerald
                                : AppColors.amber,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'open':
                              onOpen();
                              break;
                            case 'edit':
                              onEdit();
                              break;
                            case 'archive':
                              onArchive();
                              break;
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'open', child: Text('Open')),
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'archive',
                            child: Text('Archive'),
                          ),
                        ],
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
                  const SizedBox(height: 6),
                  Text(
                    course.description.isEmpty
                        ? 'No course description yet.'
                        : course.description,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    course.semester.isEmpty
                        ? 'Semester not set'
                        : course.semester,
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
                              label: '${course.lecturesCount} materials',
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: onOpen,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
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
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to load courses',
        subtitle: 'Please check your database migration and try again.',
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
    );
  }
}
