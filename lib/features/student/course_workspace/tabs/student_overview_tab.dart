import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../models/course_model.dart';

class StudentOverviewTab extends StatelessWidget {
  final CourseModel course;
  final double progress;

  const StudentOverviewTab({super.key, required this.course, required this.progress});

  static const _latestMaterials = [
    (icon: Icons.picture_as_pdf_rounded, name: 'Lecture 5 - Advanced Topics.pdf', date: 'Mar 20'),
    (icon: Icons.slideshow_rounded, name: 'Week 4 Slides.pptx', date: 'Mar 15'),
    (icon: Icons.video_library_rounded, name: 'Demo Recording.mp4', date: 'Mar 12'),
  ];

  static const _deadlines = [
    (title: 'Quiz 2: Core Principles', due: 'Apr 10', type: 'Quiz', color: AppColors.violet),
    (title: 'Assignment 2: Implementation', due: 'Apr 12', type: 'Assignment', color: AppColors.emerald),
    (title: 'Midterm Review Quiz', due: 'Apr 15', type: 'Quiz', color: AppColors.violet),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgress(),
          const SizedBox(height: 24),
          _buildDescription(),
          const SizedBox(height: 24),
          _buildLatestMaterials(),
          const SizedBox(height: 24),
          _buildUpcomingDeadlines(),
          const SizedBox(height: 24),
          _buildLatestAnnouncement(),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Your Progress', style: AppTextStyles.h3),
              const Spacer(),
              Text(
                '$percent% Complete',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.background,
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ProgressStat(label: 'Materials', value: '${(progress * 12).round()}/12', icon: Icons.book_rounded, color: AppColors.cyan),
              const SizedBox(width: 16),
              _ProgressStat(label: 'Quizzes', value: '2/4', icon: Icons.quiz_rounded, color: AppColors.violet),
              const SizedBox(width: 16),
              _ProgressStat(label: 'Assignments', value: '1/4', icon: Icons.assignment_rounded, color: AppColors.emerald),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('About This Course', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 10),
          Text(course.description, style: AppTextStyles.body),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: course.instructor, icon: Icons.person_rounded),
              _Tag(label: '${course.lecturesCount} Lectures', icon: Icons.book_rounded),
              _Tag(label: '${course.studentsCount} Students', icon: Icons.people_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestMaterials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Latest Materials', actionLabel: 'View all', onAction: () {}),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _latestMaterials.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) {
              final m = _latestMaterials[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(m.icon, color: AppColors.primary, size: 18),
                ),
                title: Text(m.name,
                    style: AppTextStyles.label, overflow: TextOverflow.ellipsis),
                trailing: Text(m.date, style: AppTextStyles.caption),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingDeadlines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Upcoming Deadlines'),
        const SizedBox(height: 12),
        ..._deadlines.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: d.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.title, style: AppTextStyles.label),
                          Text('Due: ${d.due}', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: d.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        d.type,
                        style: AppTextStyles.caption
                            .copyWith(color: d.color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildLatestAnnouncement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Latest Announcement'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.amberLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.push_pin_rounded, color: AppColors.amber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Office hours moved to Thursday',
                        style: AppTextStyles.label),
                    const SizedBox(height: 4),
                    Text(
                      'This week only, office hours will be held on Thursday at 2PM instead of Wednesday.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text('Posted 2 days ago',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.amber)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Tag({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
