import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/admin_content_models.dart';
import '../../../services/admin_content_service.dart';

class AdminAnnouncementsPage extends StatefulWidget {
  const AdminAnnouncementsPage({super.key});

  @override
  State<AdminAnnouncementsPage> createState() => _AdminAnnouncementsPageState();
}

class _AdminAnnouncementsPageState extends State<AdminAnnouncementsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  Future<List<AdminAnnouncementItem>>? _future;
  List<AdminCourseItem> _courses = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = AdminContentService.instance.listAnnouncements(
        search: _searchController.text,
      );
    });
    AdminContentService.instance.listCourses().then((courses) {
      if (mounted) setState(() => _courses = courses);
    });
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return FutureBuilder<List<AdminAnnouncementItem>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AdminAnnouncementItem>[];
        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Announcements', style: AppTextStyles.h1),
                  ),
                  Text(
                    '${items.length}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: _load,
                    icon: Icon(Icons.refresh_rounded),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showEdit(),
                    icon: Icon(Icons.add_rounded, size: 16),
                    label: const Text('Create'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search announcements, courses, or body...',
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.hasError)
                Center(
                  child: ElevatedButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                )
              else if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (items.isEmpty)
                _Panel(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No announcements found',
                        style: AppTextStyles.h3,
                      ),
                    ),
                  ),
                )
              else
                _Panel(
                  child: Column(
                    children: items.map((item) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        leading: Icon(
                          item.isPinned
                              ? Icons.push_pin_rounded
                              : Icons.campaign_rounded,
                          color: item.isPinned
                              ? AppColors.amber
                              : AppColors.primary,
                        ),
                        title: Text(item.title, style: AppTextStyles.label),
                        subtitle: Text(
                          '${item.courseCode} - ${item.instructorName} - ${item.createdLabel}',
                          style: AppTextStyles.caption,
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'View',
                              onPressed: () => _showDetails(item),
                              icon: Icon(Icons.visibility_rounded),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _showEdit(item),
                              icon: Icon(Icons.edit_rounded),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => _delete(item),
                              icon: Icon(
                                Icons.delete_rounded,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showDetails(item),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDetails(AdminAnnouncementItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.title, style: AppTextStyles.h2),
              const SizedBox(height: 12),
              Text(
                '${item.courseTitle} - ${item.courseCode}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              Text(item.body, style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }

  void _showEdit([AdminAnnouncementItem? item]) {
    if (_courses.isEmpty) {
      _snack('Create a course before creating announcements.', isError: true);
      return;
    }
    final title = TextEditingController(text: item?.title ?? '');
    final body = TextEditingController(text: item?.body ?? '');
    var courseId = item?.courseId ?? _courses.first.id;
    var isPinned = item?.isPinned ?? false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item == null ? 'Create Announcement' : 'Edit Announcement',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: courseId,
                  items: _courses
                      .map(
                        (course) => DropdownMenuItem(
                          value: course.id,
                          child: Text('${course.title} - ${course.code}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setSheet(() => courseId = value ?? courseId),
                  decoration: const InputDecoration(labelText: 'Course'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: body,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Body'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pinned'),
                  value: isPinned,
                  onChanged: (value) => setSheet(() => isPinned = value),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await AdminContentService.instance.saveAnnouncement(
                              announcementId: item?.id,
                              courseId: courseId,
                              title: title.text,
                              body: body.text,
                              isPinned: isPinned,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            _snack('Announcement saved');
                            _load();
                          } catch (error) {
                            _snack(error.toString(), isError: true);
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(AdminAnnouncementItem item) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Announcement'),
            content: Text('Delete ${item.title}?'),
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
    if (!ok) return;
    try {
      await AdminContentService.instance.deleteAnnouncement(item.id);
      if (!mounted) return;
      _snack('Announcement deleted');
      _load();
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}
