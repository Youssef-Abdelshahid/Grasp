import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../study/quiz_attempt_page.dart';

class StudentQuizzesTab extends StatelessWidget {
  const StudentQuizzesTab({super.key});

  static const _quizzes = [
    (
      title: 'Quiz 1: Introduction Concepts',
      questions: 10,
      dueDate: 'Mar 10, 2025',
      status: 'Completed',
      score: 90,
    ),
    (
      title: 'Quiz 2: Core Principles',
      questions: 15,
      dueDate: 'Apr 10, 2025',
      status: 'Pending',
      score: 0,
    ),
    (
      title: 'Midterm Review Quiz',
      questions: 25,
      dueDate: 'Apr 15, 2025',
      status: 'Pending',
      score: 0,
    ),
    (
      title: 'Quiz 3: Advanced Topics',
      questions: 12,
      dueDate: 'Apr 30, 2025',
      status: 'Locked',
      score: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildQuizList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final completed = _quizzes.where((q) => q.status == 'Completed').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quizzes', style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text(
          '$completed of ${_quizzes.length} completed',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildQuizList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Quizzes', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        ...List.generate(_quizzes.length, (i) {
          final q = _quizzes[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuizCard(
              title: q.title,
              questions: q.questions,
              dueDate: q.dueDate,
              status: q.status,
              score: q.score,
            ),
          );
        }),
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  final String title;
  final int questions;
  final String dueDate;
  final String status;
  final int score;

  const _QuizCard({
    required this.title,
    required this.questions,
    required this.dueDate,
    required this.status,
    required this.score,
  });

  (Color, Color, String) _statusConfig() {
    switch (status) {
      case 'Completed':
        return (AppColors.success, AppColors.successLight, 'Completed');
      case 'Pending':
        return (AppColors.amber, AppColors.amberLight, 'Pending');
      default:
        return (AppColors.textMuted, AppColors.background, 'Locked');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg, statusLabel) = _statusConfig();
    final isCompleted = status == 'Completed';
    final isPending = status == 'Pending';

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
                child: const Icon(Icons.quiz_rounded,
                    color: AppColors.violet, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$questions questions · Due: $dueDate',
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
                  statusLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (isCompleted) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.emerald, Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Score: $score%',
                        style: AppTextStyles.buttonSmall
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizAttemptPage(title: title),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Review'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (isPending) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizAttemptPage(title: title),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Start Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
