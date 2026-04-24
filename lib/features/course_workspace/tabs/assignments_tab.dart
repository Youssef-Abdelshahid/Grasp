import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/assignment_model.dart';
import '../../../services/assignment_service.dart';
import '../pages/assignment_builder_page.dart';

class AssignmentsTab extends StatefulWidget {
  const AssignmentsTab({
    super.key,
    required this.courseId,
  });

  final String courseId;

  @override
  State<AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<AssignmentsTab> {
  late Future<List<AssignmentModel>> _assignmentsFuture;

  @override
  void initState() {
    super.initState();
    _assignmentsFuture =
        AssignmentService.instance.getCourseAssignments(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssignmentModel>>(
      future: _assignmentsFuture,
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(assignments.length),
              const SizedBox(height: 20),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (assignments.isEmpty)
                const EmptyState(
                  icon: Icons.assignment_rounded,
                  title: 'No assignments yet',
                  subtitle:
                      'Create your first assignment to start the real academic workflow for this course.',
                )
              else
                ...assignments.map(
                  (assignment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AssignmentCard(
                      assignment: assignment,
                      onTap: () => _showAssignmentDetails(assignment),
                      onEdit: () => _openBuilder(assignment: assignment),
                      onTogglePublished: () => _togglePublished(assignment),
                      onDelete: () => _deleteAssignment(assignment),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int count) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isNarrow = constraints.maxWidth < 480;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assignments', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              '$count assignments in this course',
              style: AppTextStyles.bodySmall,
            ),
          ],
        );

        final createButton = ElevatedButton.icon(
          onPressed: () => _openBuilder(),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Create Assignment'),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: createButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleBlock),
            createButton,
          ],
        );
      },
    );
  }

  Future<void> _openBuilder({AssignmentModel? assignment}) async {
    final result = await Navigator.push<AssignmentModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentBuilderPage(
          courseId: widget.courseId,
          assignment: assignment,
        ),
      ),
    );
    if (result != null) {
      _refresh();
    }
  }

  Future<void> _togglePublished(AssignmentModel assignment) async {
    try {
      await AssignmentService.instance.setPublished(
        assignmentId: assignment.id,
        isPublished: !assignment.isPublished,
      );
      _refresh();
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteAssignment(AssignmentModel assignment) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Assignment'),
            content: Text('Delete "${assignment.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await AssignmentService.instance.deleteAssignment(assignment.id);
      _refresh();
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _showAssignmentDetails(AssignmentModel assignment) async {
    final details =
        await AssignmentService.instance.getAssignmentDetails(assignment.id);
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(details.title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailLine(
                  label: 'Status',
                  value: details.isPublished ? 'Published' : 'Draft',
                ),
                _DetailLine(
                  label: 'Due',
                  value: details.dueAt == null
                      ? 'No deadline'
                      : FileUtils.formatDate(details.dueAt!.toLocal()),
                ),
                _DetailLine(
                  label: 'Points',
                  value: '${details.maxPoints}',
                ),
                _DetailLine(
                  label: 'Rubric Rows',
                  value: '${details.rubricCount}',
                ),
                if (details.instructions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Instructions', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(details.instructions, style: AppTextStyles.bodySmall),
                ],
                if (details.attachmentRequirements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Attachment Requirements', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(
                    details.attachmentRequirements,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openBuilder(assignment: details);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _refresh() {
    setState(() {
      _assignmentsFuture =
          AssignmentService.instance.getCourseAssignments(widget.courseId);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.onTap,
    required this.onEdit,
    required this.onTogglePublished,
    required this.onDelete,
  });

  final AssignmentModel assignment;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final chipColor =
        assignment.isPublished ? AppColors.success : AppColors.warning;
    final chipBackground = assignment.isPublished
        ? AppColors.successLight
        : AppColors.warningLight;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: AppColors.emerald,
                  size: 20,
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          assignment.dueAt == null
                              ? 'No deadline'
                              : 'Due ${FileUtils.formatDate(assignment.dueAt!.toLocal())}',
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          '${assignment.maxPoints} pts',
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          '${assignment.rubricCount} rubric rows',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  assignment.isPublished ? 'Published' : 'Draft',
                  style: AppTextStyles.caption.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'toggle':
                      onTogglePublished();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      assignment.isPublished ? 'Unpublish' : 'Publish',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
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

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.label.copyWith(fontSize: 13),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
