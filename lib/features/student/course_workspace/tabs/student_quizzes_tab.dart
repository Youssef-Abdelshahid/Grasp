import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../models/quiz_model.dart';
import '../../../../models/submission_model.dart';
import '../../../../models/user_settings_model.dart';
import '../../../../services/quiz_service.dart';
import '../../../../services/submission_service.dart';
import '../../../../services/user_settings_service.dart';
import '../../../activity/activity_sheets.dart';
import '../../study/quiz_attempt_page.dart';

class StudentQuizzesTab extends StatefulWidget {
  const StudentQuizzesTab({super.key, required this.courseId});

  final String courseId;

  @override
  State<StudentQuizzesTab> createState() => _StudentQuizzesTabState();
}

class _StudentQuizzesTabState extends State<StudentQuizzesTab> {
  late Future<_StudentQuizData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StudentQuizData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _StudentQuizData([], {});
        final quizzes = data.quizzes;
        final completed = data.latestSubmissions.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quizzes', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                '$completed of ${quizzes.length} attempted',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (quizzes.isEmpty)
                const EmptyState(
                  icon: Icons.quiz_rounded,
                  title: 'No quizzes available',
                  subtitle:
                      'Published quizzes from your instructor will appear here once they are ready.',
                )
              else
                ...quizzes.map(
                  (quiz) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuizCard(
                      quiz: quiz,
                      submission: data.latestSubmissions[quiz.id],
                      onStart: () =>
                          _startQuiz(quiz, data.latestSubmissions[quiz.id]),
                      onViewAttempt: () => _showAttemptDetails(
                        quiz,
                        data.latestSubmissions[quiz.id],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<_StudentQuizData> _load() async {
    final quizzes = await QuizService.instance.getCourseQuizzes(
      widget.courseId,
    );
    final submissions = await SubmissionService.instance
        .getLatestQuizAttemptsForCourse(widget.courseId);
    final settings = await UserSettingsService.instance
        .getCurrentSettingsOrNull();
    if (settings is StudentSettings && settings.showOverdueFirst) {
      quizzes.sort(_compareQuizzesWithOverdueFirst);
    }
    return _StudentQuizData(quizzes, submissions);
  }

  Future<void> _startQuiz(QuizModel quiz, SubmissionModel? submission) async {
    if (submission != null && !quiz.allowRetakes) {
      _showMessage('You have already submitted this quiz.');
      return;
    }
    final result = await Navigator.push<SubmissionModel>(
      context,
      MaterialPageRoute(builder: (_) => QuizAttemptPage(quiz: quiz)),
    );
    if (!mounted || result == null) {
      return;
    }
    _refresh();
  }

  Future<void> _showAttemptDetails(
    QuizModel quiz,
    SubmissionModel? submission,
  ) async {
    if (submission == null) {
      return;
    }
    await showStudentSubmissionResultSheet(
      context: context,
      submissionId: submission.id,
    );
  }

  void _refresh() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

int _compareQuizzesWithOverdueFirst(QuizModel a, QuizModel b) {
  final now = DateTime.now();
  final aOverdue = a.dueAt != null && a.dueAt!.isBefore(now);
  final bOverdue = b.dueAt != null && b.dueAt!.isBefore(now);
  if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
  final aDue = a.dueAt;
  final bDue = b.dueAt;
  if (aDue == null && bDue == null) return a.title.compareTo(b.title);
  if (aDue == null) return 1;
  if (bDue == null) return -1;
  return aDue.compareTo(bDue);
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.quiz,
    required this.submission,
    required this.onStart,
    required this.onViewAttempt,
  });

  final QuizModel quiz;
  final SubmissionModel? submission;
  final VoidCallback onStart;
  final VoidCallback onViewAttempt;

  @override
  Widget build(BuildContext context) {
    final hasSubmission = submission != null;
    final statusColor = hasSubmission ? AppColors.success : AppColors.amber;
    final statusBg = hasSubmission
        ? AppColors.successLight
        : AppColors.amberLight;

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
                  color: AppColors.violetLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: AppColors.violet,
                  size: 16,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${quiz.questionCount} questions • ${quiz.dueAt == null ? 'No deadline' : 'Due: ${FileUtils.formatDate(quiz.dueAt!)}'}',
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
                  hasSubmission ? 'Attempted' : 'Available',
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          if (hasSubmission)
            Row(
              children: [
                if (submission!.score != null &&
                    submission!.gradeVisible &&
                    submission!.attemptVisible)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.emerald, Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Score: ${submission!.score!.toStringAsFixed(0)}%',
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: onViewAttempt,
                  child: const Text('View Attempt'),
                ),
                ElevatedButton.icon(
                  onPressed: quiz.allowRetakes ? onStart : null,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    quiz.allowRetakes ? 'Retake' : 'Already submitted',
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Start Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentQuizData {
  const _StudentQuizData(this.quizzes, this.latestSubmissions);

  final List<QuizModel> quizzes;
  final Map<String, SubmissionModel> latestSubmissions;
}
