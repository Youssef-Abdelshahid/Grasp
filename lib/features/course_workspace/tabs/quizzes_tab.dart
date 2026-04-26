import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/quiz_model.dart';
import '../../../services/quiz_service.dart';
import '../../activity/activity_sheets.dart';
import '../pages/quiz_builder_page.dart';

class QuizzesTab extends StatefulWidget {
  const QuizzesTab({super.key, required this.courseId});

  final String courseId;

  @override
  State<QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends State<QuizzesTab> {
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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(quizzes.length),
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
                      onEdit: () => _openBuilder(quiz: quiz),
                      onTogglePublished: () => _togglePublished(quiz),
                      onDelete: () => _deleteQuiz(quiz),
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
            Text('Quizzes', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              '$count quizzes in this course',
              style: AppTextStyles.bodySmall,
            ),
          ],
        );

        final createButton = ElevatedButton.icon(
          onPressed: () => _openBuilder(),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Create Quiz'),
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
  final VoidCallback onEdit;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

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
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(quiz.isPublished ? 'Unpublish' : 'Publish'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
