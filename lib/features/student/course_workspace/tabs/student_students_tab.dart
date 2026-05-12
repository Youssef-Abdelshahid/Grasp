import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_utils.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../models/basic_profile_model.dart';
import '../../../../services/course_people_service.dart';

class StudentStudentsTab extends StatefulWidget {
  const StudentStudentsTab({super.key, required this.courseId});

  final String courseId;

  @override
  State<StudentStudentsTab> createState() => _StudentStudentsTabState();
}

class _StudentStudentsTabState extends State<StudentStudentsTab> {
  final _searchController = TextEditingController();
  late Future<List<BasicProfileModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = CoursePeopleService.instance.listCourseStudents(widget.courseId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BasicProfileModel>>(
      future: _future,
      builder: (context, snapshot) {
        final students = _filter(snapshot.data ?? const []);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Students', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                '${students.length} classmates',
                style: AppTextStyles.bodySmall,
              ),
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
              else if (snapshot.hasError)
                EmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Students unavailable',
                  subtitle: snapshot.error.toString(),
                )
              else if (students.isEmpty)
                const EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No classmates found',
                  subtitle: 'Enrolled students will appear here.',
                )
              else
                _StudentList(students: students),
            ],
          ),
        );
      },
    );
  }

  List<BasicProfileModel> _filter(List<BasicProfileModel> students) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return students;
    }
    return students
        .where(
          (student) =>
              student.name.toLowerCase().contains(query) ||
              student.email.toLowerCase().contains(query),
        )
        .toList();
  }
}

class _StudentList extends StatelessWidget {
  const _StudentList({required this.students});

  final List<BasicProfileModel> students;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: students
          .map(
            (student) => Padding(
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
                      avatarUrl: student.avatarUrl,
                      initials: UserUtils.initials(student.name),
                      backgroundColor: AppColors.cyan.withValues(alpha: 0.12),
                      textColor: AppColors.cyan,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: AppTextStyles.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            student.email,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
