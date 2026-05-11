import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../models/quiz_model.dart';
import '../../../models/quiz_question_model.dart';
import '../../../models/material_model.dart';
import '../../../services/gemini_ai_service.dart';
import '../../../services/material_service.dart';
import '../../../services/quiz_service.dart';
import '../../ai_controls/providers/ai_controls_provider.dart';

class QuizBuilderPage extends ConsumerStatefulWidget {
  const QuizBuilderPage({
    super.key,
    required this.courseId,
    this.quiz,
    this.aiDraft,
  });

  final String courseId;
  final QuizModel? quiz;
  final AiQuizDraft? aiDraft;

  @override
  ConsumerState<QuizBuilderPage> createState() => _QuizBuilderPageState();
}

class _QuizBuilderPageState extends ConsumerState<QuizBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  late final List<_QuestionDraft> _questions;
  late final Set<String> _linkedMaterialIds;
  late Future<List<MaterialModel>> _materialsFuture;
  DateTime? _dueAt;
  bool _isSaving = false;
  bool _showCorrectAnswers = false;
  bool _allowRetakes = false;
  bool _showQuestionMarks = true;

  bool get _isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    final quiz = widget.quiz;
    final aiDraft = widget.aiDraft;
    _materialsFuture = MaterialService.instance.getCourseMaterials(
      widget.courseId,
    );
    _linkedMaterialIds = _resolveLinkedMaterialIds(quiz, aiDraft);
    _questions = quiz != null
        ? quiz.questionSchema
              .map(QuizQuestionModel.fromJson)
              .map(_QuestionDraft.fromModel)
              .toList()
        : aiDraft != null
        ? aiDraft.questionSchema
              .map(QuizQuestionModel.fromJson)
              .map(_QuestionDraft.fromModel)
              .toList()
        : [_QuestionDraft()];

    if (_questions.isEmpty) {
      _questions.add(_QuestionDraft());
    }

    if (quiz != null) {
      _titleCtrl.text = quiz.title;
      _descriptionCtrl.text = quiz.description;
      _instructionsCtrl.text = quiz.instructions;
      _durationCtrl.text = quiz.durationMinutes?.toString() ?? '';
      _dueAt = quiz.dueAt?.toLocal();
      _showCorrectAnswers = quiz.showCorrectAnswers;
      _allowRetakes = quiz.allowRetakes;
      _showQuestionMarks = quiz.showQuestionMarks;
    } else if (aiDraft != null) {
      _titleCtrl.text = aiDraft.title;
      _descriptionCtrl.text = aiDraft.description;
      _instructionsCtrl.text = aiDraft.instructions;
      _durationCtrl.text = aiDraft.durationMinutes?.toString() ?? '';
      _dueAt = aiDraft.dueAt?.toLocal();
      _showCorrectAnswers = aiDraft.showCorrectAnswers;
      _allowRetakes = aiDraft.allowRetakes;
      _showQuestionMarks = aiDraft.showQuestionMarks;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _instructionsCtrl.dispose();
    _durationCtrl.dispose();
    for (final question in _questions) {
      question.dispose();
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
          _isEditing ? 'Edit Quiz' : 'Create Quiz',
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
              _buildQuestionsCard(),
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
        color: AppColors.violetLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.quiz_rounded, color: AppColors.violet),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz draft setup', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  'Build manually or review AI-generated questions before publishing.',
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
          Text('Quiz Details', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          _label('Quiz Title *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Quiz 1: Introduction Concepts',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Title is required'
                : null,
          ),
          const SizedBox(height: 16),
          _label('Short Description'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descriptionCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText:
                  'A short summary students will see in the course workspace',
            ),
          ),
          const SizedBox(height: 16),
          _label('Instructions'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _instructionsCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Explain timing, attempts, or what students should prepare',
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              final dueField = _DateField(
                label: 'Due Date',
                value: _dueAt == null
                    ? 'No due date'
                    : FileUtils.formatDateTime(_dueAt!),
                onTap: _pickDueDate,
                onClear: _dueAt == null
                    ? null
                    : () => setState(() {
                        _dueAt = null;
                      }),
              );
              final durationField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Duration (minutes)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '30'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return null;
                      }
                      return int.tryParse(value.trim()) == null
                          ? 'Enter a valid number'
                          : null;
                    },
                  ),
                ],
              );
              final marksField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Total Marks'),
                  const SizedBox(height: 6),
                  InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.functions_rounded, size: 18),
                    ),
                    child: Text(
                      _markText(_totalMarks),
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    dueField,
                    const SizedBox(height: 16),
                    durationField,
                    const SizedBox(height: 16),
                    marksField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dueField),
                  const SizedBox(width: 16),
                  Expanded(child: durationField),
                  const SizedBox(width: 16),
                  Expanded(child: marksField),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Show correct/incorrect answers to students after submission',
            ),
            value: _showCorrectAnswers,
            onChanged: (value) => setState(() => _showCorrectAnswers = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Allow quiz retakes'),
            value: _allowRetakes,
            onChanged: (value) => setState(() => _allowRetakes = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show question marks while taking quiz'),
            value: _showQuestionMarks,
            onChanged: (value) => setState(() => _showQuestionMarks = value),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsCard() {
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
              Text('Questions', style: AppTextStyles.h3),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${_questions.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Question data is stored in a structured schema so later phases can support richer quiz behavior.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _questions.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _QuestionCard(
                number: index + 1,
                draft: _questions[index],
                courseId: widget.courseId,
                canDelete: _questions.length > 1,
                onChanged: () => setState(() {}),
                onDelete: () => _removeQuestion(index),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Question'),
              ),
              if (ref
                  .watch(aiControlsProvider)
                  .valueOrDefaults
                  .canGenerateSingleQuestion)
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _generateQuestion,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Generate Question'),
                ),
            ],
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

  void _addQuestion() {
    setState(() => _questions.add(_QuestionDraft()));
  }

  void _removeQuestion(int index) {
    final question = _questions.removeAt(index);
    question.dispose();
    setState(() {});
  }

  Future<void> _generateQuestion() async {
    final courseMaterials = await _materialsFuture;
    final scopedMaterials = _scopedQuestionMaterials(courseMaterials);
    if (!mounted) return;
    final generated = await showDialog<QuizQuestionModel>(
      context: context,
      builder: (_) => _GenerateQuestionDialog(
        courseId: widget.courseId,
        quizId: widget.quiz?.id,
        materials: scopedMaterials,
        usingLinkedMaterials: _linkedMaterialIds.isNotEmpty,
        existingQuizContext: _singleQuestionContext(),
      ),
    );
    if (generated == null) return;
    setState(() {
      _questions.add(_QuestionDraft.fromModel(generated));
    });
  }

  Future<void> _save(bool publish) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final validationError = _validateQuestions();
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final questionSchema = _questions
          .map((item) => item.toModel().toJson())
          .toList();
      final maxPoints = _totalMarks.ceil();
      final quiz = _isEditing
          ? await QuizService.instance.updateQuiz(
              quizId: widget.quiz!.id,
              title: _titleCtrl.text,
              description: _descriptionCtrl.text,
              instructions: _instructionsCtrl.text,
              dueAt: _dueAt,
              maxPoints: maxPoints,
              durationMinutes: _parseNullableInt(_durationCtrl.text),
              isPublished: publish,
              questionSchema: questionSchema,
              showCorrectAnswers: _showCorrectAnswers,
              allowRetakes: _allowRetakes,
              showQuestionMarks: _showQuestionMarks,
            )
          : await QuizService.instance.createQuiz(
              courseId: widget.courseId,
              title: _titleCtrl.text,
              description: _descriptionCtrl.text,
              instructions: _instructionsCtrl.text,
              dueAt: _dueAt,
              maxPoints: maxPoints,
              durationMinutes: _parseNullableInt(_durationCtrl.text),
              isPublished: publish,
              questionSchema: questionSchema,
              showCorrectAnswers: _showCorrectAnswers,
              allowRetakes: _allowRetakes,
              showQuestionMarks: _showQuestionMarks,
            );

      if (!mounted) {
        return;
      }
      Navigator.pop(context, quiz);
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validateQuestions() {
    if (_questions.isEmpty) {
      return 'Add at least one question before saving.';
    }

    for (var index = 0; index < _questions.length; index++) {
      final question = _questions[index];
      if (question.textCtrl.text.trim().isEmpty) {
        return 'Question ${index + 1} is missing its prompt.';
      }
      if (question.type == 'MCQ' &&
          question.optionCtrls.any((item) => item.text.trim().isEmpty)) {
        return 'Question ${index + 1} needs all answer options filled in.';
      }
      if (question.isMappedType &&
          question.mappingRows.any((row) => !row.isValid)) {
        return 'Question ${index + 1} needs every row filled in.';
      }
    }

    return null;
  }

  int? _parseNullableInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return int.tryParse(trimmed);
  }

  double get _totalMarks {
    return _questions.fold<double>(0, (sum, question) => sum + question.marks);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.label);

  Set<String> _resolveLinkedMaterialIds(QuizModel? quiz, AiQuizDraft? aiDraft) {
    final ids = <String>{};
    if (aiDraft != null) {
      ids.addAll(aiDraft.materialIds);
    }
    final schema = quiz?.questionSchema ?? aiDraft?.questionSchema ?? const [];
    for (final item in schema) {
      final sourceRef = item['source_ref'];
      if (sourceRef is! Map) continue;
      final selected = sourceRef['selected_material_ids'];
      if (selected is List) {
        ids.addAll(
          selected.map((id) => id.toString()).where((id) => id.isNotEmpty),
        );
      }
      final materialId = sourceRef['material_id']?.toString() ?? '';
      if (materialId.isNotEmpty &&
          materialId != 'user_prompt' &&
          materialId != 'question_image' &&
          materialId != 'existing_quiz_context') {
        ids.add(materialId);
      }
    }
    return ids;
  }

  List<MaterialModel> _scopedQuestionMaterials(
    List<MaterialModel> courseMaterials,
  ) {
    if (_linkedMaterialIds.isEmpty) return courseMaterials;
    final scoped = courseMaterials
        .where((material) => _linkedMaterialIds.contains(material.id))
        .toList();
    return scoped.isEmpty ? courseMaterials : scoped;
  }

  String _singleQuestionContext() {
    final parts = <String>[
      if (_titleCtrl.text.trim().isNotEmpty) 'Quiz title: ${_titleCtrl.text}',
      if (_descriptionCtrl.text.trim().isNotEmpty)
        'Quiz description: ${_descriptionCtrl.text}',
      if (_instructionsCtrl.text.trim().isNotEmpty)
        'Quiz instructions: ${_instructionsCtrl.text}',
      ..._questions
          .where((question) => question.textCtrl.text.trim().isNotEmpty)
          .take(8)
          .map((question) => 'Existing question: ${question.textCtrl.text}'),
    ];
    return parts.join('\n');
  }
}

