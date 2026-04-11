import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class QuizAttemptPage extends StatefulWidget {
  final String title;
  const QuizAttemptPage({super.key, required this.title});

  @override
  State<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends State<QuizAttemptPage> with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  int _current = 0;
  final Map<int, int> _answers = {};

  static const _questions = [
    (
      q: 'Which widget rebuilds every time setState() is called?',
      options: ['StatelessWidget', 'StatefulWidget', 'InheritedWidget', 'ProxyWidget'],
      correct: 1,
    ),
    (
      q: 'What function initializes a StatefulWidget\'s state?',
      options: ['build()', 'dispose()', 'initState()', 'didUpdateWidget()'],
      correct: 2,
    ),
    (
      q: 'Which layout widget arranges children in a horizontal line?',
      options: ['Column', 'Stack', 'Row', 'Wrap'],
      correct: 2,
    ),
    (
      q: 'What does "async" keyword indicate in Dart?',
      options: ['Synchronous execution', 'A function returns a Future', 'A deprecated method', 'A generator function'],
      correct: 1,
    ),
    (
      q: 'Which widget is used to display a scrollable list of widgets?',
      options: ['Container', 'ListView', 'Padding', 'GestureDetector'],
      correct: 1,
    ),
    (
      q: 'What is the purpose of the "key" property in Flutter?',
      options: ['Used for API authentication', 'Preserve state during widget tree updates', 'Set widget opacity', 'Define widget color'],
      correct: 1,
    ),
    (
      q: 'Which class provides access to screen dimensions in Flutter?',
      options: ['ThemeData', 'BuildContext', 'MediaQueryData', 'Navigator'],
      correct: 2,
    ),
    (
      q: 'What does Navigator.pop() do?',
      options: ['Opens a new screen', 'Removes the top route', 'Refreshes the current page', 'Logs out the user'],
      correct: 1,
    ),
    (
      q: 'What is a Stream in Dart?',
      options: ['A single async value', 'A sequence of async events', 'A synchronous list', 'An error handler'],
      correct: 1,
    ),
    (
      q: 'Which Dart keyword is used to handle async errors?',
      options: ['catch', 'try-catch', 'await', 'finally'],
      correct: 1,
    ),
  ];

  int _secondsLeft = 600;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 600),
    )..addListener(() {
        setState(() {
          _secondsLeft = (600 * (1 - _timerController.value)).round();
        });
      });
    _timerController.forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  String get _timeString {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isLowTime => _secondsLeft < 120;

  void _submit() {
    _timerController.stop();
    setState(() => _submitted = true);
  }

  int get _score {
    int correct = 0;
    for (final entry in _answers.entries) {
      if (_questions[entry.key].correct == entry.value) correct++;
    }
    return correct;
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildResultScreen(context);

    final q = _questions[_current];
    final chosen = _answers[_current];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showExitDialog(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${_questions.length} questions', style: AppTextStyles.caption),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isLowTime ? AppColors.roseLight : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isLowTime ? AppColors.rose : AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded,
                    size: 14,
                    color: _isLowTime ? AppColors.rose : AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  _timeString,
                  style: AppTextStyles.label.copyWith(
                    color: _isLowTime ? AppColors.rose : AppColors.primary,
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
          _buildProgress(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionCard(q, chosen),
                  const SizedBox(height: 24),
                  _buildQuestionMap(),
                ],
              ),
            ),
          ),
          _buildNavBar(chosen),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final answered = _answers.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_current + 1} of ${_questions.length}',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$answered answered',
                  style: AppTextStyles.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: (_current + 1) / _questions.length,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(dynamic q, int? chosen) {
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
            'Question ${_current + 1}',
            style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 14),
        Text(q.q, style: AppTextStyles.h3),
        const SizedBox(height: 20),
        ...q.options.asMap().entries.map((opt) {
          final isChosen = chosen == opt.key;
          return GestureDetector(
            onTap: () => setState(() => _answers[_current] = opt.key),
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
                      color: isChosen ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isChosen ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: isChosen
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : Center(
                            child: Text(
                              String.fromCharCode(65 + (opt.key as int)),
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opt.value,
                      style: AppTextStyles.body.copyWith(
                        color: isChosen ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isChosen ? FontWeight.w500 : FontWeight.w400,
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

  Widget _buildQuestionMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question Overview', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_questions.length, (i) {
            final isAnswered = _answers.containsKey(i);
            final isCurrent = _current == i;
            return GestureDetector(
              onTap: () => setState(() => _current = i),
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
                    '${i + 1}',
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

  Widget _buildNavBar(int? chosen) {
    final isFirst = _current == 0;
    final isLast = _current == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: isFirst ? null : () => setState(() => _current--),
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            label: const Text('Prev'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const Spacer(),
          if (isLast)
            ElevatedButton.icon(
              onPressed: _answers.length == _questions.length ? _submit : () => _showSubmitDialog(context),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Submit Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => setState(() => _current++),
              icon: const Text('Next'),
              label: const Icon(Icons.chevron_right_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(BuildContext context) {
    final score = _score;
    final total = _questions.length;
    final pct = (score * 100 ~/ total);
    final passed = pct >= 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: Text(widget.title, style: AppTextStyles.label),
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
                  colors: passed
                      ? [AppColors.emerald, const Color(0xFF059669)]
                      : [AppColors.amber, AppColors.rose],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$pct%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(passed ? 'Passed' : 'Review', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(passed ? 'Great job!' : 'Keep practicing!', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text('You answered $score out of $total questions correctly.',
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            Row(
              children: [
                _ResultStat(label: 'Correct', value: '$score', color: AppColors.emerald),
                _ResultStat(label: 'Wrong', value: '${total - score}', color: AppColors.rose),
                _ResultStat(label: 'Score', value: '$pct%', color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 28),
            Text('Answer Review', style: AppTextStyles.h3),
            const SizedBox(height: 14),
            ..._questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final chosen = _answers[i];
              final isCorrect = chosen == q.correct;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect ? AppColors.success : AppColors.rose,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isCorrect ? AppColors.success : AppColors.rose,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Q${i + 1}. ${q.q}', style: AppTextStyles.label, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 8),
                      Text('Your answer: ${chosen != null ? q.options[chosen] : 'Not answered'}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.rose)),
                      Text('Correct: ${q.options[q.correct]}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Quizzes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost if you exit now.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(BuildContext context) {
    final unanswered = _questions.length - _answers.length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: Text(unanswered > 0
            ? 'You have $unanswered unanswered question(s). Submit anyway?'
            : 'Are you sure you want to submit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Review')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _submit(); },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
