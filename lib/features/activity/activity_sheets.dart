import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/user_utils.dart';
import '../../models/activity_models.dart';
import '../../models/quiz_question_model.dart';
import '../../services/activity_service.dart';
import '../../services/quiz_service.dart';

Future<void> showStudentActivitySheet({
  required BuildContext context,
  required String courseId,
  required String studentId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _StudentActivitySheet(courseId: courseId, studentId: studentId),
  );
}

Future<void> showSubmissionDetailSheet({
  required BuildContext context,
  required String submissionId,
  bool canGrade = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _SubmissionDetailSheet(submissionId: submissionId, canGrade: canGrade),
  );
}

Future<void> showStudentSubmissionResultSheet({
  required BuildContext context,
  required String submissionId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SubmissionDetailSheet(
      submissionId: submissionId,
      canGrade: false,
      studentResult: true,
    ),
  );
}

class _SheetFeedbackScaffold extends StatelessWidget {
  const _SheetFeedbackScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        resizeToAvoidBottomInset: false,
        body: child,
      ),
    );
  }
}

class AssessmentActivityPanel extends StatefulWidget {
  const AssessmentActivityPanel({
    super.key,
    required this.assessmentId,
    required this.isQuiz,
  });

  final String assessmentId;
  final bool isQuiz;

  @override
  State<AssessmentActivityPanel> createState() =>
      _AssessmentActivityPanelState();
}

