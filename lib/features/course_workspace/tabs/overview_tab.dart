import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/course_model.dart';

class OverviewTab extends StatelessWidget {
  final CourseModel course;

  const OverviewTab({super.key, required this.course});

  static const _materials = [
    (icon: Icons.picture_as_pdf_rounded, name: 'Lecture 1 - Introduction.pdf', date: 'Mar 1'),
    (icon: Icons.picture_as_pdf_rounded, name: 'Lecture 2 - Core Concepts.pdf', date: 'Mar 8'),
    (icon: Icons.slideshow_rounded, name: 'Week 3 Slides.pptx', date: 'Mar 15'),
    (icon: Icons.video_library_rounded, name: 'Demo Recording.mp4', date: 'Mar 20'),
  ];

  static const _tasks = [
    (title: 'Quiz 1', deadline: 'Apr 10', type: 'Quiz', color: AppColors.violet),
    (title: 'Assignment 2', deadline: 'Apr 15', type: 'Assignment', color: AppColors.emerald),
    (title: 'Midterm Exam', deadline: 'Apr 22', type: 'Exam', color: AppColors.rose),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescription(),
          const SizedBox(height: 28),
          const _AnnouncementsSection(),
          const SizedBox(height: 28),
          _buildRecentMaterials(),
          const SizedBox(height: 28),
          _buildUpcomingTasks(),
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
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Course Description', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 12),
          Text(course.description, style: AppTextStyles.body),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: '${course.studentsCount} Students', icon: Icons.people_rounded),
              _Tag(label: '${course.lecturesCount} Lectures', icon: Icons.book_rounded),
              _Tag(label: course.instructor, icon: Icons.person_rounded),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildRecentMaterials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Materials',
          actionLabel: 'View all',
          onAction: () {},
        ),
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
            itemCount: _materials.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) {
              final m = _materials[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(m.icon, color: AppColors.primary, size: 18),
                ),
                title: Text(m.name,
                    style: AppTextStyles.label,
                    overflow: TextOverflow.ellipsis),
                trailing: Text(m.date, style: AppTextStyles.caption),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Upcoming Deadlines'),
        const SizedBox(height: 12),
        ..._tasks.map((t) => Padding(
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
                        color: t.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: AppTextStyles.label),
                          Text('Due: ${t.deadline}',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        t.type,
                        style: AppTextStyles.caption
                            .copyWith(color: t.color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )),
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

class _AnnouncementItem {
  String title;
  String body;
  String time;
  bool isPinned;

  _AnnouncementItem({
    required this.title,
    required this.body,
    required this.time,
    this.isPinned = false,
  });
}

class _AnnouncementsSection extends StatefulWidget {
  const _AnnouncementsSection();

  @override
  State<_AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<_AnnouncementsSection> {
  final List<_AnnouncementItem> _announcements = [
    _AnnouncementItem(
      title: 'Office hours moved to Thursday',
      body: 'This week only, office hours will be held on Thursday at 2PM instead of Wednesday.',
      time: 'Posted 2 days ago',
      isPinned: true,
    ),
    _AnnouncementItem(
      title: 'Assignment 2 deadline extended',
      body: 'Due to the upcoming holiday, the Assignment 2 deadline has been extended by 3 days.',
      time: 'Posted 5 days ago',
    ),
  ];

  Future<void> _showAddDialog(BuildContext context) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _AnnouncementDialog(),
    );
    if (!mounted) return;
    if (result != null && result.$1.isNotEmpty) {
      setState(() => _announcements.insert(0, _AnnouncementItem(
        title: result.$1,
        body: result.$2,
        time: 'Just now',
      )));
    }
  }

  Future<void> _showEditDialog(BuildContext context, int index) async {
    final item = _announcements[index];
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _AnnouncementDialog(initialTitle: item.title, initialBody: item.body),
    );
    if (!mounted) return;
    if (result != null && result.$1.isNotEmpty) {
      setState(() {
        _announcements[index].title = result.$1;
        _announcements[index].body = result.$2;
      });
    }
  }

  void _delete(int index) => setState(() => _announcements.removeAt(index));
  void _togglePin(int index) => setState(() => _announcements[index].isPinned = !_announcements[index].isPinned);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(
        title: 'Announcements',
        actionLabel: 'Add',
        onAction: () => _showAddDialog(context),
      ),
      const SizedBox(height: 12),
      if (_announcements.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(child: Column(children: [
            const Icon(Icons.campaign_rounded, color: AppColors.textMuted, size: 28),
            const SizedBox(height: 8),
            Text('No announcements yet', style: AppTextStyles.bodySmall),
          ])),
        )
      else
        ...List.generate(_announcements.length, (i) {
          final item = _announcements[i];
          final isPinned = item.isPinned;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isPinned ? AppColors.amberLight : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPinned ? AppColors.amber.withValues(alpha: 0.35) : AppColors.border,
                ),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.campaign_rounded,
                  color: isPinned ? AppColors.amber : AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(item.body, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    item.time,
                    style: AppTextStyles.caption.copyWith(
                      color: isPinned ? AppColors.amber : AppColors.textMuted,
                    ),
                  ),
                ])),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: Icon(
                      isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => _togglePin(i),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                    onPressed: () => _showEditDialog(context, i),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textSecondary),
                    onPressed: () => _delete(i),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ]),
              ]),
            ),
          );
        }),
    ]);
  }
}

class _AnnouncementDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialBody;

  const _AnnouncementDialog({this.initialTitle, this.initialBody});

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _bodyCtrl = TextEditingController(text: widget.initialBody ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTitle != null ? 'Edit Announcement' : 'New Announcement'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
        const SizedBox(height: 12),
        TextField(controller: _bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Message')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, (_titleCtrl.text, _bodyCtrl.text)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