class _QuestionDraft {
  _QuestionDraft()
    : textCtrl = TextEditingController(),
      marksCtrl = TextEditingController(text: '1'),
      explanationCtrl = TextEditingController(),
      sampleAnswerCtrl = TextEditingController(),
      optionCtrls = List.generate(4, (_) => TextEditingController()),
      mappingRows = List.generate(4, (_) => _MappingRowDraft()),
      categoryCtrls = const [],
      sourceReference = const {};

  _QuestionDraft.fromModel(QuizQuestionModel model)
    : type = model.type,
      correctOption = model.correctOption,
      imagePath = model.imagePath,
      imageName = model.imageName,
      sourceReference = model.sourceReference,
      textCtrl = TextEditingController(text: model.questionText),
      marksCtrl = TextEditingController(text: _markText(model.marks)),
      explanationCtrl = TextEditingController(text: model.explanation),
      sampleAnswerCtrl = TextEditingController(text: model.sampleAnswer),
      optionCtrls = List.generate(
        4,
        (index) => TextEditingController(
          text: index < model.options.length ? model.options[index] : '',
        ),
      ),
      mappingRows = _rowsFromModel(model),
      categoryCtrls = const [];

  String type = 'MCQ';
  int correctOption = 0;
  String imagePath = '';
  String imageName = '';
  Map<String, dynamic> sourceReference;
  final TextEditingController textCtrl;
  final List<TextEditingController> optionCtrls;
  final List<_MappingRowDraft> mappingRows;
  final List<TextEditingController> categoryCtrls;
  final TextEditingController marksCtrl;
  final TextEditingController explanationCtrl;
  final TextEditingController sampleAnswerCtrl;

