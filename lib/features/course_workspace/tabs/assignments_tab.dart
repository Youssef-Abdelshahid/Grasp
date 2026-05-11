import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/assignment_model.dart';
import '../../../models/material_model.dart';
import '../../../models/user_settings_model.dart';
import '../../../services/assignment_service.dart';
import '../../../services/gemini_ai_service.dart';
import '../../../services/material_service.dart';
import '../../../services/user_settings_service.dart';
import '../../activity/activity_sheets.dart';
import '../../ai_controls/providers/ai_controls_provider.dart';
import '../../permissions/providers/permissions_provider.dart';
import '../pages/assignment_builder_page.dart';

class AssignmentsTab extends ConsumerStatefulWidget {
  const AssignmentsTab({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends ConsumerState<AssignmentsTab> {
  late Future<List<AssignmentModel>> _assignmentsFuture;

  @override
  void initState() {
    super.initState();
    _assignmentsFuture = AssignmentService.instance.getCourseAssignments(
      widget.courseId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssignmentModel>>(
      future: _assignmentsFuture,
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];
        final permissions = ref.watch(permissionsProvider).valueOrDefaults;
        final aiControls = ref.watch(aiControlsProvider).valueOrDefaults;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                assignments.length,
                canManage: permissions.manageAssignments,
                canUseAi: permissions.useAiAssignmentGeneration &&
                    aiControls.canInstructorGenerateAssignment,
              ),
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
                      onEdit: permissions.manageAssignments
                          ? () => _openBuilder(assignment: assignment)
                          : null,
                      onTogglePublished: permissions.manageAssignments
                          ? () => _togglePublished(assignment)
                          : null,
                      onDelete: permissions.manageAssignments
                          ? () => _deleteAssignment(assignment)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    int count, {
    required bool canManage,
    required bool canUseAi,
  }) {
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
          onPressed: canManage ? () => _openBuilder() : null,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Create Assignment'),
        );
        final generateButton = OutlinedButton.icon(
          onPressed: canUseAi && canManage ? _generateAssignment : null,
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Generate Assignment'),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              if (canUseAi && canManage) ...[
                SizedBox(width: double.infinity, child: generateButton),
                const SizedBox(height: 8),
              ],
              if (canManage)
                SizedBox(width: double.infinity, child: createButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleBlock),
            if (canUseAi && canManage) ...[
              generateButton,
              const SizedBox(width: 8),
            ],
            if (canManage) createButton,
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

  Future<void> _generateAssignment() async {
    try {
      final materials = await MaterialService.instance.getCourseMaterials(
        widget.courseId,
      );
      final settings = await UserSettingsService.instance
          .getCurrentSettingsOrNull();
      if (!mounted) return;
      final draft = await showDialog<AiAssignmentDraft>(
        context: context,
        builder: (_) => _GenerateAssignmentDialog(
          courseId: widget.courseId,
          materials: materials,
          defaults: settings is InstructorSettings ? settings : null,
        ),
      );
      if (draft == null || !mounted) return;
      final result = await Navigator.push<AssignmentModel>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AssignmentBuilderPage(courseId: widget.courseId, aiDraft: draft),
        ),
      );
      if (result != null) _refresh();
    } catch (error) {
      _showMessage(error.toString());
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
    final confirmed =
        await showDialog<bool>(
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
    final permissions = ref.read(permissionsProvider).valueOrDefaults;
    final details = await AssignmentService.instance.getAssignmentDetails(
      assignment.id,
    );
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
                _DetailLine(label: 'Points', value: '${details.maxPoints}'),
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
                if (permissions.viewStudentActivity)
                  AssessmentActivityPanel(
                    assessmentId: details.id,
                    isQuiz: false,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (permissions.manageAssignments)
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
      _assignmentsFuture = AssignmentService.instance.getCourseAssignments(
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
  final VoidCallback? onEdit;
  final VoidCallback? onTogglePublished;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final chipColor = assignment.isPublished
        ? AppColors.success
        : AppColors.warning;
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      onEdit?.call();
                      break;
                    case 'toggle':
                      onTogglePublished?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onTogglePublished != null)
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        assignment.isPublished
                            ? 'Unpublish'
                            : 'Accept & Publish',
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        assignment.isPublished ? 'Delete' : 'Reject Draft',
                      ),
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
  const _DetailLine({required this.label, required this.value});

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

class _GenerateAssignmentDialog extends StatefulWidget {
  const _GenerateAssignmentDialog({
    required this.courseId,
    required this.materials,
    this.defaults,
  });

  final String courseId;
  final List<MaterialModel> materials;
  final InstructorSettings? defaults;

  @override
  State<_GenerateAssignmentDialog> createState() =>
      _GenerateAssignmentDialogState();
}

class _GenerateAssignmentDialogState extends State<_GenerateAssignmentDialog> {
  final _promptCtrl = TextEditingController();
  final _tasksCtrl = TextEditingController(text: '3');
  final _marksCtrl = TextEditingController(text: '100');
  final _selectedMaterialIds = <String>{};
  String _difficulty = 'medium';
  DateTime? _deadline;
  bool _allMaterials = true;
  bool _includeRubric = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final defaults = widget.defaults;
    if (defaults == null) return;
    _difficulty = defaults.defaultAssignmentDifficulty;
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _tasksCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Assignment Draft'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _promptCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Optional Prompt',
                  hintText: 'Focus area or deliverable expectations',
                ),
              ),
              const SizedBox(height: 12),
              _materialSelector(),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _difficulty,
                decoration: const InputDecoration(labelText: 'Difficulty'),
                items: const ['easy', 'medium', 'hard']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: _loading
                    ? null
                    : (value) =>
                          setState(() => _difficulty = value ?? 'medium'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tasksCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tasks'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _marksCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Marks'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include rubric'),
                value: _includeRubric,
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _includeRubric = value),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _deadline == null
                          ? 'No deadline'
                          : FileUtils.formatDateTime(_deadline!),
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _pickDeadline,
                    child: const Text('Deadline'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _generate,
          child: Text(_loading ? 'Generating...' : 'Generate Draft'),
        ),
      ],
    );
  }

  Widget _materialSelector() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Use all course materials'),
          value: _allMaterials,
          onChanged: _loading
              ? null
              : (value) => setState(() => _allMaterials = value),
        ),
        if (!_allMaterials)
          ...widget.materials.map(
            (material) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(material.title, overflow: TextOverflow.ellipsis),
              value: _selectedMaterialIds.contains(material.id),
              onChanged: _loading
                  ? null
                  : (value) => setState(() {
                      if (value ?? false) {
                        _selectedMaterialIds.add(material.id);
                      } else {
                        _selectedMaterialIds.remove(material.id);
                      }
                    }),
            ),
          ),
      ],
    );
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (time == null) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _generate() async {
    final selected = _allMaterials
        ? widget.materials
        : widget.materials
              .where((material) => _selectedMaterialIds.contains(material.id))
              .toList();
    setState(() => _loading = true);
    try {
      final draft = await GeminiAiService.instance.generateAssignmentDraft(
        courseId: widget.courseId,
        materials: selected,
        prompt: _promptCtrl.text,
        difficulty: _difficulty,
        taskCount: int.tryParse(_tasksCtrl.text) ?? 3,
        marks: int.tryParse(_marksCtrl.text) ?? 100,
        includeRubric: _includeRubric,
        deadline: _deadline,
      );
      if (!mounted) return;
      Navigator.pop(context, draft);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
