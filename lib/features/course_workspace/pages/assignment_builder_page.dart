import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../models/assignment_model.dart';
import '../../../models/assignment_rubric_item_model.dart';
import '../../../services/assignment_service.dart';

class AssignmentBuilderPage extends StatefulWidget {
  const AssignmentBuilderPage({
    super.key,
    required this.courseId,
    this.assignment,
  });

  final String courseId;
  final AssignmentModel? assignment;

  @override
  State<AssignmentBuilderPage> createState() => _AssignmentBuilderPageState();
}

class _AssignmentBuilderPageState extends State<AssignmentBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _attachmentRequirementsCtrl = TextEditingController();
  final _marksCtrl = TextEditingController(text: '100');

  late final List<_RubricDraft> _rubric;
  DateTime? _dueAt;
  bool _isSaving = false;

  bool get _isEditing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final assignment = widget.assignment;
    _rubric = assignment == null
        ? [_RubricDraft()]
        : assignment.rubric
            .map(AssignmentRubricItemModel.fromJson)
            .map(_RubricDraft.fromModel)
            .toList();

    if (_rubric.isEmpty) {
      _rubric.add(_RubricDraft());
    }

    if (assignment != null) {
      _titleCtrl.text = assignment.title;
      _instructionsCtrl.text = assignment.instructions;
      _attachmentRequirementsCtrl.text = assignment.attachmentRequirements;
      _marksCtrl.text = assignment.maxPoints.toString();
      _dueAt = assignment.dueAt?.toLocal();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    _attachmentRequirementsCtrl.dispose();
    _marksCtrl.dispose();
    for (final row in _rubric) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Assignment' : 'Create Assignment',
          style: AppTextStyles.h3,
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(false),
            child: const Text('Save Draft'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _save(true),
              child: Text(_isEditing ? 'Update & Publish' : 'Publish'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 20),
              _buildDetailsCard(),
              const SizedBox(height: 20),
              _buildRubricCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emeraldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_rounded, color: AppColors.emerald),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manual assignment setup', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  'This stores assignment details, rubric structure, and publish state for the next submission phase.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assignment Details', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          _label('Assignment Title *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Assignment 2: Implementation Phase',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          _label('Instructions'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _instructionsCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Detailed instructions for students...',
            ),
          ),
          const SizedBox(height: 16),
          _label('Attachment Requirements'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _attachmentRequirementsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Optional notes about files, format, or upload expectations',
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final dateField = _DateField(
                label: 'Deadline',
                value: _dueAt == null ? 'No deadline' : FileUtils.formatDate(_dueAt!),
                onTap: _pickDueDate,
                onClear: _dueAt == null
                    ? null
                    : () => setState(() {
                          _dueAt = null;
                        }),
              );
              final marksField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Total Marks *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _marksCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '100'),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter valid marks';
                      }
                      return null;
                    },
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    dateField,
                    const SizedBox(height: 16),
                    marksField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dateField),
                  const SizedBox(width: 16),
                  Expanded(child: marksField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRubricCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Text('Grading Rubric', style: AppTextStyles.h3),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${_rubric.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rubric rows are stored as structured JSON so later grading and submissions can build on this cleanly.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _rubric.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RubricRowCard(
                number: index + 1,
                draft: _rubric[index],
                canDelete: _rubric.length > 1,
                onDelete: () => _removeRubric(index),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _addRubric,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Criterion'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (selected == null) {
      return;
    }

    setState(() {
      _dueAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        23,
        59,
      );
    });
  }

  void _addRubric() {
    setState(() => _rubric.add(_RubricDraft()));
  }

  void _removeRubric(int index) {
    final item = _rubric.removeAt(index);
    item.dispose();
    setState(() {});
  }

  Future<void> _save(bool publish) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final validationError = _validateRubric();
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final rubric = _rubric.map((item) => item.toModel().toJson()).toList();
      final assignment = _isEditing
          ? await AssignmentService.instance.updateAssignment(
              assignmentId: widget.assignment!.id,
              title: _titleCtrl.text,
              instructions: _instructionsCtrl.text,
              attachmentRequirements: _attachmentRequirementsCtrl.text,
              dueAt: _dueAt,
              maxPoints: int.parse(_marksCtrl.text.trim()),
              isPublished: publish,
              rubric: rubric,
            )
          : await AssignmentService.instance.createAssignment(
              courseId: widget.courseId,
              title: _titleCtrl.text,
              instructions: _instructionsCtrl.text,
              attachmentRequirements: _attachmentRequirementsCtrl.text,
              dueAt: _dueAt,
              maxPoints: int.parse(_marksCtrl.text.trim()),
              isPublished: publish,
              rubric: rubric,
            );

      if (!mounted) {
        return;
      }
      Navigator.pop(context, assignment);
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validateRubric() {
    if (_rubric.isEmpty) {
      return 'Add at least one rubric criterion before saving.';
    }

    for (var index = 0; index < _rubric.length; index++) {
      final item = _rubric[index];
      if (item.criterionCtrl.text.trim().isEmpty) {
        return 'Rubric criterion ${index + 1} needs a title.';
      }
      if (item.marks <= 0) {
        return 'Rubric criterion ${index + 1} needs valid marks.';
      }
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.label);
}

class _RubricDraft {
  _RubricDraft()
      : criterionCtrl = TextEditingController(),
        descriptionCtrl = TextEditingController(),
        marksCtrl = TextEditingController(text: '10');

  _RubricDraft.fromModel(AssignmentRubricItemModel model)
      : criterionCtrl = TextEditingController(text: model.criterion),
        descriptionCtrl = TextEditingController(text: model.description),
        marksCtrl = TextEditingController(text: model.marks.toString());

  final TextEditingController criterionCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController marksCtrl;

  int get marks => int.tryParse(marksCtrl.text.trim()) ?? 0;

  AssignmentRubricItemModel toModel() {
    return AssignmentRubricItemModel(
      criterion: criterionCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      marks: marks,
    );
  }

  void dispose() {
    criterionCtrl.dispose();
    descriptionCtrl.dispose();
    marksCtrl.dispose();
  }
}

class _RubricRowCard extends StatelessWidget {
  const _RubricRowCard({
    required this.number,
    required this.draft,
    required this.canDelete,
    required this.onDelete,
  });

  final int number;
  final _RubricDraft draft;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Criterion $number',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (canDelete)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.criterionCtrl,
            decoration: const InputDecoration(labelText: 'Criterion title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.descriptionCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.marksCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Marks'),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
              suffixIcon: onClear == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: onClear,
                    ),
            ),
            child: Text(value, style: AppTextStyles.body),
          ),
        ),
      ],
    );
  }
}