  bool get isMappedType => type == 'Matching';

  double get marks => double.tryParse(marksCtrl.text.trim()) ?? 0;

  QuizQuestionModel toModel() {
    final rows = mappingRows
        .where((row) => row.leftCtrl.text.trim().isNotEmpty)
        .toList();
    return QuizQuestionModel(
      type: type,
      questionText: textCtrl.text.trim(),
      options: type == 'MCQ'
          ? optionCtrls.map((item) => item.text.trim()).toList()
          : type == 'True / False'
          ? const ['True', 'False']
          : const [],
      correctOption: correctOption,
      marks: double.tryParse(marksCtrl.text.trim()) ?? 1,
      explanation: explanationCtrl.text.trim(),
      sampleAnswer: sampleAnswerCtrl.text.trim(),
      imagePath: imagePath,
      imageName: imageName,
      items: isMappedType
          ? rows.map((row) => row.leftCtrl.text.trim()).toList()
          : const [],
      targets: type == 'Matching'
          ? rows.map((row) => row.rightCtrl.text.trim()).toSet().toList()
          : const [],
      categories: const [],
      correctMapping: isMappedType
          ? {
              for (final row in rows)
                row.leftCtrl.text.trim(): row.rightCtrl.text.trim(),
            }
          : const {},
      sourceReference: sourceReference,
    );
  }