class _AssessmentActivityPanelState extends State<AssessmentActivityPanel> {
  late Future<AssessmentActivity> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.isQuiz
        ? ActivityService.instance.getQuizActivity(widget.assessmentId)
        : ActivityService.instance.getAssignmentActivity(widget.assessmentId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssessmentActivity>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _MutedText('Unable to load activity: ${snapshot.error}');
        }
        final activity = snapshot.data;
        if (activity == null) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('Student Activity', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            _StatsWrap(stats: activity.stats, isQuiz: widget.isQuiz),
            const SizedBox(height: 14),
            Text(
              widget.isQuiz ? 'Attempts' : 'Submissions',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 8),
            if (activity.items.isEmpty)
              const _MutedText('No enrolled students found.')
            else
              ...activity.items.map(
                (item) => _SubmissionRow(
                  item: item,
                  actionLabel: widget.isQuiz ? 'Attempt' : 'Submission',
                  onOpen: item.submissionId == null
                      ? null
                      : () => showSubmissionDetailSheet(
                          context: context,
                          submissionId: item.submissionId!,
                        ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StudentActivitySheet extends StatelessWidget {
  const _StudentActivitySheet({
    required this.courseId,
    required this.studentId,
  });

  final String courseId;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return _SheetFeedbackScaffold(
          child: FutureBuilder<StudentCourseActivityDetail>(
            future: ActivityService.instance.getStudentCourseActivity(
              courseId: courseId,
              studentId: studentId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _SheetError(message: snapshot.error.toString());
              }
              final detail = snapshot.data;
              if (detail == null) {
                return const _SheetError(message: 'No activity found.');
              }
              final student = detail.student;
              return ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          UserUtils.initials(student.studentName),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.studentName, style: AppTextStyles.h2),
                            Text(
                              student.studentEmail,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(value: student.progress.clamp(0, 1)),
                  const SizedBox(height: 8),
                  Text(
                    '${student.completedCount}/${student.totalCount} activities complete - ${student.overdueCount} overdue',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  _ActivitySection(
                    title: 'Quizzes',
                    items: detail.quizzes,
                    empty: 'No published quizzes.',
                  ),
                  const SizedBox(height: 18),
                  _ActivitySection(
                    title: 'Assignments',
                    items: detail.assignments,
                    empty: 'No published assignments.',
                  ),
                  const SizedBox(height: 18),
                  Text('Latest Activity', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  if (detail.timeline.isEmpty)
                    const _MutedText('No submissions yet.')
                  else
                    ...detail.timeline.map(
                      (item) => _TimelineRow(
                        item: item,
                        onOpen: item.submissionId == null
                            ? null
                            : () => showSubmissionDetailSheet(
                                context: context,
                                submissionId: item.submissionId!,
                              ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SubmissionDetailSheet extends StatefulWidget {
  const _SubmissionDetailSheet({
    required this.submissionId,
    required this.canGrade,
    this.studentResult = false,
  });

  final String submissionId;
  final bool canGrade;
  final bool studentResult;

  @override
  State<_SubmissionDetailSheet> createState() => _SubmissionDetailSheetState();
}

class _SubmissionDetailSheetState extends State<_SubmissionDetailSheet> {
  late Future<SubmissionDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.studentResult
        ? ActivityService.instance.getMySubmissionResult(widget.submissionId)
        : ActivityService.instance.getSubmissionDetail(widget.submissionId);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return _SheetFeedbackScaffold(
          child: FutureBuilder<SubmissionDetail>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _SheetError(message: snapshot.error.toString());
              }
              final detail = snapshot.data;
              if (detail == null) {
                return const _SheetError(message: 'Submission not found.');
              }
              return ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  _ReviewHeader(
                    detail: detail,
                    isStudent: widget.studentResult,
                    canGrade: widget.canGrade,
                  ),
                  const SizedBox(height: 16),
                  _ResultSummary(
                    detail: detail,
                    studentResult: widget.studentResult,
                  ),
                  const SizedBox(height: 18),
                  if (widget.studentResult &&
                      detail.type == 'quiz' &&
                      !detail.attemptVisible) ...[
                    _Box(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your quiz was submitted. Attempt review is not available yet.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (detail.type == 'quiz') ...[
                    _QuizReview(
                      detail: detail,
                      showGrade: !widget.studentResult || detail.gradeVisible,
                      showCorrections:
                          !widget.studentResult ||
                          (detail.feedbackVisible && detail.showCorrectAnswers),
                      canGrade: widget.canGrade,
                      onSaved: (updated) {
                        setState(() {
                          _future = Future.value(updated);
                        });
                      },
                    ),
                  ] else ...[
                    _AssignmentReview(detail: detail),
                    if (widget.canGrade) ...[
                      const SizedBox(height: 18),
                      _AssignmentGradingPanel(
                        detail: detail,
                        onSaved: (updated) {
                          setState(() {
                            _future = Future.value(updated);
                          });
                        },
                      ),
                    ],
                  ],
                  if (widget.studentResult &&
                      (!detail.gradeVisible || !detail.feedbackVisible)) ...[
                    const SizedBox(height: 14),
                    _VisibilityNotice(detail: detail),
                  ],
                  if (detail.feedback.isNotEmpty &&
                      (!widget.studentResult || detail.feedbackVisible)) ...[
                    const SizedBox(height: 14),
                    Text('Feedback', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    _Box(
                      child: Text(
                        detail.feedback,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.title,
    required this.items,
    required this.empty,
  });

  final String title;
  final List<StudentActivityItem> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h3),
        const SizedBox(height: 8),
        if (items.isEmpty)
          _MutedText(empty)
        else
          ...items.map(
            (item) => _TimelineRow(
              item: item,
              onOpen: item.submissionId == null
                  ? null
                  : () => showSubmissionDetailSheet(
                      context: context,
                      submissionId: item.submissionId!,
                    ),
            ),
          ),
      ],
    );
  }
}

class _StatsWrap extends StatelessWidget {
  const _StatsWrap({required this.stats, required this.isQuiz});

  final AssessmentStats stats;
  final bool isQuiz;

  @override
  Widget build(BuildContext context) {
    final attemptedLabel = isQuiz ? 'Attempted' : 'Submitted';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetricChip('Students', '${stats.totalStudents}'),
        _MetricChip(attemptedLabel, '${stats.submittedCount}'),
        _MetricChip(
          isQuiz ? 'Not Attempted' : 'Missing',
          '${stats.missingCount}',
        ),
        _MetricChip('Rate', '${(stats.submissionRate * 100).round()}%'),
        _MetricChip(
          'Overdue',
          '${stats.overdueCount}',
          danger: stats.overdueCount > 0,
        ),
        if (stats.averageScore != null)
          _MetricChip('Avg Score', stats.averageScore!.toStringAsFixed(1)),
        if (stats.highestScore != null)
          _MetricChip('High', stats.highestScore!.toStringAsFixed(1)),
        if (stats.lowestScore != null)
          _MetricChip('Low', stats.lowestScore!.toStringAsFixed(1)),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip(this.label, this.value, {this.danger = false});

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;
    final background = danger ? AppColors.errorLight : AppColors.primaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.label.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({
    required this.item,
    required this.actionLabel,
    this.onOpen,
  });

  final AssessmentSubmissionItem item;
  final String actionLabel;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.studentName, style: AppTextStyles.label),
      subtitle: Text(
        '${item.studentEmail} - ${_titleCase(item.status)} - ${item.submittedLabel}',
        style: AppTextStyles.caption,
      ),
      trailing: onOpen == null
          ? _StatusPill(label: _titleCase(item.status), status: item.status)
          : TextButton(onPressed: onOpen, child: Text(actionLabel)),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, this.onOpen});

  final StudentActivityItem item;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        item.type == 'quiz' ? Icons.quiz_rounded : Icons.assignment_rounded,
        color: AppColors.primary,
      ),
      title: Text(item.title, style: AppTextStyles.label),
      subtitle: Text(
        '${item.submittedLabel} - Score ${item.scoreLabel}',
        style: AppTextStyles.caption,
      ),
      trailing: onOpen == null
          ? _StatusPill(label: _titleCase(item.status), status: item.status)
          : TextButton(onPressed: onOpen, child: const Text('Open')),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({
    required this.detail,
    required this.isStudent,
    required this.canGrade,
  });

  final SubmissionDetail detail;
  final bool isStudent;
  final bool canGrade;

  @override
  Widget build(BuildContext context) {
    final icon = detail.type == 'quiz'
        ? Icons.quiz_rounded
        : Icons.assignment_rounded;
    final label = detail.type == 'quiz'
        ? isStudent
              ? 'Quiz Attempt Review'
              : 'Quiz Attempt Grading'
        : isStudent
        ? 'Assignment Submission Review'
        : 'Assignment Submission Grading';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
                if (!isStudent)
                  Text(
                    '${detail.studentName} - ${detail.studentEmail}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (canGrade)
            _HeaderPill(
              label: detail.status == 'graded' ? 'Graded' : 'Needs grading',
            ),
        ],
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.detail, required this.studentResult});

  final SubmissionDetail detail;
  final bool studentResult;

  @override
  Widget build(BuildContext context) {
    final showScore = !studentResult || detail.gradeVisible;
    final quizReviewHidden =
        studentResult && detail.type == 'quiz' && !detail.attemptVisible;
    return _Box(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryTile('Submitted', detail.submittedLabel),
          _SummaryTile('Due', detail.dueLabel),
          _SummaryTile('Timing', detail.isLate ? 'Late' : 'On time'),
          _SummaryTile('Status', _titleCase(detail.status)),
          _SummaryTile(
            'Score',
            quizReviewHidden
                ? 'Review locked'
                : showScore
                ? detail.scoreLabel
                : 'Not visible yet',
          ),
          if (detail.attemptNumber != null)
            _SummaryTile('Attempt', '#${detail.attemptNumber}'),
          if (!studentResult) ...[
            _SummaryTile('Grade visible', detail.gradeVisible ? 'Yes' : 'No'),
            _SummaryTile(
              'Feedback visible',
              detail.feedbackVisible ? 'Yes' : 'No',
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuizReview extends StatefulWidget {
  const _QuizReview({
    required this.detail,
    required this.showGrade,
    required this.showCorrections,
    required this.canGrade,
    required this.onSaved,
  });

  final SubmissionDetail detail;
  final bool showGrade;
  final bool showCorrections;
  final bool canGrade;
  final ValueChanged<SubmissionDetail> onSaved;

  @override
  State<_QuizReview> createState() => _QuizReviewState();
}

class _QuizReviewState extends State<_QuizReview> {
  late final TextEditingController _scoreCtrl;
  late final TextEditingController _feedbackCtrl;
  late final List<TextEditingController> _questionMarkCtrls;
  late final List<TextEditingController> _questionFeedbackCtrls;
  late bool _gradeVisible;
  late bool _feedbackVisible;
  late bool _attemptVisible;
  bool _saving = false;

  SubmissionDetail get detail => widget.detail;

  @override
  void initState() {
    super.initState();
    _scoreCtrl = TextEditingController(
      text: detail.score == null ? '' : detail.score!.toStringAsFixed(1),
    );
    _feedbackCtrl = TextEditingController(text: detail.feedback);
    _gradeVisible = detail.gradeVisible;
    _feedbackVisible = detail.feedbackVisible;
    _attemptVisible = detail.attemptVisible;
    final existing = (detail.gradingDetails['question_grades'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final answers = _answers.length;
    _questionMarkCtrls = List.generate(answers, (index) {
      final grade = index < existing.length ? existing[index]['marks'] : null;
      final question = _questionAt(index);
      final fallback = _automatedMarks(_answers[index], question);
      return TextEditingController(
        text: _markText(_isWritten(question) ? grade ?? fallback : fallback),
      );
    });
    _questionFeedbackCtrls = List.generate(answers, (index) {
      final value = index < existing.length
          ? existing[index]['feedback']
          : null;
      return TextEditingController(text: value?.toString() ?? '');
    });
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _feedbackCtrl.dispose();
    for (final ctrl in _questionMarkCtrls) {
      ctrl.dispose();
    }
    for (final ctrl in _questionFeedbackCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> get _answers {
    return (detail.content['answers'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final answers = _answers;
    if (answers.isEmpty) {
      return const _MutedText('No answer data found for this attempt.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question Review', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        _QuestionMapReview(
          total: answers.length,
          answered: answers
              .where(
                (answer) => (answer['answer']?.toString() ?? '').isNotEmpty,
              )
              .length,
        ),
        const SizedBox(height: 12),
        ...answers.asMap().entries.map((entry) {
          final index = entry.key;
          final answer = entry.value;
          final question = index < detail.questionSchema.length
              ? QuizQuestionModel.fromJson(detail.questionSchema[index])
              : null;
          final rawAnswer = answer['answer'];
          final answerText = _answerText(rawAnswer, question);
          final correctText = _correctAnswerText(answer, question);
          final isCorrect = answer['is_correct'];
          final grade = _questionGrade(detail, index);
          final automated = _automatedMarks(answer, question);
          return _QuestionReviewCard(
            number: index + 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answer['question_text']?.toString() ??
                      question?.questionText ??
                      'Question ${index + 1}',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 8),
                if ((question?.imagePath ?? '').isNotEmpty) ...[
                  _ReviewQuestionImage(path: question!.imagePath),
                  const SizedBox(height: 10),
                ],
                if (_isMatching(question))
                  _MatchingReviewRows(
                    question: question,
                    value: _stringMap(rawAnswer),
                    showCorrections: widget.showCorrections,
                  )
                else
                  _AnswerBlock(label: 'Student answer', value: answerText),
                if (widget.showCorrections && !_isMatching(question))
                  _AnswerBlock(label: 'Correct answer', value: correctText),
                _SmallLine('Automated grade', _markText(automated)),
                _SmallLine(
                  'Available marks',
                  '${answer['marks'] ?? question?.marks ?? '-'}',
                ),
                if (widget.showGrade && grade != null && grade['marks'] != null)
                  _SmallLine('Awarded', '${grade['marks']}'),
                if (widget.showCorrections && isCorrect != null)
                  _SmallLine(
                    'Result',
                    isCorrect == true ? 'Correct' : 'Incorrect',
                  ),
                if (widget.showCorrections &&
                    (question?.explanation ?? '').isNotEmpty)
                  _SmallLine('Explanation', question!.explanation),
                if (widget.showCorrections &&
                    (grade?['feedback']?.toString() ?? '').isNotEmpty)
                  _SmallLine('Correction', grade!['feedback'].toString()),
                if (widget.canGrade) ...[
                  const SizedBox(height: 12),
                  _QuestionGradeInput(
                    controller: _questionMarkCtrls[index],
                    feedbackController: _questionFeedbackCtrls[index],
                    question: question,
                    onManualChanged: (_) => _syncTotal(),
                  ),
                ],
              ],
            ),
          );
        }),
        if (widget.canGrade) ...[
          const SizedBox(height: 12),
          _QuizGradeControls(
            scoreCtrl: _scoreCtrl,
            feedbackCtrl: _feedbackCtrl,
            gradeVisible: _gradeVisible,
            feedbackVisible: _feedbackVisible,
            attemptVisible: _attemptVisible,
            saving: _saving,
            onGradeVisible: (value) => _gradeVisible = value,
            onFeedbackVisible: (value) => _feedbackVisible = value,
            onAttemptVisible: (value) => _attemptVisible = value,
            onSave: _save,
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final validation = _validateQuestionGrades();
    if (validation != null) {
      messenger.showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    setState(() => _saving = true);
    try {
      final questionGrades = List.generate(_questionMarkCtrls.length, (index) {
        final question = _questionAt(index);
        final marks = _isWritten(question)
            ? double.tryParse(_questionMarkCtrls[index].text.trim()) ?? 0
            : _automatedMarks(_answers[index], question);
        return {
          'question_index': index,
          'marks': marks,
          'feedback': _isWritten(question)
              ? _questionFeedbackCtrls[index].text.trim()
              : '',
        };
      });
      final totalScore = questionGrades.fold<double>(
        0,
        (sum, grade) => sum + ((grade['marks'] as num?)?.toDouble() ?? 0),
      );
      _scoreCtrl.text = _markText(totalScore);
      final updated = await ActivityService.instance.gradeSubmission(
        submissionId: detail.id,
        score: totalScore,
        feedback: _feedbackCtrl.text.trim(),
        gradingDetails: {'question_grades': questionGrades},
        gradeVisible: _gradeVisible,
        feedbackVisible: _feedbackVisible,
        attemptVisible: _attemptVisible,
      );
      widget.onSaved(updated);
      messenger.showSnackBar(const SnackBar(content: Text('Grade saved.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _syncTotal() {
    final total = _questionMarkCtrls.fold<double>(
      0,
      (sum, ctrl) => sum + (double.tryParse(ctrl.text.trim()) ?? 0),
    );
    _scoreCtrl.text = _markText(total);
  }

  QuizQuestionModel? _questionAt(int index) {
    return index < detail.questionSchema.length
        ? QuizQuestionModel.fromJson(detail.questionSchema[index])
        : null;
  }

  String? _validateQuestionGrades() {
    for (var index = 0; index < _questionMarkCtrls.length; index++) {
      final question = _questionAt(index);
      if (!_isWritten(question)) {
        continue;
      }
      final marks = double.tryParse(_questionMarkCtrls[index].text.trim());
      if (marks == null) return 'Question ${index + 1} needs a valid grade.';
      final max = (question?.marks ?? 0).toDouble();
      if (marks < 0 || marks > max) {
        return 'Question ${index + 1} grade must be between 0 and ${_markText(max)}.';
      }
      if ((marks * 4).roundToDouble() != marks * 4) {
        return 'Question ${index + 1} grade must use 0.25 increments.';
      }
    }
    return null;
  }
}

class _QuestionMapReview extends StatelessWidget {
  const _QuestionMapReview({required this.total, required this.answered});

  final int total;
  final int answered;

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress', style: AppTextStyles.label),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : answered / total,
                ),
                const SizedBox(height: 6),
                Text(
                  '$answered of $total answered',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              total,
              (index) => Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({required this.number, required this.child});

  final int number;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.violetLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Question $number',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.violet,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              value.isEmpty ? '-' : value,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchingReviewRows extends StatelessWidget {
  const _MatchingReviewRows({
    required this.question,
    required this.value,
    required this.showCorrections,
  });

  final QuizQuestionModel? question;
  final Map<String, String> value;
  final bool showCorrections;

  @override
  Widget build(BuildContext context) {
    final items = question?.items ?? const <String>[];
    final choices = (question?.targets ?? const <String>[]).toSet().toList();
    if (items.isEmpty || choices.isEmpty) {
      return _AnswerBlock(
        label: 'Student answer',
        value: _answerText(value, question),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Student answer', style: AppTextStyles.caption),
          const SizedBox(height: 4),
          ...items.map((item) {
            final selected = choices.contains(value[item]) ? value[item] : null;
            final correct = question?.correctMapping[item];
            final isCorrect = selected != null && selected == correct;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 520;
                  final prompt = Container(
                    width: narrow ? double.infinity : 150,
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(item, style: AppTextStyles.caption),
                  );
                  final dropdown = DropdownButtonFormField<String>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: choices
                        .map(
                          (choice) => DropdownMenuItem(
                            value: choice,
                            child: Text(choice),
                          ),
                        )
                        .toList(),
                    onChanged: null,
                  );
                  final icon = showCorrections
                      ? Icon(
                          isCorrect
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                          size: 18,
                          color: isCorrect ? AppColors.success : AppColors.rose,
                        )
                      : null;
                  final correction =
                      showCorrections && !isCorrect && correct != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Correct: $correct',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null;

                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        prompt,
                        Row(
                          children: [
                            Expanded(child: dropdown),
                            if (icon != null) ...[
                              const SizedBox(width: 8),
                              icon,
                            ],
                          ],
                        ),
                        ?correction,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      prompt,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [dropdown, ?correction],
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: icon,
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _QuizGradeControls extends StatelessWidget {
  const _QuizGradeControls({
    required this.scoreCtrl,
    required this.feedbackCtrl,
    required this.gradeVisible,
    required this.feedbackVisible,
    required this.attemptVisible,
    required this.saving,
    required this.onGradeVisible,
    required this.onFeedbackVisible,
    required this.onAttemptVisible,
    required this.onSave,
  });

  final TextEditingController scoreCtrl;
  final TextEditingController feedbackCtrl;
  final bool gradeVisible;
  final bool feedbackVisible;
  final bool attemptVisible;
  final bool saving;
  final ValueChanged<bool> onGradeVisible;
  final ValueChanged<bool> onFeedbackVisible;
  final ValueChanged<bool> onAttemptVisible;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overall Grade', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: scoreCtrl,
            builder: (context, value, _) {
              return InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Total score',
                  prefixIcon: Icon(Icons.functions_rounded, size: 18),
                ),
                child: Text(value.text.isEmpty ? '0' : value.text),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: feedbackCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Overall feedback'),
          ),
          _VisibilitySwitches(
            gradeVisible: gradeVisible,
            feedbackVisible: feedbackVisible,
            attemptVisible: attemptVisible,
            onGradeVisible: onGradeVisible,
            onFeedbackVisible: onFeedbackVisible,
            onAttemptVisible: onAttemptVisible,
            showAttemptSwitch: true,
          ),
          _SaveGradeButton(saving: saving, onSave: onSave),
        ],
      ),
    );
  }
}

class _QuestionGradeInput extends StatelessWidget {
  const _QuestionGradeInput({
    required this.controller,
    required this.feedbackController,
    required this.question,
    required this.onManualChanged,
  });

  final TextEditingController controller;
  final TextEditingController feedbackController;
  final QuizQuestionModel? question;
  final ValueChanged<String> onManualChanged;

  @override
  Widget build(BuildContext context) {
    final written = _isWritten(question);
    final maxMarks = _markText(question?.marks ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (written)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 116,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onManualChanged,
                  decoration: InputDecoration(
                    labelText: 'Awarded',
                    helperText: '0 to $maxMarks only',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: feedbackController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Correction / feedback',
                  ),
                ),
              ),
            ],
          )
        else
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Awarded automatically',
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
            ),
            child: Text('${controller.text} / $maxMarks'),
          ),
      ],
    );
  }
}

Map<String, dynamic>? _questionGrade(SubmissionDetail detail, int index) {
  final grades = (detail.gradingDetails['question_grades'] as List? ?? [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
  if (index >= grades.length) return null;
  return grades[index];
}

class _AssignmentReview extends StatelessWidget {
  const _AssignmentReview({required this.detail});

  final SubmissionDetail detail;

  @override
  Widget build(BuildContext context) {
    final textAnswer = detail.content['text_answer']?.toString().trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Submitted Work', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        _ReviewSection(
          title: 'Written Response',
          icon: Icons.edit_rounded,
          iconColor: AppColors.amber,
          child: Text(
            textAnswer.isEmpty ? 'No text answer provided.' : textAnswer,
            style: AppTextStyles.body,
          ),
        ),
        if (detail.fileName != null && detail.fileName!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ReviewSection(
            title: 'Uploaded File',
            icon: Icons.attach_file_rounded,
            iconColor: AppColors.emerald,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.fileName!,
                        style: AppTextStyles.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (detail.fileSizeBytes != null)
                        Text(
                          FileUtils.formatBytes(detail.fileSizeBytes!),
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openAttachment(context, detail),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Open'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _ReviewSection(
          title: 'Rubric / Criteria',
          icon: Icons.grade_rounded,
          iconColor: AppColors.violet,
          child: detail.rubric.isEmpty
              ? Text(
                  'No criteria/rubric added.',
                  style: AppTextStyles.bodySmall,
                )
              : Column(
                  children: detail.rubric
                      .map(
                        (row) => _SmallLine(
                          row['criterion']?.toString() ?? 'Criterion',
                          '${row['points'] ?? row['marks'] ?? '-'} pts',
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _openAttachment(
    BuildContext context,
    SubmissionDetail detail,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = await ActivityService.instance.createSubmissionFileUrl(detail);
    if (url == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No file available.')),
      );
      return;
    }
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open attachment.')),
      );
    }
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _VisibilityNotice extends StatelessWidget {
  const _VisibilityNotice({required this.detail});

  final SubmissionDetail detail;

  @override
  Widget build(BuildContext context) {
    final gradeHidden = !detail.gradeVisible;
    final feedbackHidden = !detail.feedbackVisible;
    final message = detail.type == 'quiz'
        ? gradeHidden && feedbackHidden
              ? 'Your attempt was submitted. Results and corrections are not visible yet.'
              : gradeHidden
              ? 'Your attempt was submitted. Grade is not visible yet.'
              : 'Your attempt was submitted. Feedback and corrections are not visible yet.'
        : gradeHidden && feedbackHidden
        ? 'Your submission was received. Grade and feedback are not visible yet.'
        : gradeHidden
        ? 'Your submission was received. Grade is not visible yet.'
        : 'Your submission was received. Feedback is not visible yet.';
    return _Box(
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _VisibilitySwitches extends StatefulWidget {
  const _VisibilitySwitches({
    required this.gradeVisible,
    required this.feedbackVisible,
    this.attemptVisible = false,
    required this.onGradeVisible,
    required this.onFeedbackVisible,
    this.onAttemptVisible,
    this.showAttemptSwitch = false,
  });

  final bool gradeVisible;
  final bool feedbackVisible;
  final bool attemptVisible;
  final ValueChanged<bool> onGradeVisible;
  final ValueChanged<bool> onFeedbackVisible;
  final ValueChanged<bool>? onAttemptVisible;
  final bool showAttemptSwitch;

  @override
  State<_VisibilitySwitches> createState() => _VisibilitySwitchesState();
}

class _VisibilitySwitchesState extends State<_VisibilitySwitches> {
  late bool _gradeVisible;
  late bool _feedbackVisible;
  late bool _attemptVisible;

  @override
  void initState() {
    super.initState();
    _gradeVisible = widget.gradeVisible;
    _feedbackVisible = widget.feedbackVisible;
    _attemptVisible = widget.attemptVisible;
  }

  @override
  void didUpdateWidget(covariant _VisibilitySwitches oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gradeVisible != widget.gradeVisible) {
      _gradeVisible = widget.gradeVisible;
    }
    if (oldWidget.feedbackVisible != widget.feedbackVisible) {
      _feedbackVisible = widget.feedbackVisible;
    }
    if (oldWidget.attemptVisible != widget.attemptVisible) {
      _attemptVisible = widget.attemptVisible;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show grade to student'),
          value: _gradeVisible,
          onChanged: (value) {
            setState(() => _gradeVisible = value);
            widget.onGradeVisible(value);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show feedback/corrections to student'),
          value: _feedbackVisible,
          onChanged: (value) {
            setState(() => _feedbackVisible = value);
            widget.onFeedbackVisible(value);
          },
        ),
        if (widget.showAttemptSwitch)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Allow student attempt review'),
            value: _attemptVisible,
            onChanged: widget.onAttemptVisible == null
                ? null
                : (value) {
                    setState(() => _attemptVisible = value);
                    widget.onAttemptVisible!(value);
                  },
          ),
      ],
    );
  }
}

class _SaveGradeButton extends StatelessWidget {
  const _SaveGradeButton({required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: saving ? null : onSave,
        icon: saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_rounded, size: 16),
        label: Text(saving ? 'Saving...' : 'Save Grade'),
      ),
    );
  }
}

class _AssignmentGradingPanel extends StatefulWidget {
  const _AssignmentGradingPanel({required this.detail, required this.onSaved});

  final SubmissionDetail detail;
  final ValueChanged<SubmissionDetail> onSaved;

  @override
  State<_AssignmentGradingPanel> createState() =>
      _AssignmentGradingPanelState();
}

class _AssignmentGradingPanelState extends State<_AssignmentGradingPanel> {
  late final TextEditingController _scoreCtrl;
  late final TextEditingController _feedbackCtrl;
  late bool _gradeVisible;
  late bool _feedbackVisible;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final detail = widget.detail;
    _scoreCtrl = TextEditingController(
      text: detail.score == null ? '' : detail.score!.toStringAsFixed(1),
    );
    _feedbackCtrl = TextEditingController(text: detail.feedback);
    _gradeVisible = detail.gradeVisible;
    _feedbackVisible = detail.feedbackVisible;
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grading', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          TextField(
            controller: _scoreCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Score / grade'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feedbackCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Overall feedback'),
          ),
          _VisibilitySwitches(
            gradeVisible: _gradeVisible,
            feedbackVisible: _feedbackVisible,
            onGradeVisible: (value) => _gradeVisible = value,
            onFeedbackVisible: (value) => _feedbackVisible = value,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(_saving ? 'Saving...' : 'Save Grade'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final score = double.tryParse(_scoreCtrl.text.trim());
    if (score == null || score < 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid score.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await ActivityService.instance.gradeSubmission(
        submissionId: widget.detail.id,
        score: score,
        feedback: _feedbackCtrl.text.trim(),
        gradingDetails: const {},
        gradeVisible: _gradeVisible,
        feedbackVisible: _feedbackVisible,
        attemptVisible: false,
      );
      widget.onSaved(updated);
      messenger.showSnackBar(const SnackBar(content: Text('Grade saved.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SmallLine extends StatelessWidget {
  const _SmallLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isBad =
        status == 'overdue' || status == 'missing' || status == 'not_attempted';
    final isLate = status == 'late';
    final color = isBad
        ? AppColors.error
        : isLate
        ? AppColors.amber
        : AppColors.success;
    final background = isBad
        ? AppColors.errorLight
        : isLate
        ? AppColors.warningLight
        : AppColors.successLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.bodySmall);
  }
}

class _SheetError extends StatelessWidget {
  const _SheetError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, style: AppTextStyles.bodySmall),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return '-';
  return value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _answerText(dynamic value, QuizQuestionModel? question) {
  if (value is Map) {
    if (value.isEmpty) return '-';
    return value.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }
  if (value is int &&
      question != null &&
      value >= 0 &&
      value < question.options.length) {
    return question.options[value];
  }
  if (value is List) {
    return value.map((item) => _answerText(item, question)).join(', ');
  }
  return value?.toString() ?? '-';
}

String _correctAnswerText(
  Map<String, dynamic> answer,
  QuizQuestionModel? question,
) {
  if (question != null && question.correctMapping.isNotEmpty) {
    return _answerText(question.correctMapping, question);
  }
  if (answer['correct_mapping'] is Map) {
    return _answerText(answer['correct_mapping'], question);
  }
  return question == null
      ? '${answer['correct_option'] ?? '-'}'
      : _answerText(question.correctOption, question);
}

class _ReviewQuestionImage extends StatefulWidget {
  const _ReviewQuestionImage({required this.path});

  final String path;

  @override
  State<_ReviewQuestionImage> createState() => _ReviewQuestionImageState();
}

class _ReviewQuestionImageState extends State<_ReviewQuestionImage> {
  late Future<String?> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = QuizService.instance.createQuestionImageUrl(widget.path);
  }

  @override
  void didUpdateWidget(covariant _ReviewQuestionImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _urlFuture = QuizService.instance.createQuestionImageUrl(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _urlFuture,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(url, fit: BoxFit.cover),
        );
      },
    );
  }
}

bool _isWritten(QuizQuestionModel? question) {
  final type = question?.type.toLowerCase() ?? '';
  return type == 'short answer' || type == 'essay';
}

bool _isMatching(QuizQuestionModel? question) => question?.type == 'Matching';

Map<String, String> _stringMap(dynamic value) {
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }
  return const {};
}

double _automatedMarks(
  Map<String, dynamic> answer,
  QuizQuestionModel? question,
) {
  if (_isWritten(question)) return 0;
  final autoAwarded = answer['auto_awarded_marks'];
  if (autoAwarded is num) return autoAwarded.toDouble();
  final isCorrect = answer['is_correct'] == true;
  final rawMarks = question?.marks ?? (answer['marks'] as num? ?? 0);
  return isCorrect ? rawMarks.toDouble() : 0;
}

String _markText(Object value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value.toString()) ?? 0;
  if (number == number.roundToDouble()) {
    return number.toInt().toString();
  }
  return number.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
}
