import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../models/quiz_model.dart';
import '../../../models/quiz_question_model.dart';
import '../../../services/quiz_service.dart';

class QuizBuilderPage extends StatefulWidget {
  const QuizBuilderPage({
    super.key,
    required this.courseId,
    this.quiz,
  });

  final String courseId;
  final QuizModel? quiz;

  @override
  State<QuizBuilderPage> createState() => _QuizBuilderPageState();
}

class _QuizBuilderPageState extends State<QuizBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _maxPointsCtrl = TextEditingController(text: '100');
  final _durationCtrl = TextEditingController();

  late final List<_QuestionDraft> _questions;
  DateTime? _dueAt;
  bool _isSaving = false;

  bool get _isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    final quiz = widget.quiz;
    _questions = quiz == null
        ? [_QuestionDraft()]
        : quiz.questionSchema
            .map(QuizQuestionModel.fromJson)
            .map(_QuestionDraft.fromModel)
            .toList();

    if (_questions.isEmpty) {
      _questions.add(_QuestionDraft());
    }

    if (quiz != null) {
      _titleCtrl.text = quiz.title;
      _descriptionCtrl.text = quiz.description;
      _instructionsCtrl.text = quiz.instructions;
      _maxPointsCtrl.text = quiz.maxPoints.toString();
      _durationCtrl.text = quiz.durationMinutes?.toString() ?? '';
      _dueAt = quiz.dueAt?.toLocal();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _instructionsCtrl.dispose();
    _maxPointsCtrl.dispose();
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
                Text('Manual quiz setup', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  'This phase stores quiz metadata and manual question structure. AI generation stays disabled for now.',
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
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          _label('Short Description'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descriptionCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'A short summary students will see in the course workspace',
            ),
          ),
          const SizedBox(height: 16),
          _label('Instructions'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _instructionsCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Explain timing, attempts, or what students should prepare',
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              final dueField = _DateField(
                label: 'Due Date',
                value: _dueAt == null ? 'No due date' : FileUtils.formatDate(_dueAt!),
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
                  _label('Max Points *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _maxPointsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '100'),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter valid points';
                      }
                      return null;
                    },
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                canDelete: _questions.length > 1,
                onChanged: () => setState(() {}),
                onDelete: () => _removeQuestion(index),
              ),
            ),
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Question'),
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

  void _addQuestion() {
    setState(() => _questions.add(_QuestionDraft()));
  }

  void _removeQuestion(int index) {
    final question = _questions.removeAt(index);
    question.dispose();
    setState(() {});
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
      final questionSchema = _questions.map((item) => item.toModel().toJson()).toList();
      final quiz = _isEditing
          ? await QuizService.instance.updateQuiz(
              quizId: widget.quiz!.id,
              title: _titleCtrl.text,
              description: _descriptionCtrl.text,
              instructions: _instructionsCtrl.text,
              dueAt: _dueAt,
              maxPoints: int.parse(_maxPointsCtrl.text.trim()),
              durationMinutes: _parseNullableInt(_durationCtrl.text),
              isPublished: publish,
              questionSchema: questionSchema,
            )
          : await QuizService.instance.createQuiz(
              courseId: widget.courseId,
              title: _titleCtrl.text,
              description: _descriptionCtrl.text,
              instructions: _instructionsCtrl.text,
              dueAt: _dueAt,
              maxPoints: int.parse(_maxPointsCtrl.text.trim()),
              durationMinutes: _parseNullableInt(_durationCtrl.text),
              isPublished: publish,
              questionSchema: questionSchema,
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.label);
}

class _QuestionDraft {
  _QuestionDraft()
      : textCtrl = TextEditingController(),
        marksCtrl = TextEditingController(text: '1'),
        explanationCtrl = TextEditingController(),
        sampleAnswerCtrl = TextEditingController(),
        optionCtrls = List.generate(4, (_) => TextEditingController());

  _QuestionDraft.fromModel(QuizQuestionModel model)
      : type = model.type,
        correctOption = model.correctOption,
        textCtrl = TextEditingController(text: model.questionText),
        marksCtrl = TextEditingController(text: model.marks.toString()),
        explanationCtrl = TextEditingController(text: model.explanation),
        sampleAnswerCtrl = TextEditingController(text: model.sampleAnswer),
        optionCtrls = List.generate(
          4,
          (index) => TextEditingController(
            text: index < model.options.length ? model.options[index] : '',
          ),
        );

  String type = 'MCQ';
  int correctOption = 0;
  final TextEditingController textCtrl;
  final List<TextEditingController> optionCtrls;
  final TextEditingController marksCtrl;
  final TextEditingController explanationCtrl;
  final TextEditingController sampleAnswerCtrl;

  QuizQuestionModel toModel() {
    return QuizQuestionModel(
      type: type,
      questionText: textCtrl.text.trim(),
      options: type == 'MCQ'
          ? optionCtrls.map((item) => item.text.trim()).toList()
          : type == 'True / False'
              ? const ['True', 'False']
              : const [],
      correctOption: correctOption,
      marks: int.tryParse(marksCtrl.text.trim()) ?? 1,
      explanation: explanationCtrl.text.trim(),
      sampleAnswer: sampleAnswerCtrl.text.trim(),
    );
  }

  void dispose() {
    textCtrl.dispose();
    for (final optionCtrl in optionCtrls) {
      optionCtrl.dispose();
    }
    marksCtrl.dispose();
    explanationCtrl.dispose();
    sampleAnswerCtrl.dispose();
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    required this.number,
    required this.draft,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final int number;
  final _QuestionDraft draft;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  static const _types = ['MCQ', 'True / False', 'Short Answer'];

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        color:
                            selected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                if (widget.draft.type == 'MCQ') _buildMcqOptions(),
                if (widget.draft.type == 'True / False') _buildTrueFalseOptions(),
                if (widget.draft.type == 'Short Answer') _buildShortAnswerField(),
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
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '1'),
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
              Radio<int>(
                value: 0,
                visualDensity: VisualDensity.compact,
              ),
              const Text('True'),
              const SizedBox(width: 20),
              Radio<int>(
                value: 1,
                visualDensity: VisualDensity.compact,
              ),
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
