import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../pages/quiz_builder_page.dart';

class QuizzesTab extends StatelessWidget {
  const QuizzesTab({super.key});

  static const _quizzes = [
    (title: 'Quiz 1: Introduction Concepts', questions: 10, status: 'Published', date: 'Mar 10, 2025'),
    (title: 'Quiz 2: Core Principles', questions: 15, status: 'Published', date: 'Mar 18, 2025'),
    (title: 'Midterm Review Quiz', questions: 25, status: 'Draft', date: 'Mar 30, 2025'),
    (title: 'Quiz 3: Advanced Topics', questions: 12, status: 'Draft', date: 'Apr 5, 2025'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActions(context),
          const SizedBox(height: 20),
          _buildAiBanner(context),
          const SizedBox(height: 20),
          _buildQuizList(),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isNarrow = constraints.maxWidth < 480;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quizzes', style: AppTextStyles.h2),
            Text('${_quizzes.length} quizzes total',
                style: AppTextStyles.bodySmall),
          ],
        );

        final aiButton = OutlinedButton.icon(
          onPressed: () => _showAiSheet(context),
          icon: const Icon(Icons.auto_awesome_rounded, size: 14),
          label: const Text('AI Generate'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.violet,
            side: const BorderSide(color: AppColors.violet),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );

        final createButton = ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuizBuilderPage()),
          ),
          icon: const Icon(Icons.add_rounded, size: 14),
          label: const Text('Create Quiz'),
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: aiButton),
                  const SizedBox(width: 8),
                  Expanded(child: createButton),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleBlock),
            aiButton,
            const SizedBox(width: 8),
            createButton,
          ],
        );
      },
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Quiz Generator',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
                Text(
                  'Upload materials and let AI generate quiz questions automatically',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showAiSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.violet,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Try it'),
          ),
        ],
      ),
    );
  }

  void _showAiSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiQuizSheet(),
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
          final isPublished = q.status == 'Published';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
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
                          q.title,
                          style: AppTextStyles.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${q.questions} questions · ${q.date}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? AppColors.successLight
                          : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      q.status,
                      style: AppTextStyles.caption.copyWith(
                        color: isPublished
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        size: 16, color: AppColors.textSecondary),
                    onPressed: () {},
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
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

class _AiQuizSheet extends StatefulWidget {
  const _AiQuizSheet();

  @override
  State<_AiQuizSheet> createState() => _AiQuizSheetState();
}

class _AiQuizSheetState extends State<_AiQuizSheet> {
  String _selectedCount = '10';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.violetLight, shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.violet, size: 28),
        ),
        const SizedBox(height: 16),
        Text('AI Question Generator', style: AppTextStyles.h3, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('How many questions would you like to generate?', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: ['5', '10', '15', '20'].map((n) => ChoiceChip(
          label: Text('$n questions'),
          selected: _selectedCount == n,
          onSelected: (_) => setState(() => _selectedCount = n),
          selectedColor: AppColors.violetLight,
          labelStyle: AppTextStyles.caption.copyWith(
            color: _selectedCount == n ? AppColors.violet : AppColors.textSecondary,
            fontWeight: _selectedCount == n ? FontWeight.w600 : FontWeight.w400,
          ),
        )).toList()),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Generate Questions'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.violet, foregroundColor: Colors.white),
        )),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        )),
      ]),
    );
  }
}
