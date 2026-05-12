import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/user_utils.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../features/activity/activity_sheets.dart';
import '../../../features/permissions/providers/permissions_provider.dart';
import '../../../models/activity_models.dart';
import '../../../services/activity_service.dart';
import '../../../services/enrollment_service.dart';
import '../../../services/permissions_service.dart';

class StudentsTab extends ConsumerStatefulWidget {
  const StudentsTab({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends ConsumerState<StudentsTab> {
  final _searchController = TextEditingController();
  late Future<List<CourseStudentActivity>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = ActivityService.instance.getCourseStudentsActivity(
      widget.courseId,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CourseStudentActivity>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        final students = _filter(snapshot.data ?? const []);
        final canManageStudents = ref
            .watch(permissionsProvider)
            .valueOrDefaults
            .manageCourseStudents;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(students.length, canManageStudents),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search students...',
                ),
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (students.isEmpty)
                EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No students enrolled',
                  subtitle: canManageStudents
                      ? 'Add students by email to start building the course roster.'
                      : 'Student enrollment changes are currently disabled for instructors.',
                  actionLabel: canManageStudents ? 'Enroll Student' : null,
                  onAction: canManageStudents ? _showEnrollDialog : null,
                )
              else
                _buildStudentList(students, canManageStudents),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int count, bool canManageStudents) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Students', style: AppTextStyles.h2),
              Text('$count enrolled students', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        if (canManageStudents)
          OutlinedButton.icon(
            onPressed: _showEnrollDialog,
            icon: Icon(Icons.person_add_alt_1_rounded, size: 14),
            label: const Text('Enroll'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  List<CourseStudentActivity> _filter(List<CourseStudentActivity> students) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return students;
    return students
        .where(
          (student) =>
              student.studentName.toLowerCase().contains(query) ||
              student.studentEmail.toLowerCase().contains(query),
        )
        .toList();
  }

  Widget _buildStudentList(
    List<CourseStudentActivity> students,
    bool canManageStudents,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(students.length, (index) {
        final student = students[index];
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
                AppAvatar(
                  radius: 20,
                  avatarUrl: student.studentAvatarUrl,
                  initials: UserUtils.initials(student.studentName),
                  backgroundColor: AppColors.primaryLight,
                  textColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: AppTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        student.studentEmail,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Quizzes ${student.quizzesCompleted}/${student.totalQuizzes}',
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            'Assignments ${student.assignmentsSubmitted}/${student.totalAssignments}',
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            'Latest: ${student.latestLabel}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (student.overdueCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${student.overdueCount} overdue',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'View activity',
                      icon: Icon(
                        Icons.analytics_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => showStudentActivitySheet(
                        context: context,
                        courseId: widget.courseId,
                        studentId: student.studentId,
                      ),
                    ),
                    if (canManageStudents)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'remove') _unenroll(student);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove'),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _showEnrollDialog() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enroll Student'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Student Email',
            hintText: 'student@university.edu',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enroll'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (email == null || email.isEmpty) {
      return;
    }

    try {
      await EnrollmentService.instance.enrollStudent(
        courseId: widget.courseId,
        studentEmail: email,
      );
      _refresh();
    } on EnrollmentException catch (error) {
      _showMessage(error.message);
    } on PermissionsException catch (error) {
      _showMessage(error.message);
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _unenroll(CourseStudentActivity student) async {
    try {
      await EnrollmentService.instance.unenrollStudent(
        courseId: widget.courseId,
        studentId: student.studentId,
      );
      _refresh();
    } on EnrollmentException catch (error) {
      _showMessage(error.message);
    } on PermissionsException catch (error) {
      _showMessage(error.message);
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    }
  }

  void _refresh() {
    setState(() {
      _studentsFuture = ActivityService.instance.getCourseStudentsActivity(
        widget.courseId,
      );
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
