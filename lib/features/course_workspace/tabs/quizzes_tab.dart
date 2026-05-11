import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/quiz_model.dart';
import '../../../models/material_model.dart';
import '../../../models/user_settings_model.dart';
import '../../../services/gemini_ai_service.dart';
import '../../../services/material_service.dart';
import '../../../services/quiz_service.dart';
import '../../../services/user_settings_service.dart';
import '../../activity/activity_sheets.dart';
import '../../permissions/providers/permissions_provider.dart';
import '../pages/quiz_builder_page.dart';

class QuizzesTab extends ConsumerStatefulWidget {
  const QuizzesTab({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends ConsumerState<QuizzesTab> {
  late Future<List<QuizModel>> _quizzesFuture;

  @override
  void initState() {
    super.initState();
    _quizzesFuture = QuizService.instance.getCourseQuizzes(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuizModel>>(
      future: _quizzesFuture,
      builder: (context, snapshot) {
        final quizzes = snapshot.data ?? [];
        final permissions = ref.watch(permissionsProvider).valueOrDefaults;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                quizzes.length,
                canManage: permissions.manageQuizzes,
                canUseAi: permissions.useAiQuizGeneration,
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (quizzes.isEmpty)
                const EmptyState(
                  icon: Icons.quiz_rounded,
                  title: 'No quizzes yet',
                  subtitle:
                      'Create your first manual quiz to start building assessment flow for this course.',
                )
              else
                ...quizzes.map(
                  (quiz) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuizCard(
                      quiz: quiz,
                      onTap: () => _showQuizDetails(quiz),
                      onEdit: permissions.manageQuizzes
                          ? () => _openBuilder(quiz: quiz)
                          : null,
                      onTogglePublished: permissions.manageQuizzes
                          ? () => _togglePublished(quiz)
                          : null,
                      onDelete: permissions.manageQuizzes
                          ? () => _deleteQuiz(quiz)
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
            Text('Quizzes', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              '$count quizzes in this course',
              style: AppTextStyles.bodySmall,
            ),
          ],
        );

        final createButton = ElevatedButton.icon(
          onPressed: canManage ? () => _openBuilder() : null,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Create Quiz'),
        );
        final generateButton = OutlinedButton.icon(
          onPressed: canUseAi && canManage ? _generateQuiz : null,
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Generate Quiz'),
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

  Future<void> _openBuilder({QuizModel? quiz}) async {
    final result = await Navigator.push<QuizModel>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizBuilderPage(courseId: widget.courseId, quiz: quiz),
      ),
    );
    if (result != null) {
      _refresh();
    }
  }

  Future<void> _generateQuiz() async {
    try {
      final materials = await MaterialService.instance.getCourseMaterials(
        widget.courseId,
      );
      final settings = await UserSettingsService.instance
          .getCurrentSettingsOrNull();
      if (!mounted) return;
      final draft = await showDialog<AiQuizDraft>(
        context: context,
        builder: (_) => _GenerateQuizDialog(
          courseId: widget.courseId,
          materials: materials,
          defaults: settings is InstructorSettings ? settings : null,
        ),
      );
      if (draft == null || !mounted) return;
      final result = await Navigator.push<QuizModel>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              QuizBuilderPage(courseId: widget.courseId, aiDraft: draft),
        ),
      );
      if (result != null) _refresh();
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _togglePublished(QuizModel quiz) async {
    try {
      await QuizService.instance.setPublished(
        quizId: quiz.id,
        isPublished: !quiz.isPublished,
      );
      _refresh();
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteQuiz(QuizModel quiz) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Quiz'),
            content: Text('Delete "${quiz.title}"?'),
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
      await QuizService.instance.deleteQuiz(quiz.id);
      _refresh();
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _showQuizDetails(QuizModel quiz) async {
    final permissions = ref.read(permissionsProvider).valueOrDefaults;
    final details = await QuizService.instance.getQuizDetails(quiz.id);
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(details.title),
        content: SizedBox(
          width: 520,
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
                  label: 'Questions',
                  value: '${details.questionCount}',
                ),
                if (details.durationMinutes != null)
                  _DetailLine(
                    label: 'Duration',
                    value: '${details.durationMinutes} min',
                  ),
                _DetailLine(label: 'Points', value: '${details.maxPoints}'),
                if (details.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Description', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(details.description, style: AppTextStyles.bodySmall),
                ],
                if (details.instructions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Instructions', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(details.instructions, style: AppTextStyles.bodySmall),
                ],
                if (permissions.viewStudentActivity)
                  AssessmentActivityPanel(assessmentId: details.id, isQuiz: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (permissions.manageQuizzes)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openBuilder(quiz: details);
              },
              child: const Text('Edit'),
            ),
        ],
      ),
    );
  }

  void _refresh() {
    setState(() {
      _quizzesFuture = QuizService.instance.getCourseQuizzes(widget.courseId);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.quiz,
    required this.onTap,
    required this.onEdit,
    required this.onTogglePublished,
    required this.onDelete,
  });

  final QuizModel quiz;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onTogglePublished;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final chipColor = quiz.isPublished ? AppColors.success : AppColors.warning;
    final chipBackground = quiz.isPublished
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
                  color: AppColors.violetLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: AppColors.violet,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: AppTextStyles.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${quiz.questionCount} questions',
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          quiz.dueAt == null
                              ? 'No deadline'
                              : 'Due ${FileUtils.formatDate(quiz.dueAt!.toLocal())}',
                          style: AppTextStyles.caption,
                        ),
                        if (quiz.durationMinutes != null)
                          Text(
                            '${quiz.durationMinutes} min',
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
                  quiz.isPublished ? 'Published' : 'Draft',
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
                        quiz.isPublished ? 'Unpublish' : 'Accept & Publish',
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(quiz.isPublished ? 'Delete' : 'Reject Draft'),
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

class _GenerateQuizDialog extends StatefulWidget {
  const _GenerateQuizDialog({
    required this.courseId,
    required this.materials,
    this.defaults,
  });

  final String courseId;
  final List<MaterialModel> materials;
  final InstructorSettings? defaults;

  @override
  State<_GenerateQuizDialog> createState() => _GenerateQuizDialogState();
}

class _GenerateQuizDialogState extends State<_GenerateQuizDialog> {
  final _promptCtrl = TextEditingController();
  final _countCtrl = TextEditingController(text: '10');
  final _marksCtrl = TextEditingController(text: '100');
  final _minutesCtrl = TextEditingController(text: '30');
  final _selectedMaterialIds = <String>{};
  final _types = <String>{'MCQ'};
  String _difficulty = 'medium';
  DateTime? _deadline;
  bool _allMaterials = true;
  bool _allowRetakes = false;
  bool _showAnswers = false;
  bool _showMarks = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final defaults = widget.defaults;
    if (defaults == null) return;
    _difficulty = defaults.defaultQuizDifficulty;
    _countCtrl.text = defaults.defaultQuestionCount.toString();
    _types
      ..clear()
      ..addAll(defaults.defaultQuestionTypes.map(_questionTypeToUi));
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _countCtrl.dispose();
    _marksCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Quiz Draft'),
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
                  hintText: 'Focus area or special instructions',
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
                      controller: _countCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Questions'),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _minutesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minutes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: ['MCQ', 'True / False', 'Short Answer', 'Matching']
                      .map(
                        (type) => FilterChip(
                          label: Text(type),
                          selected: _types.contains(type),
                          onSelected: _loading
                              ? null
                              : (selected) => setState(() {
                                  selected
                                      ? _types.add(type)
                                      : _types.remove(type);
                                }),
                        ),
                      )
                      .toList(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow retakes'),
                value: _allowRetakes,
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _allowRetakes = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show correction after submission'),
                value: _showAnswers,
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _showAnswers = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show question marks'),
                value: _showMarks,
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _showMarks = value),
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
      final draft = await GeminiAiService.instance.generateQuizDraft(
        courseId: widget.courseId,
        materials: selected,
        prompt: _promptCtrl.text,
        questionCount: int.tryParse(_countCtrl.text) ?? 10,
        questionTypes: _types.map(_questionTypeFromUi).toList(),
        difficulty: _difficulty,
        totalMarks: int.tryParse(_marksCtrl.text) ?? 100,
        timeLimitMinutes: int.tryParse(_minutesCtrl.text),
        deadline: _deadline,
        allowRetakes: _allowRetakes,
        showCorrectAnswers: _showAnswers,
        showQuestionMarks: _showMarks,
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

String _questionTypeToUi(String type) {
  return type == 'True/False' ? 'True / False' : type;
}

String _questionTypeFromUi(String type) {
  return type == 'True / False' ? 'True/False' : type;
}