  void dispose() {
    textCtrl.dispose();
    for (final optionCtrl in optionCtrls) {
      optionCtrl.dispose();
    }
    for (final row in mappingRows) {
      row.dispose();
    }
    marksCtrl.dispose();
    explanationCtrl.dispose();
    sampleAnswerCtrl.dispose();
  }

  static List<_MappingRowDraft> _rowsFromModel(QuizQuestionModel model) {
    if (model.correctMapping.isEmpty) {
      return List.generate(4, (_) => _MappingRowDraft());
    }
    return model.correctMapping.entries
        .map((entry) => _MappingRowDraft(left: entry.key, right: entry.value))
        .toList();
  }
}

class _MappingRowDraft {
  _MappingRowDraft({String left = '', String right = ''})
    : leftCtrl = TextEditingController(text: left),
      rightCtrl = TextEditingController(text: right);

  final TextEditingController leftCtrl;
  final TextEditingController rightCtrl;

  bool get isValid =>
      leftCtrl.text.trim().isNotEmpty && rightCtrl.text.trim().isNotEmpty;

  void dispose() {
    leftCtrl.dispose();
    rightCtrl.dispose();
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    required this.number,
    required this.draft,
    required this.courseId,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final int number;
  final _QuestionDraft draft;
  final String courseId;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  static const _types = ['MCQ', 'True / False', 'Short Answer', 'Matching'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q${widget.number}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.draft.type, style: AppTextStyles.label),
                ),
                if (widget.canDelete)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Question Text', style: AppTextStyles.label),
                const SizedBox(height: 6),
                TextField(
                  controller: widget.draft.textCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Enter your question here...',
                  ),
                ),
                const SizedBox(height: 10),
                _QuestionImagePicker(
                  draft: widget.draft,
                  courseId: widget.courseId,
                  onChanged: () => setState(widget.onChanged),
                ),
                const SizedBox(height: 14),
                Text('Question Type', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((type) {
                    final selected = widget.draft.type == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          widget.draft.type = type;
                          if (type == 'True / False') {
                            widget.draft.correctOption = 0;
                          }
                          widget.onChanged();
                        });
                      },
                      selectedColor: AppColors.primaryLight,
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                if (widget.draft.type == 'MCQ') _buildMcqOptions(),
                if (widget.draft.type == 'True / False')
                  _buildTrueFalseOptions(),
                if (widget.draft.type == 'Short Answer')
                  _buildShortAnswerField(),
                if (widget.draft.type == 'Matching')
                  _buildMappingRows('Left prompt', 'Correct match'),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (_, constraints) {
                    final isNarrow = constraints.maxWidth < 340;
                    final marksField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Marks', style: AppTextStyles.label),
                        const SizedBox(height: 6),
                        TextField(
                          controller: widget.draft.marksCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(hintText: '1'),
                          onChanged: (_) => widget.onChanged(),
                        ),
                      ],
                    );
                    final explanationField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Explanation', style: AppTextStyles.label),
                        const SizedBox(height: 6),
                        TextField(
                          controller: widget.draft.explanationCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Optional explanation or rationale',
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          marksField,
                          const SizedBox(height: 12),
                          explanationField,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: marksField),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: explanationField),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMcqOptions() {
    const labels = ['A', 'B', 'C', 'D'];
    return RadioGroup<int>(
      groupValue: widget.draft.correctOption,
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => widget.draft.correctOption = value);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Options', style: AppTextStyles.label),
          const SizedBox(height: 8),
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Radio<int>(
                    value: index,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 26,
                    child: Text(
                      labels[index],
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: widget.draft.optionCtrls[index],
                      decoration: InputDecoration(
                        hintText: 'Option ${labels[index]}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrueFalseOptions() {
    return RadioGroup<int>(
      groupValue: widget.draft.correctOption,
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => widget.draft.correctOption = value);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Correct Answer', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Radio<int>(value: 0, visualDensity: VisualDensity.compact),
              const Text('True'),
              const SizedBox(width: 20),
              Radio<int>(value: 1, visualDensity: VisualDensity.compact),
              const Text('False'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortAnswerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sample Answer', style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: widget.draft.sampleAnswerCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Optional reference answer for later grading phases',
          ),
        ),
      ],
    );
  }

  Widget _buildMappingRows(String leftLabel, String rightLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Correct Mapping', style: AppTextStyles.label),
        const SizedBox(height: 8),
        ...widget.draft.mappingRows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.leftCtrl,
                    decoration: InputDecoration(
                      labelText: '$leftLabel ${index + 1}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.rightCtrl,
                    decoration: InputDecoration(labelText: rightLabel),
                  ),
                ),
                if (widget.draft.mappingRows.length > 1)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        final removed = widget.draft.mappingRows.removeAt(
                          index,
                        );
                        removed.dispose();
                        widget.onChanged();
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              widget.draft.mappingRows.add(_MappingRowDraft());
              widget.onChanged();
            });
          },
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Row'),
        ),
      ],
    );
  }
}

