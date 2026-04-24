import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/user_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/enrollment_model.dart';
import '../../../services/enrollment_service.dart';

class StudentsTab extends StatefulWidget {
  const StudentsTab({
    super.key,
    required this.courseId,
  });

  final String courseId;

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  late Future<List<EnrollmentModel>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture =
        EnrollmentService.instance.getCourseEnrollments(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EnrollmentModel>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(students.length),
              const SizedBox(height: 20),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (students.isEmpty)
                EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No students enrolled',
                  subtitle:
                      'Add students by email to start building the course roster.',
                  actionLabel: 'Enroll Student',
                  onAction: _showEnrollDialog,
                )
              else
                _buildStudentList(students),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int count) {
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
        OutlinedButton.icon(
          onPressed: _showEnrollDialog,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
          label: const Text('Enroll'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList(List<EnrollmentModel> students) {
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    UserUtils.initials(student.studentName),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
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
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _unenroll(student),
                  icon: const Icon(Icons.person_remove_alt_1_rounded, size: 14),
                  label: const Text('Remove'),
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
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _unenroll(EnrollmentModel student) async {
    await EnrollmentService.instance.unenrollStudent(
      courseId: widget.courseId,
      studentId: student.studentId,
    );
    _refresh();
  }

  void _refresh() {
    setState(() {
      _studentsFuture =
          EnrollmentService.instance.getCourseEnrollments(widget.courseId);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
