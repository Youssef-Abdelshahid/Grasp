import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/announcement_model.dart';
import '../../../models/course_model.dart';
import '../../../models/material_model.dart';
import '../../../services/announcement_service.dart';
import '../../../services/material_service.dart';
import '../../permissions/providers/permissions_provider.dart';

class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key, required this.course});

  final CourseModel course;

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  late Future<List<MaterialModel>> _materialsFuture;
  late Future<List<AnnouncementModel>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _materialsFuture = MaterialService.instance.getCourseMaterials(
      widget.course.id,
    );
    _announcementsFuture = AnnouncementService.instance.getCourseAnnouncements(
      widget.course.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescription(),
          const SizedBox(height: 28),
          _buildAnnouncementsSection(),
          const SizedBox(height: 28),
          _buildRecentMaterials(),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Course Description', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.course.description.isEmpty
                ? 'No course description yet.'
                : widget.course.description,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(
                label: '${widget.course.studentsCount} Students',
                icon: Icons.people_rounded,
              ),
              _Tag(
                label: '${widget.course.lecturesCount} Materials',
                icon: Icons.book_rounded,
              ),
              _Tag(
                label: widget.course.instructorsCountLabel,
                icon: Icons.person_rounded,
              ),
              if (widget.course.semester.isNotEmpty)
                _Tag(
                  label: widget.course.semester,
                  icon: Icons.calendar_month_rounded,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructors(),
        ],
      ),
    );
  }

  Widget _buildInstructors() {
    final instructors = widget.course.instructors;
    if (instructors.isEmpty && widget.course.instructor.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instructors', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: instructors.isEmpty
              ? [_InstructorChip(name: widget.course.instructor, email: '')]
              : instructors
                    .map(
                      (item) =>
                          _InstructorChip(name: item.name, email: item.email),
                    )
                    .toList(),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsSection() {
    return FutureBuilder<List<AnnouncementModel>>(
      future: _announcementsFuture,
      builder: (context, snapshot) {
        final announcements = snapshot.data ?? [];
        final canPost =
            ref.watch(permissionsProvider).valueOrDefaults.postAnnouncements;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Announcements',
              actionLabel: canPost ? 'Add' : null,
              onAction: canPost ? _createAnnouncement : null,
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (announcements.isEmpty)
              const EmptyState(
                icon: Icons.campaign_rounded,
                title: 'No announcements yet',
                subtitle:
                    'Announcements you create for this course will appear here.',
              )
            else
              ...announcements.take(3).map((item) {
                final isPinned = item.isPinned;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isPinned
                          ? AppColors.amberLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isPinned
                            ? AppColors.amber.withValues(alpha: 0.35)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isPinned
                              ? Icons.push_pin_rounded
                              : Icons.campaign_rounded,
                          color: isPinned
                              ? AppColors.amber
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: AppTextStyles.label),
                              const SizedBox(height: 2),
                              Text(item.body, style: AppTextStyles.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                FileUtils.formatDate(item.createdAt),
                                style: AppTextStyles.caption.copyWith(
                                  color: isPinned
                                      ? AppColors.amber
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (canPost)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _editAnnouncement(item);
                                  break;
                                case 'delete':
                                  _deleteAnnouncement(item);
                                  break;
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildRecentMaterials() {
    return FutureBuilder<List<MaterialModel>>(
      future: _materialsFuture,
      builder: (context, snapshot) {
        final materials = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Recent Materials',
              actionLabel: 'Refresh',
              onAction: () {
                setState(() {
                  _materialsFuture = MaterialService.instance
                      .getCourseMaterials(widget.course.id);
                });
              },
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (materials.isEmpty)
              const EmptyState(
                icon: Icons.attach_file_rounded,
                title: 'No materials uploaded',
                subtitle:
                    'Upload the first course material from the Materials tab.',
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
                  itemCount: materials.take(4).length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, index) {
                    final material = materials[index];
                    final color = FileUtils.colorForExtension(
                      material.fileType,
                    );
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
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
                      subtitle: Text(
                        material.fileName,
                        style: AppTextStyles.caption,
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

  Future<void> _createAnnouncement() async {
    final result = await _showAnnouncementDialog();
    if (result == null) {
      return;
    }

    await AnnouncementService.instance.createAnnouncement(
      courseId: widget.course.id,
      title: result.title,
      body: result.body,
      isPinned: result.isPinned,
    );
    _refreshAnnouncements();
  }

  Future<void> _editAnnouncement(AnnouncementModel announcement) async {
    final result = await _showAnnouncementDialog(
      title: announcement.title,
      body: announcement.body,
      isPinned: announcement.isPinned,
    );
    if (result == null) {
      return;
    }

    await AnnouncementService.instance.updateAnnouncement(
      announcementId: announcement.id,
      title: result.title,
      body: result.body,
      isPinned: result.isPinned,
    );
    _refreshAnnouncements();
  }

  Future<void> _deleteAnnouncement(AnnouncementModel announcement) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Announcement'),
            content: Text('Delete "${announcement.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    await AnnouncementService.instance.deleteAnnouncement(announcement.id);
    _refreshAnnouncements();
  }

  Future<_AnnouncementFormResult?> _showAnnouncementDialog({
    String title = '',
    String body = '',
    bool isPinned = false,
  }) async {
    final titleController = TextEditingController(text: title);
    final bodyController = TextEditingController(text: body);
    var pinned = isPinned;

    return showDialog<_AnnouncementFormResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title.isEmpty ? 'New Announcement' : 'Edit Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: pinned,
                    onChanged: (value) =>
                        setDialogState(() => pinned = value ?? false),
                  ),
                  const Text('Pin announcement'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                _AnnouncementFormResult(
                  title: titleController.text.trim(),
                  body: bodyController.text.trim(),
                  isPinned: pinned,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      titleController.dispose();
      bodyController.dispose();
    });
  }

  void _refreshAnnouncements() {
    setState(() {
      _announcementsFuture = AnnouncementService.instance
          .getCourseAnnouncements(widget.course.id);
    });
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

class _InstructorChip extends StatelessWidget {
  const _InstructorChip({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.caption),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementFormResult {
  const _AnnouncementFormResult({
    required this.title,
    required this.body,
    required this.isPinned,
  });

  final String title;
  final String body;
  final bool isPinned;
}
