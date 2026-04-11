import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../study/assignment_submission_page.dart';

class StudentAssignmentsTab extends StatelessWidget {
  const StudentAssignmentsTab({super.key});

  static const _assignments = [
    (
      title: 'Assignment 1: Project Proposal',
      deadline: 'Mar 20, 2025',
      status: 'Submitted',
      grade: '92/100',
    ),
    (
      title: 'Assignment 2: Implementation Phase',
      deadline: 'Apr 10, 2025',
      status: 'Pending',
      grade: '',
    ),
    (
      title: 'Assignment 3: Testing & Documentation',
      deadline: 'Apr 25, 2025',
      status: 'Not Started',
      grade: '',
    ),
    (
      title: 'Final Project Submission',
      deadline: 'May 15, 2025',
      status: 'Not Started',
      grade: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildAssignmentList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final submitted = _assignments.where((a) => a.status == 'Submitted').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assignments', style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text(
          '$submitted of ${_assignments.length} submitted',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAssignmentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Assignments', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        ...List.generate(_assignments.length, (i) {
          final a = _assignments[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AssignmentCard(
              title: a.title,
              deadline: a.deadline,
              status: a.status,
              grade: a.grade,
            ),
          );
        }),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final String title;
  final String deadline;
  final String status;
  final String grade;

  const _AssignmentCard({
    required this.title,
    required this.deadline,
    required this.status,
    required this.grade,
  });

  (Color, Color) _statusConfig() {
    switch (status) {
      case 'Submitted':
        return (AppColors.success, AppColors.successLight);
      case 'Pending':
        return (AppColors.amber, AppColors.amberLight);
      default:
        return (AppColors.textMuted, AppColors.background);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg) = _statusConfig();
    final isSubmitted = status == 'Submitted';
    final isPending = status == 'Pending';

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
                child: const Icon(Icons.assignment_rounded,
                    color: AppColors.emerald, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Due: $deadline',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (isSubmitted) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.emerald, Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.grade_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Grade: $grade',
                        style: AppTextStyles.buttonSmall
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Submission'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (isPending) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignmentSubmissionPage(
                      title: title,
                      deadline: deadline,
                    ),
                  ),
                ),
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: const Text('Submit Assignment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock_rounded, size: 16),
                label: const Text('Not Yet Available'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