class _QuestionImagePicker extends StatefulWidget {
  const _QuestionImagePicker({
    required this.draft,
    required this.courseId,
    required this.onChanged,
  });

  final _QuestionDraft draft;
  final String courseId;
  final VoidCallback onChanged;

  @override
  State<_QuestionImagePicker> createState() => _QuestionImagePickerState();
}

class _QuestionImagePickerState extends State<_QuestionImagePicker> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.draft.imagePath.isNotEmpty;
    return Row(
      children: [
        Icon(
          hasImage ? Icons.image_rounded : Icons.add_photo_alternate_outlined,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasImage ? widget.draft.imageName : 'No question image',
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: _uploading ? null : _pickImage,
          child: Text(
            _uploading
                ? 'Uploading...'
                : hasImage
                ? 'Replace'
                : 'Add Image',
          ),
        ),
        if (hasImage)
          IconButton(
            onPressed: _uploading
                ? null
                : () {
                    setState(() {
                      widget.draft.imagePath = '';
                      widget.draft.imageName = '';
                    });
                    widget.onChanged();
                  },
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() => _uploading = true);
    try {
      final uploaded = await QuizService.instance.uploadQuestionImage(
        courseId: widget.courseId,
        file: result.files.single,
      );
      if (!mounted) return;
      setState(() {
        widget.draft.imagePath = uploaded['image_path'] as String? ?? '';
        widget.draft.imageName = uploaded['image_name'] as String? ?? '';
      });
      widget.onChanged();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

class _GenerateQuestionDialog extends StatefulWidget {
  const _GenerateQuestionDialog({
    required this.courseId,
    required this.quizId,
    required this.materials,
    required this.usingLinkedMaterials,
    required this.existingQuizContext,
  });

  final String courseId;
  final String? quizId;
  final List<MaterialModel> materials;
  final bool usingLinkedMaterials;
  final String existingQuizContext;

  @override
  State<_GenerateQuestionDialog> createState() =>
      _GenerateQuestionDialogState();
}

class _GenerateQuestionDialogState extends State<_GenerateQuestionDialog> {
  static const _types = ['MCQ', 'True / False', 'Short Answer', 'Matching'];

  final _promptCtrl = TextEditingController();
  String _type = 'MCQ';
  bool _isGenerating = false;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Question'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Question Type'),
                items: _types
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: _isGenerating
                    ? null
                    : (value) => setState(() => _type = value ?? 'MCQ'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptCtrl,
                enabled: !_isGenerating,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Optional Prompt',
                  hintText: 'Focus area, learning objective, or constraints',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _sourceScopeText(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _generate,
          child: Text(_isGenerating ? 'Generating...' : 'Generate'),
        ),
      ],
    );
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final question = await GeminiAiService.instance.generateSingleQuestion(
        courseId: widget.courseId,
        materials: widget.materials,
        type: _type,
        prompt: _promptCtrl.text,
        marks: 1,
        quizId: widget.quizId,
        existingQuizContext: widget.existingQuizContext,
      );
      if (!mounted) return;
      Navigator.pop(context, question);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  String _sourceScopeText() {
    if (widget.usingLinkedMaterials && widget.materials.isNotEmpty) {
      final names = widget.materials.map((material) => material.title).toList();
      if (names.length <= 2) {
        return 'Using materials linked to this quiz: ${names.join(', ')}';
      }
      return 'Using ${names.length} materials linked to this quiz';
    }
    if (widget.materials.isNotEmpty) {
      return 'Using course materials because no quiz-linked materials were found';
    }
    return 'Using prompt context';
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

String _markText(num value) {
  final number = value.toDouble();
  if (number == number.roundToDouble()) {
    return number.toInt().toString();
  }
  return number.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
}
