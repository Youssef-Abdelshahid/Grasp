import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../models/quiz_model.dart';
import '../../../models/quiz_question_model.dart';
import '../../../models/submission_model.dart';
import '../../../services/quiz_service.dart';
import '../../../services/permissions_service.dart';
import '../../../services/submission_service.dart';

class QuizAttemptPage extends StatefulWidget {
  const QuizAttemptPage({super.key, required this.quiz});

  final QuizModel quiz;

  @override
  State<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends State<QuizAttemptPage> {
  late final List<QuizQuestionModel> _questions;
  late final List<TextEditingController> _shortAnswerControllers;
  final Map<int, dynamic> _answers = {};
  late final Stopwatch _stopwatch;
  Timer? _timer;

  int _current = 0;
  int? _secondsLeft;
  bool _isSubmitting = false;
  SubmissionModel? _submission;

  @override
  void initState() {
    super.initState();
    _questions = widget.quiz.questionSchema
        .map(QuizQuestionModel.fromJson)
        .toList();
    _shortAnswerControllers = List.generate(
      _questions.length,
      (_) => TextEditingController(),
    );
    _stopwatch = Stopwatch()..start();
    if (widget.quiz.durationMinutes != null) {
      _secondsLeft = widget.quiz.durationMinutes! * 60;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _submission != null) {
          return;
        }
        setState(() {
          if (_secondsLeft == null || _secondsLeft == 0) {
            _timer?.cancel();
            _submit();
            return;
          }
          _secondsLeft = _secondsLeft! - 1;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    for (final controller in _shortAnswerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submission != null) {
      return _ResultScreen(
        quiz: widget.quiz,
        questions: _questions,
        answers: _answers,
        submission: _submission!,
      );
    }

    final question = _questions[_current];
    final answer = _answers[_current];
    final answeredCount = _answers.entries
        .where((entry) => _hasAnswer(entry.value))
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _isSubmitting ? null : () => _showExitDialog(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.quiz.title,
              style: AppTextStyles.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_questions.length} questions',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          if (_secondsLeft != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (_secondsLeft ?? 0) < 120
                    ? AppColors.roseLight
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_secondsLeft ?? 0) < 120
                      ? AppColors.rose
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_rounded,
                    size: 14,
                    color: (_secondsLeft ?? 0) < 120
                        ? AppColors.rose
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _timeString(_secondsLeft!),
                    style: AppTextStyles.label.copyWith(
                      color: (_secondsLeft ?? 0) < 120
                          ? AppColors.rose
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          _ProgressHeader(
            current: _current,
            total: _questions.length,
            answered: answeredCount,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuestionCard(
                    index: _current,
                    question: question,
                    answer: answer,
                    showMarks: widget.quiz.showQuestionMarks,
                    shortAnswerController: _shortAnswerControllers[_current],
                    onSelectOption: (value) {
                      setState(() => _answers[_current] = value);
                    },
                    onShortAnswerChanged: (value) {
                      _answers[_current] = value;
                    },
                    onMappingChanged: (value) {
                      setState(() => _answers[_current] = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  _QuestionMap(
                    total: _questions.length,
                    current: _current,
                    answers: _answers,
                    onSelect: (value) => setState(() => _current = value),
                  ),
                ],
              ),
            ),
          ),
          _NavigationBar(
            isFirst: _current == 0,
            isLast: _current == _questions.length - 1,
            isSubmitting: _isSubmitting,
            onPrevious: () => setState(() => _current--),
            onNext: () => setState(() => _current++),
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  bool _hasAnswer(dynamic value) {
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    if (value is Map) {
      return value.values.any((item) => item.toString().trim().isNotEmpty);
    }
    return value != null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final submission = await SubmissionService.instance.submitQuiz(
        quiz: widget.quiz,
        answers: _answers,
        elapsedSeconds: _stopwatch.elapsed.inSeconds,
      );
      _timer?.cancel();
      _stopwatch.stop();
      if (!mounted) {
        return;
      }
      setState(() => _submission = submission);
    } on SubmissionException catch (error) {
      _showMessage(error.message);
    } on PermissionsException catch (error) {
      _showMessage(error.message);
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted && _submission == null) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Your current progress will be lost if you leave now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _timeString(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.answered,
  });

  final int current;
  final int total;
  final int answered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${current + 1} of $total',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$answered answered',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: (current + 1) / total,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.answer,
    required this.showMarks,
    required this.shortAnswerController,
    required this.onSelectOption,
    required this.onShortAnswerChanged,
    required this.onMappingChanged,
  });

  final int index;
  final QuizQuestionModel question;
  final dynamic answer;
  final bool showMarks;
  final TextEditingController shortAnswerController;
  final ValueChanged<int> onSelectOption;
  final ValueChanged<String> onShortAnswerChanged;
  final ValueChanged<Map<String, String>> onMappingChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Question ${index + 1}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(question.questionText, style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(
          showMarks
              ? '${question.type} - ${_markText(question.marks)} mark${question.marks == 1 ? '' : 's'}'
              : question.type,
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 20),
        if (question.imagePath.isNotEmpty) ...[
          _QuestionImage(path: question.imagePath),
          const SizedBox(height: 16),
        ],
        if (_isWritten(question.type))
          TextField(
            controller: shortAnswerController,
            maxLines: 5,
            onChanged: onShortAnswerChanged,
            decoration: const InputDecoration(
              hintText: 'Write your answer here...',
            ),
          )
        else if (_isMappingType(question.type))
          _MappingAnswerFields(
            question: question,
            value: _stringMap(answer),
            onChanged: onMappingChanged,
          )
        else
          ...List.generate(question.options.length, (optionIndex) {
            final isChosen = answer == optionIndex;
            return GestureDetector(
              onTap: () => onSelectOption(optionIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isChosen ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChosen ? AppColors.primary : AppColors.border,
                    width: isChosen ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isChosen
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isChosen
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: isChosen
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          : Center(
                              child: Text(
                                String.fromCharCode(65 + optionIndex),
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.options[optionIndex],
                        style: AppTextStyles.body.copyWith(
                          color: isChosen
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: isChosen
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _MappingAnswerFields extends StatelessWidget {
  const _MappingAnswerFields({
    required this.question,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
    this.showCorrectness = false,
  });

  final QuizQuestionModel question;
  final Map<String, String> value;
  final ValueChanged<Map<String, String>> onChanged;
  final bool readOnly;
  final bool showCorrectness;

  @override
  Widget build(BuildContext context) {
    final choices = question.targets.toSet().toList();
    if (choices.isEmpty || question.items.isEmpty) {
      return Text(
        'This question is not fully configured.',
        style: AppTextStyles.bodySmall,
      );
    }
    return Column(
      children: question.items.map((item) {
        final selected = choices.contains(value[item]) ? value[item] : null;
        final isCorrect = question.correctMapping[item] == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 480;
              final prompt = Container(
                width: narrow ? double.infinity : 150,
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  item,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
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
                      (choice) =>
                          DropdownMenuItem(value: choice, child: Text(choice)),
                    )
                    .toList(),
                onChanged: readOnly
                    ? null
                    : (choice) {
                        final next = {...value};
                        if (choice == null) {
                          next.remove(item);
                        } else {
                          next[item] = choice;
                        }
                        onChanged(next);
                      },
              );
              final statusIcon = showCorrectness
                  ? Icon(
                      isCorrect
                          ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined,
                      size: 18,
                      color: isCorrect ? AppColors.success : AppColors.rose,
                    )
                  : null;
              final correction =
                  showCorrectness &&
                      !isCorrect &&
                      question.correctMapping[item] != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Correct: ${question.correctMapping[item]}',
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
                        if (statusIcon != null) ...[
                          const SizedBox(width: 8),
                          statusIcon,
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
                  if (statusIcon != null) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: statusIcon,
                    ),
                  ],
                ],
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _QuestionImage extends StatelessWidget {
  const _QuestionImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: QuizService.instance.createQuestionImageUrl(path),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _QuestionMap extends StatelessWidget {
  const _QuestionMap({
    required this.total,
    required this.current,
    required this.answers,
    required this.onSelect,
  });

  final int total;
  final int current;
  final Map<int, dynamic> answers;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question Overview',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(total, (index) {
            final isAnswered =
                answers[index] != null &&
                ((answers[index] is! String) ||
                    (answers[index] as String).trim().isNotEmpty);
            final isCurrent = current == index;
            return GestureDetector(
              onTap: () => onSelect(index),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : isAnswered
                      ? AppColors.primaryLight
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primary
                        : isAnswered
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.caption.copyWith(
                      color: isCurrent
                          ? Colors.white
                          : isAnswered
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.isFirst,
    required this.isLast,
    required this.isSubmitting,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final bool isFirst;
  final bool isLast;
  final bool isSubmitting;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: isFirst || isSubmitting ? null : onPrevious,
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            label: const Text('Prev'),
          ),
          const Spacer(),
          if (isLast)
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 16),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : onNext,
              icon: const Text('Next'),
              label: const Icon(Icons.chevron_right_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  const _ResultScreen({
    required this.quiz,
    required this.questions,
    required this.answers,
    required this.submission,
  });

  final QuizModel quiz;
  final List<QuizQuestionModel> questions;
  final Map<int, dynamic> answers;
  final SubmissionModel submission;

  @override
  Widget build(BuildContext context) {
    final hasScore = submission.status == 'graded' && submission.score != null;
    final scoreValue = submission.score ?? 0;
    final totalMarks = questions.fold<double>(
      0,
      (sum, question) => sum + question.marks,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: Text(quiz.title, style: AppTextStyles.label),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: hasScore
                      ? [AppColors.emerald, const Color(0xFF059669)]
                      : [AppColors.primary, AppColors.violet],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasScore ? _markText(scoreValue) : 'Sent',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    hasScore ? 'of ${_markText(totalMarks)}' : 'Pending review',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasScore ? 'Submitted successfully' : 'Submission received',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 8),
            Text(
              hasScore
                  ? 'Your quiz was auto-scored and saved to your submission history.'
                  : 'This quiz includes answers that may need manual review before a final score appears.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _ResultDetail(
                    label: 'Submitted',
                    value: FileUtils.formatDateTime(submission.submittedAt),
                  ),
                  const SizedBox(height: 10),
                  _ResultDetail(
                    label: 'Attempt',
                    value: '#${submission.attemptNumber}',
                  ),
                  const SizedBox(height: 10),
                  _ResultDetail(
                    label: 'Questions',
                    value: '${questions.length}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (hasScore && quiz.showCorrectAnswers)
              ...List.generate(questions.length, (index) {
                final question = questions[index];
                final answer = answers[index];
                final isShortAnswer = _isWritten(question.type);
                final isCorrect = isShortAnswer
                    ? false
                    : _isMappingType(question.type)
                    ? _mappingIsCorrect(question, answer)
                    : answer == question.correctOption;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isShortAnswer
                          ? AppColors.border
                          : isCorrect
                          ? AppColors.success
                          : AppColors.rose,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q${index + 1}. ${question.questionText}',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isShortAnswer
                            ? 'Submitted for manual review'
                            : 'Your answer: ${_studentAnswerText(question, answer)}',
                        style: AppTextStyles.caption,
                      ),
                      if (!isShortAnswer && !_isMappingType(question.type))
                        Text(
                          'Correct answer: ${question.options[question.correctOption]}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (_isMappingType(question.type)) ...[
                        const SizedBox(height: 8),
                        _MappingAnswerFields(
                          question: question,
                          value: _stringMap(answer),
                          readOnly: true,
                          showCorrectness: true,
                          onChanged: (_) {},
                        ),
                      ],
                    ],
                  ),
                );
              }),
            if (hasScore && !quiz.showCorrectAnswers) ...[
              const SizedBox(height: 8),
              Text(
                'Your quiz was submitted. Correct answers and explanations are not visible yet.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, submission),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Quizzes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultDetail extends StatelessWidget {
  const _ResultDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label:', style: AppTextStyles.caption),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

bool _isWritten(String type) =>
    type.toLowerCase() == 'short answer' || type.toLowerCase() == 'essay';

bool _isMappingType(String type) {
  return type == 'Matching';
}

Map<String, String> _stringMap(dynamic value) {
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }
  return const {};
}

String _markText(num value) {
  final number = value.toDouble();
  if (number == number.roundToDouble()) {
    return number.toInt().toString();
  }
  return number.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
}

bool _mappingIsCorrect(QuizQuestionModel question, dynamic answer) {
  final submitted = _stringMap(answer);
  if (question.correctMapping.isEmpty) return false;
  return question.correctMapping.entries.every(
    (entry) => submitted[entry.key] == entry.value,
  );
}

String _studentAnswerText(QuizQuestionModel question, dynamic answer) {
  if (_isMappingType(question.type)) {
    return _mappingText(_stringMap(answer));
  }
  if (answer is int && answer >= 0 && answer < question.options.length) {
    return question.options[answer];
  }
  return answer?.toString() ?? 'Not answered';
}

String _mappingText(Map<String, String> value) {
  if (value.isEmpty) return 'Not answered';
  return value.entries
      .map((entry) => '${entry.key}: ${entry.value}')
      .join(', ');
}
