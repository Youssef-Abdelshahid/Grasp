import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class StudentsTab extends StatelessWidget {
  const StudentsTab({super.key});

  static const _students = [
    (name: 'Alice Johnson', email: 'alice.j@university.edu', progress: 0.82, assignments: 5, totalAssignments: 6, quizAvg: 88),
    (name: 'Bob Smith', email: 'bob.s@university.edu', progress: 0.65, assignments: 4, totalAssignments: 6, quizAvg: 72),
    (name: 'Carol Davis', email: 'carol.d@university.edu', progress: 0.91, assignments: 6, totalAssignments: 6, quizAvg: 95),
    (name: 'David Chen', email: 'd.chen@university.edu', progress: 0.50, assignments: 3, totalAssignments: 6, quizAvg: 68),
    (name: 'Emma Wilson', email: 'emma.w@university.edu', progress: 0.78, assignments: 5, totalAssignments: 6, quizAvg: 80),
    (name: 'Frank Miller', email: 'f.miller@university.edu', progress: 0.45, assignments: 2, totalAssignments: 6, quizAvg: 59),
    (name: 'Grace Lee', email: 'g.lee@university.edu', progress: 0.88, assignments: 6, totalAssignments: 6, quizAvg: 91),
    (name: 'Henry Brown', email: 'h.brown@university.edu', progress: 0.72, assignments: 4, totalAssignments: 6, quizAvg: 75),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildSummaryRow(),
        const SizedBox(height: 20),
        _buildStudentList(),
      ]),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Students', style: AppTextStyles.h2),
        Text('${_students.length} enrolled students', style: AppTextStyles.bodySmall),
      ])),
      OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.download_rounded, size: 14),
        label: const Text('Export'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ]);
  }

  Widget _buildSummaryRow() {
    final avgProgress = _students.fold(0.0, (s, e) => s + e.progress) / _students.length;
    final avgQuiz = _students.fold(0, (s, e) => s + e.quizAvg) / _students.length;
    final completed = _students.where((s) => s.assignments == s.totalAssignments).length;

    return Row(children: [
      Expanded(child: _SummaryCard(
        label: 'Avg. Progress',
        value: '${(avgProgress * 100).round()}%',
        color: AppColors.primary,
        bg: AppColors.primaryLight,
        icon: Icons.trending_up_rounded,
      )),
      const SizedBox(width: 10),
      Expanded(child: _SummaryCard(
        label: 'Avg. Quiz Score',
        value: '${avgQuiz.round()}%',
        color: AppColors.violet,
        bg: AppColors.violetLight,
        icon: Icons.quiz_rounded,
      )),
      const SizedBox(width: 10),
      Expanded(child: _SummaryCard(
        label: 'All Submitted',
        value: '$completed/${_students.length}',
        color: AppColors.emerald,
        bg: AppColors.emeraldLight,
        icon: Icons.check_circle_outline_rounded,
      )),
    ]);
  }

  Widget _buildStudentList() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('All Students', style: AppTextStyles.h3),
      const SizedBox(height: 12),
      ...List.generate(_students.length, (i) {
        final s = _students[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _StudentCard(
            name: s.name,
            email: s.email,
            progress: s.progress,
            assignments: s.assignments,
            totalAssignments: s.totalAssignments,
            quizAvg: s.quizAvg,
          ),
        );
      }),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.h3.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String name;
  final String email;
  final double progress;
  final int assignments;
  final int totalAssignments;
  final int quizAvg;

  const _StudentCard({
    required this.name,
    required this.email,
    required this.progress,
    required this.assignments,
    required this.totalAssignments,
    required this.quizAvg,
  });

  Color _progressColor() {
    if (progress >= 0.8) return AppColors.success;
    if (progress >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  Color _quizColor() {
    if (quizAvg >= 80) return AppColors.success;
    if (quizAvg >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _initials() {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = _progressColor();
    final quizColor = _quizColor();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              _initials(),
              style: AppTextStyles.label.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(email, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          _Badge(
            label: '$assignments/$totalAssignments',
            sublabel: 'tasks',
            color: AppColors.emerald,
            bg: AppColors.emeraldLight,
          ),
          const SizedBox(width: 6),
          _Badge(
            label: '$quizAvg%',
            sublabel: 'quiz avg',
            color: quizColor,
            bg: quizColor.withValues(alpha: 0.1),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Progress', style: AppTextStyles.caption),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: AppTextStyles.caption.copyWith(color: progressColor, fontWeight: FontWeight.w600),
              ),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
          ])),
        ]),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.sublabel, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
        Text(sublabel, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }
}
