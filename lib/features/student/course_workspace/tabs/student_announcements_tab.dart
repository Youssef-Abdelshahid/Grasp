import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class StudentAnnouncementsTab extends StatelessWidget {
  const StudentAnnouncementsTab({super.key});

  static const _announcements = [
    (
      title: 'Office hours moved to Thursday',
      body: 'This week only, office hours will be held on Thursday at 2PM instead of Wednesday. Please bring your questions about the upcoming quiz.',
      date: 'Apr 5, 2025',
      time: '2h ago',
      isPinned: true,
    ),
    (
      title: 'Assignment 2 deadline extended',
      body: 'Due to the upcoming holiday, the Assignment 2 deadline has been extended by 3 days. New deadline: April 10th.',
      date: 'Apr 2, 2025',
      time: '5h ago',
      isPinned: false,
    ),
    (
      title: 'Midterm exam schedule published',
      body: 'The midterm exam schedule has been published on the university portal. Please check the dates and prepare accordingly.',
      date: 'Mar 28, 2025',
      time: 'Yesterday',
      isPinned: false,
    ),
    (
      title: 'New study resources uploaded',
      body: 'Additional study materials including practice problems and sample solutions have been uploaded under Materials.',
      date: 'Mar 25, 2025',
      time: '3 days ago',
      isPinned: false,
    ),
    (
      title: 'Quiz 1 results are now available',
      body: 'Results for Quiz 1 have been published. You can view your score and detailed feedback in the Quizzes tab.',
      date: 'Mar 20, 2025',
      time: '1 week ago',
      isPinned: false,
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
          const SizedBox(height: 16),
          ..._announcements
              .asMap()
              .entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnnouncementCard(
                      title: entry.value.title,
                      body: entry.value.body,
                      date: entry.value.date,
                      time: entry.value.time,
                      isPinned: entry.value.isPinned,
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Announcements', style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text(
          '${_announcements.length} announcements',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String body;
  final String date;
  final String time;
  final bool isPinned;

  const _AnnouncementCard({
    required this.title,
    required this.body,
    required this.date,
    required this.time,
    required this.isPinned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPinned ? AppColors.amberLight : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPinned
              ? AppColors.amber.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPinned
                      ? AppColors.amber.withValues(alpha: 0.15)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.campaign_rounded,
                  color: isPinned ? AppColors.amber : AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(date, style: AppTextStyles.caption),
                        const SizedBox(width: 6),
                        Text('·',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted)),
                        const SizedBox(width: 6),
                        Text(time, style: AppTextStyles.caption),
                        if (isPinned) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Pinned',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
