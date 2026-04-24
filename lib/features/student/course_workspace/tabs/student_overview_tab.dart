import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../models/announcement_model.dart';
import '../../../../models/course_model.dart';
import '../../../../models/material_model.dart';
import '../../../../services/announcement_service.dart';
import '../../../../services/material_service.dart';

class StudentOverviewTab extends StatefulWidget {
  const StudentOverviewTab({
    super.key,
    required this.course,
  });

  final CourseModel course;

  @override
  State<StudentOverviewTab> createState() => _StudentOverviewTabState();
}

class _StudentOverviewTabState extends State<StudentOverviewTab> {
  late Future<List<MaterialModel>> _materialsFuture;
  late Future<List<AnnouncementModel>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _materialsFuture =
        MaterialService.instance.getCourseMaterials(widget.course.id);
    _announcementsFuture =
        AnnouncementService.instance.getCourseAnnouncements(widget.course.id);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescription(),
          const SizedBox(height: 24),
          _buildLatestMaterials(),
          const SizedBox(height: 24),
          _buildLatestAnnouncement(),
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
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('About This Course', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.course.description.isEmpty
                ? 'No course description yet.'
                : widget.course.description,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: widget.course.instructor, icon: Icons.person_rounded),
              _Tag(
                label: '${widget.course.lecturesCount} Materials',
                icon: Icons.book_rounded,
              ),
              _Tag(
                label: '${widget.course.studentsCount} Students',
                icon: Icons.people_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestMaterials() {
    return FutureBuilder<List<MaterialModel>>(
      future: _materialsFuture,
      builder: (context, snapshot) {
        final materials = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Latest Materials'),
            const SizedBox(height: 12),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (materials.isEmpty)
              const EmptyState(
                icon: Icons.attach_file_rounded,
                title: 'No materials yet',
                subtitle: 'Your instructor has not uploaded any materials yet.',
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: materials.take(3).length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, index) {
                    final material = materials[index];
                    final color =
                        FileUtils.colorForExtension(material.fileType);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          FileUtils.iconForExtension(material.fileType),
                          color: color,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        material.title,
                        style: AppTextStyles.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        FileUtils.formatDate(material.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLatestAnnouncement() {
    return FutureBuilder<List<AnnouncementModel>>(
      future: _announcementsFuture,
      builder: (context, snapshot) {
        final announcements = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Latest Announcement'),
            const SizedBox(height: 12),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (announcements.isEmpty)
              const EmptyState(
                icon: Icons.campaign_rounded,
                title: 'No announcements yet',
                subtitle: 'New announcements from your instructor will appear here.',
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: announcements.first.isPinned
                      ? AppColors.amberLight
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: announcements.first.isPinned
                        ? AppColors.amber.withValues(alpha: 0.35)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      announcements.first.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.campaign_rounded,
                      color: announcements.first.isPinned
                          ? AppColors.amber
                          : AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcements.first.title,
                            style: AppTextStyles.label,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            announcements.first.body,
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            FileUtils.formatDate(announcements.first.createdAt),
                            style: AppTextStyles.caption.copyWith(
                              color: announcements.first.isPinned
                                  ? AppColors.amber
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon});

  final String label;
  final IconData icon;

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
