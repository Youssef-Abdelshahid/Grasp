import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../models/announcement_model.dart';
import '../../../../services/announcement_service.dart';

class StudentAnnouncementsTab extends StatefulWidget {
  const StudentAnnouncementsTab({
    super.key,
    required this.courseId,
  });

  final String courseId;

  @override
  State<StudentAnnouncementsTab> createState() => _StudentAnnouncementsTabState();
}

class _StudentAnnouncementsTabState extends State<StudentAnnouncementsTab> {
  late Future<List<AnnouncementModel>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture =
        AnnouncementService.instance.getCourseAnnouncements(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AnnouncementModel>>(
      future: _announcementsFuture,
      builder: (context, snapshot) {
        final announcements = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Announcements', style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  Text(
                    '${announcements.length} announcements',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (announcements.isEmpty)
                const EmptyState(
                  icon: Icons.campaign_rounded,
                  title: 'No announcements yet',
                  subtitle:
                      'Announcements from your instructor will appear here.',
                )
              else
                ...announcements.map(
                  (announcement) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnnouncementCard(announcement: announcement),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
  });

  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    final isPinned = announcement.isPinned;

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
                    Text(
                      announcement.title,
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      FileUtils.formatDate(announcement.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(announcement.body, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
