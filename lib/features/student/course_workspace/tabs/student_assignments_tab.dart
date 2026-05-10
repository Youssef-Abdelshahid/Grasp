import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../models/assignment_model.dart';
import '../../../../models/submission_model.dart';
import '../../../../models/user_settings_model.dart';
import '../../../../services/assignment_service.dart';
import '../../../../services/submission_service.dart';
import '../../../../services/user_settings_service.dart';
import '../../study/assignment_submission_page.dart';

class StudentAssignmentsTab extends StatefulWidget {
  const StudentAssignmentsTab({super.key, required this.courseId});

  final String courseId;

  @override
  State<StudentAssignmentsTab> createState() => _StudentAssignmentsTabState();
}

class _StudentAssignmentsTabState extends State<StudentAssignmentsTab> {
  late Future<_StudentAssignmentData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StudentAssignmentData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _StudentAssignmentData([], {});
        final assignments = data.assignments;
        final submitted = data.latestSubmissions.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assignments', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                '$submitted of ${assignments.length} submitted',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (assignments.isEmpty)
                const EmptyState(
                  icon: Icons.assignment_rounded,
                  title: 'No assignments available',
                  subtitle:
                      'Published assignments from your instructor will appear here once they are ready.',
                )
              else
                ...assignments.map(
                  (assignment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AssignmentCard(
                      assignment: assignment,
                      submission: data.latestSubmissions[assignment.id],
                      onOpen: () => _openAssignment(
                        assignment,
                        data.latestSubmissions[assignment.id],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<_StudentAssignmentData> _load() async {
    final assignments = await AssignmentService.instance.getCourseAssignments(
      widget.courseId,
    );
    final submissions = await SubmissionService.instance
        .getLatestAssignmentSubmissionsForCourse(widget.courseId);
    final settings = await UserSettingsService.instance
        .getCurrentSettingsOrNull();
    if (settings is StudentSettings && settings.showOverdueFirst) {
      assignments.sort(_compareAssignmentsWithOverdueFirst);
    }
    return _StudentAssignmentData(assignments, submissions);
  }

  Future<void> _openAssignment(
    AssignmentModel assignment,
    SubmissionModel? submission,
  ) async {
    final result = await Navigator.push<SubmissionModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentSubmissionPage(
          assignment: assignment,
          latestSubmission: submission,
        ),
      ),
    );

    if (result != null) {
      _refresh();
    }
  }

  void _refresh() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }
}

int _compareAssignmentsWithOverdueFirst(AssignmentModel a, AssignmentModel b) {
  final now = DateTime.now();
  final aOverdue = a.dueAt != null && a.dueAt!.isBefore(now);
  final bOverdue = b.dueAt != null && b.dueAt!.isBefore(now);
  if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
  final aDue = a.dueAt;
  final bDue = b.dueAt;
  if (aDue == null && bDue == null) return a.title.compareTo(b.title);
  if (aDue == null) return 1;
  if (bDue == null) return -1;
  return aDue.compareTo(bDue);
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.submission,
    required this.onOpen,
  });

  final AssignmentModel assignment;
  final SubmissionModel? submission;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isSubmitted = submission != null;
    final chipColor = isSubmitted ? AppColors.success : AppColors.amber;
    final chipBackground = isSubmitted
        ? AppColors.successLight
        : AppColors.amberLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: AppColors.emerald,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      assignment.dueAt == null
                          ? 'No deadline'
                          : 'Due: ${FileUtils.formatDate(assignment.dueAt!)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isSubmitted ? 'Submitted' : 'Pending',
                  style: AppTextStyles.caption.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          if (isSubmitted)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Latest attempt: ${FileUtils.formatDateTime(submission!.submittedAt)}',
                    style: AppTextStyles.caption,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('View / Resubmit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: const Text('Submit Assignment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentAssignmentData {
  const _StudentAssignmentData(this.assignments, this.latestSubmissions);

  final List<AssignmentModel> assignments;
  final Map<String, SubmissionModel> latestSubmissions;
}
