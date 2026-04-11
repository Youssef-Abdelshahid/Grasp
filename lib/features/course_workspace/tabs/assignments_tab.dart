import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../pages/assignment_builder_page.dart';

class AssignmentsTab extends StatelessWidget {
  const AssignmentsTab({super.key});

  static const _assignments = [
    (title: 'Assignment 1: Project Proposal', deadline: 'Mar 20, 2025', status: 'Closed', submissions: 38),
    (title: 'Assignment 2: Implementation Phase', deadline: 'Apr 10, 2025', status: 'Open', submissions: 12),
    (title: 'Assignment 3: Testing & Documentation', deadline: 'Apr 25, 2025', status: 'Draft', submissions: 0),
    (title: 'Final Project Submission', deadline: 'May 15, 2025', status: 'Draft', submissions: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActions(context),
          const SizedBox(height: 20),
          _buildAiBanner(context),
          const SizedBox(height: 20),
          _buildAssignmentList(),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isNarrow = constraints.maxWidth < 480;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assignments', style: AppTextStyles.h2),
            Text('${_assignments.length} assignments total',
                style: AppTextStyles.bodySmall),
          ],
        );

        final aiButton = OutlinedButton.icon(
          onPressed: () => _showAiSheet(context),
          icon: const Icon(Icons.auto_awesome_rounded, size: 14),
          label: const Text('AI Generate'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.emerald,
            side: const BorderSide(color: AppColors.emerald),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );

        final createButton = ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssignmentBuilderPage()),
          ),
          icon: const Icon(Icons.add_rounded, size: 14),
          label: const Text('Create'),
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: aiButton),
                  const SizedBox(width: 8),
                  Expanded(child: createButton),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleBlock),
            aiButton,
            const SizedBox(width: 8),
            createButton,
          ],
        );
      },
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emeraldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.emerald.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppColors.emerald, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assignment Generator',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.emerald),
                ),
                Text(
                  'Create rubric-based assignments and auto-generate marking criteria using AI',
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showAiSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Try it'),
          ),
        ],
      ),
    );
  }

  void _showAiSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AiAssignmentSheet(),
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
          final statusConfig = _statusConfig(a.status);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
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
                          a.title,
                          style: AppTextStyles.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Due: ${a.deadline}'
                          '${a.submissions > 0 ? ' · ${a.submissions} submitted' : ''}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusConfig.$2,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      a.status,
                      style: AppTextStyles.caption.copyWith(
                        color: statusConfig.$1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        size: 16, color: AppColors.textSecondary),
                    onPressed: () {},
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  (Color, Color) _statusConfig(String status) {
    switch (status) {
      case 'Open':
        return (AppColors.success, AppColors.successLight);
      case 'Closed':
        return (AppColors.textSecondary, AppColors.background);
      default:
        return (AppColors.warning, AppColors.warningLight);
    }
  }
}

class _AiAssignmentSheet extends StatelessWidget {
  const _AiAssignmentSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: AppColors.emeraldLight, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.emerald, size: 28),
          ),
          const SizedBox(height: 16),
          Text('AI Assignment Generator', style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Describe the assignment and AI will generate complete instructions and a grading rubric.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. A project on mobile app development with implementation and testing phases...',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Generate Assignment'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.white),
          )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          )),
        ]),
      ),
    );
  }
}
