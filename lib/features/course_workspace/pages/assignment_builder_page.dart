import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../models/assignment_model.dart';
import '../../../models/assignment_rubric_item_model.dart';
import '../../../services/gemini_ai_service.dart';
import '../../../services/assignment_service.dart';

class AssignmentBuilderPage extends StatefulWidget {
  const AssignmentBuilderPage({
    super.key,
    required this.courseId,
    this.assignment,
    this.aiDraft,
  });

  final String courseId;
  final AssignmentModel? assignment;
  final AiAssignmentDraft? aiDraft;

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
  late final List<Map<String, dynamic>> _attachments;
  DateTime? _dueAt;
  bool _isSaving = false;
  bool _isUploadingAttachment = false;

  bool get _isEditing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final assignment = widget.assignment;
    final aiDraft = widget.aiDraft;
    _rubric = assignment != null
        ? assignment.rubric
              .map(AssignmentRubricItemModel.fromJson)
              .map(_RubricDraft.fromModel)
              .toList()
        : aiDraft != null
        ? aiDraft.rubric
              .map(AssignmentRubricItemModel.fromJson)
              .map(_RubricDraft.fromModel)
              .toList()
        : <_RubricDraft>[];
    _attachments =
        assignment?.attachments
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        aiDraft?.attachments
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        <Map<String, dynamic>>[];

    if (assignment != null) {
      _titleCtrl.text = assignment.title;
      _instructionsCtrl.text = assignment.instructions;
      _attachmentRequirementsCtrl.text = assignment.attachmentRequirements;
      _marksCtrl.text = assignment.maxPoints.toString();
      _dueAt = assignment.dueAt?.toLocal();
    } else if (aiDraft != null) {
      _titleCtrl.text = aiDraft.title;
      _instructionsCtrl.text = aiDraft.instructions;
      _attachmentRequirementsCtrl.text = aiDraft.attachmentRequirements;
      _marksCtrl.text = aiDraft.maxPoints.toString();
      _dueAt = aiDraft.dueAt?.toLocal();
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
          icon: Icon(Icons.arrow_back_rounded),
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
          Icon(Icons.assignment_rounded, color: AppColors.emerald),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assignment draft setup', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  'Build manually or review AI-generated instructions before publishing.',
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
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Title is required'
                : null,
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
              hintText:
                  'Optional notes about files, format, or upload expectations',
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final dateField = _DateField(
                label: 'Deadline',
                value: _dueAt == null
                    ? 'No deadline'
                    : FileUtils.formatDateTime(_dueAt!),
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
                  children: [dateField, const SizedBox(height: 16), marksField],
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
          const SizedBox(height: 16),
          _AttachmentEditor(
            attachments: _attachments,
            uploading: _isUploadingAttachment,
            onAdd: _pickAttachment,
            onRemove: (index) => setState(() => _attachments.removeAt(index)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            'Rubric rows are optional. Add criteria when you want structured grading guidance.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          if (_rubric.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No criteria/rubric added.',
                style: AppTextStyles.bodySmall,
              ),
            )
          else
            ...List.generate(
              _rubric.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RubricRowCard(
                  number: index + 1,
                  draft: _rubric[index],
                  canDelete: true,
                  onDelete: () => _removeRubric(index),
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addRubric,
            icon: Icon(Icons.add_rounded, size: 16),
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
    if (!mounted) {
      return;
    }
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _dueAt ?? DateTime(now.year, now.month, now.day, 23, 59),
      ),
    );
    if (selectedTime == null) {
      return;
    }

    setState(() {
      _dueAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _isUploadingAttachment = true);
    try {
      final attachment = await AssignmentService.instance.uploadAttachment(
        courseId: widget.courseId,
        file: result.files.single,
      );
      if (!mounted) return;
      setState(() => _attachments.add(attachment));
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
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
      final rubric = _rubric
          .where((item) => item.criterionCtrl.text.trim().isNotEmpty)
          .map((item) => item.toModel().toJson())
          .toList();
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
              attachments: _attachments,
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
              attachments: _attachments,
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
    for (var index = 0; index < _rubric.length; index++) {
      final item = _rubric[index];
      final hasAnyText =
          item.criterionCtrl.text.trim().isNotEmpty ||
          item.descriptionCtrl.text.trim().isNotEmpty ||
          item.marksCtrl.text.trim().isNotEmpty;
      if (!hasAnyText) {
        continue;
      }
      if (item.criterionCtrl.text.trim().isEmpty) {
        return 'Rubric criterion ${index + 1} needs a title or should be removed.';
      }
      if (item.marks <= 0) {
        return 'Rubric criterion ${index + 1} needs valid marks.';
      }
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.label);
}

class _RubricDraft {
  _RubricDraft()
    : criterionCtrl = TextEditingController(),
      descriptionCtrl = TextEditingController(),
      marksCtrl = TextEditingController(text: '10'),
      sourceReference = const {};

  _RubricDraft.fromModel(AssignmentRubricItemModel model)
    : criterionCtrl = TextEditingController(text: model.criterion),
      descriptionCtrl = TextEditingController(text: model.description),
      marksCtrl = TextEditingController(text: model.marks.toString()),
      sourceReference = model.sourceReference;

  final TextEditingController criterionCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController marksCtrl;
  Map<String, dynamic> sourceReference;

  int get marks => int.tryParse(marksCtrl.text.trim()) ?? 0;

  AssignmentRubricItemModel toModel() {
    return AssignmentRubricItemModel(
      criterion: criterionCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      marks: marks,
      sourceReference: sourceReference,
    );
  }

  void dispose() {
    criterionCtrl.dispose();
    descriptionCtrl.dispose();
    marksCtrl.dispose();
  }
}

class _AttachmentEditor extends StatelessWidget {
  const _AttachmentEditor({
    required this.attachments,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Map<String, dynamic>> attachments;
  final bool uploading;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assignment Attachments', style: AppTextStyles.label),
        const SizedBox(height: 8),
        if (attachments.isEmpty)
          Text('No files attached.', style: AppTextStyles.bodySmall)
        else
          ...attachments.asMap().entries.map((entry) {
            final attachment = entry.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.attach_file_rounded),
              title: Text(
                attachment['name']?.toString() ?? 'Attachment',
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: attachment['size'] is num
                  ? Text(
                      FileUtils.formatBytes(
                        (attachment['size'] as num).toInt(),
                      ),
                    )
                  : null,
              trailing: IconButton(
                icon: Icon(Icons.close_rounded),
                onPressed: () => onRemove(entry.key),
              ),
            );
          }),
        OutlinedButton.icon(
          onPressed: uploading ? null : onAdd,
          icon: uploading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.attach_file_rounded, size: 16),
          label: Text(uploading ? 'Uploading...' : 'Add Attachment'),
        ),
      ],
    );
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  icon: Icon(
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
              prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
              suffixIcon: onClear == null
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded, size: 18),
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
