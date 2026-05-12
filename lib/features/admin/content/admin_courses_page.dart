import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/activity_models.dart';
import '../../../models/admin_content_models.dart';
import '../../../models/admin_models.dart';
import '../../../services/activity_service.dart';
import '../../../services/admin_content_service.dart';
import '../../../services/admin_service.dart';
import '../../../services/material_service.dart';
import '../../activity/activity_sheets.dart';
import '../../course_workspace/pages/assignment_builder_page.dart';
import '../../course_workspace/pages/quiz_builder_page.dart';

class AdminCoursesPage extends StatefulWidget {
  const AdminCoursesPage({super.key});

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _status;
  Future<List<AdminCourseItem>>? _future;

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
      _future = AdminContentService.instance.listCourses(
        search: _searchController.text,
        status: _status,
      );
    });
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _archive(AdminCourseItem course) async {
    final ok = await _confirm('Archive Course', 'Archive ${course.title}?');
    if (!ok) return;
    try {
      await AdminContentService.instance.archiveCourse(course.id);
      if (!mounted) return;
      _snack('Course archived');
      _load();
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
  }

  Future<void> _delete(AdminCourseItem course) async {
    final ok = await _confirm(
      'Delete Course',
      'Permanently delete ${course.title}? Related course records will be removed from the active system.',
    );
    if (!ok) return;
    try {
      await AdminContentService.instance.deleteCourseSafely(course.id);
      if (!mounted) return;
      _snack('Course deleted');
      _load();
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
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

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return FutureBuilder<List<AdminCourseItem>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AdminCourseItem>[];
        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: 'Courses',
                subtitle: 'Manage every course across the platform',
                count: items.length,
                onRefresh: _load,
                actionLabel: 'Create',
                onAction: () => _showCourseSheet(),
              ),
              const SizedBox(height: 16),
              _Filters(
                controller: _searchController,
                hint: 'Search courses, codes, or instructors...',
                onChanged: _search,
                status: _status,
                statuses: const ['draft', 'published', 'archived'],
                onStatus: (value) {
                  _status = value;
                  _load();
                },
              ),
              const SizedBox(height: 16),
              if (snapshot.hasError)
                _Error(onRetry: _load)
              else if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (items.isEmpty)
                const _Empty(title: 'No courses found')
              else
                _CourseList(
                  items: items,
                  isWide: isWide,
                  onView: _showCourseDetails,
                  onEdit: _showCourseSheet,
                  onArchive: _archive,
                  onDelete: _delete,
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCourseSheet([AdminCourseItem? course]) async {
    final instructors = await AdminService.instance.listUsers(
      role: AppRole.instructor,
    );
    if (!mounted) return;

    final title = TextEditingController(text: course?.title ?? '');
    final code = TextEditingController(text: course?.code ?? '');
    final description = TextEditingController(text: course?.description ?? '');
    final semester = TextEditingController(text: course?.semester ?? '');
    final maxStudents = TextEditingController(
      text: '${course?.maxStudents ?? 50}',
    );
    final selectedInstructorIds = course == null
        ? <String>{}
        : await _loadAssignedInstructorIds(course);
    if (!mounted) return;
    var status = course?.status ?? 'draft';
    var allowSelfEnrollment = course?.allowSelfEnrollment ?? false;
    var isVisible = course?.isVisible ?? false;

    await showModalBottomSheet<void>(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course == null ? 'Create Course' : 'Edit Course',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 16),
                _Field(label: 'Title', controller: title),
                const SizedBox(height: 12),
                _Field(label: 'Code', controller: code),
                const SizedBox(height: 12),
                _Field(
                  label: 'Description',
                  controller: description,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _Field(label: 'Semester', controller: semester),
                const SizedBox(height: 12),
                _Field(
                  label: 'Max Students',
                  controller: maxStudents,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Text('Instructors', style: AppTextStyles.label),
                const SizedBox(height: 6),
                _InstructorSelector(
                  instructors: instructors,
                  selectedIds: selectedInstructorIds,
                  onChanged: (ids) {
                    setSheet(() {
                      selectedInstructorIds
                        ..clear()
                        ..addAll(ids);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text('Status', style: AppTextStyles.label),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: const ['draft', 'published', 'archived']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setSheet(() => status = value ?? status),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible to students'),
                  value: isVisible,
                  onChanged: (value) => setSheet(() => isVisible = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow self enrollment'),
                  value: allowSelfEnrollment,
                  onChanged: (value) =>
                      setSheet(() => allowSelfEnrollment = value),
                ),
                const SizedBox(height: 16),
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
                          if (selectedInstructorIds.isEmpty) {
                            _snack(
                              'Please assign at least one instructor to this course.',
                              isError: true,
                            );
                            return;
                          }
                          try {
                            await AdminContentService.instance.saveCourse(
                              courseId: course?.id,
                              title: title.text,
                              code: code.text,
                              description: description.text,
                              instructorId: selectedInstructorIds.first,
                              instructorIds: selectedInstructorIds.toList(),
                              status: status,
                              semester: semester.text,
                              maxStudents: int.tryParse(maxStudents.text) ?? 50,
                              allowSelfEnrollment: allowSelfEnrollment,
                              isVisible: isVisible,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            _snack('Course saved');
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

  Future<Set<String>> _loadAssignedInstructorIds(AdminCourseItem course) async {
    try {
      final members = await AdminContentService.instance.getCourseMembers(
        course.id,
      );
      return members.instructors.map((user) => user.id).toSet();
    } catch (_) {
      return course.instructors.map((user) => user.id).toSet();
    }
  }

  void _showCourseDetails(AdminCourseItem course) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailSheet(
                title: course.title,
                rows: {
                  'Code': course.code,
                  'Status': course.statusLabel,
                  'Instructors': course.instructorName,
                  'Students': '${course.studentsCount}',
                  'Materials': '${course.materialsCount}',
                  'Quizzes': '${course.quizzesCount}',
                  'Assignments': '${course.assignmentsCount}',
                  'Announcements': '${course.announcementsCount}',
                  'Created': course.createdLabel,
                  'Description': course.description.isEmpty
                      ? 'No description'
                      : course.description,
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showMembers(course),
                    icon: Icon(Icons.group_rounded, size: 16),
                    label: const Text('Members'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _uploadMaterial(course),
                    icon: Icon(Icons.upload_rounded, size: 16),
                    label: const Text('Material'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _createQuiz(course),
                    icon: Icon(Icons.quiz_rounded, size: 16),
                    label: const Text('Quiz'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _createAssignment(course),
                    icon: Icon(Icons.assignment_rounded, size: 16),
                    label: const Text('Assignment'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _createAnnouncement(course),
                    icon: Icon(Icons.campaign_rounded, size: 16),
                    label: const Text('Announcement'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMembers(AdminCourseItem course) async {
    Navigator.pop(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CourseMembersSheet(
        course: course,
        onChanged: () {
          _load();
        },
      ),
    );
  }

  Future<void> _uploadMaterial(AdminCourseItem course) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final selected = result.files.single;
    final title = TextEditingController(text: selected.name.split('.').first);
    final description = TextEditingController();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Upload to ${course.code}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await MaterialService.instance.uploadMaterial(
                  courseId: course.id,
                  file: selected,
                  title: title.text,
                  description: description.text,
                );
                await AdminContentService.instance.logAdminAction(
                  action: 'material_uploaded',
                  summary: 'Uploaded material to ${course.code}: ${title.text}',
                  metadata: {'course_id': course.id},
                );
                if (!mounted) return;
                Navigator.pop(context);
                _snack('Material uploaded');
                _load();
              } catch (error) {
                _snack(error.toString(), isError: true);
              }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _createQuiz(AdminCourseItem course) async {
    Navigator.pop(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizBuilderPage(courseId: course.id)),
    );
    if (result != null) {
      await AdminContentService.instance.logAdminAction(
        action: 'quiz_created',
        summary: 'Created quiz in ${course.code} from admin',
        metadata: {'course_id': course.id},
      );
      _load();
    }
  }

  Future<void> _createAssignment(AdminCourseItem course) async {
    Navigator.pop(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentBuilderPage(courseId: course.id),
      ),
    );
    if (result != null) {
      await AdminContentService.instance.logAdminAction(
        action: 'assignment_created',
        summary: 'Created assignment in ${course.code} from admin',
        metadata: {'course_id': course.id},
      );
      _load();
    }
  }

  void _createAnnouncement(AdminCourseItem course) {
    Navigator.pop(context);
    final title = TextEditingController();
    final body = TextEditingController();
    var pinned = false;
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
                  'Announcement for ${course.code}',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 16),
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
                  value: pinned,
                  onChanged: (value) => setSheet(() => pinned = value),
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
                              courseId: course.id,
                              title: title.text,
                              body: body.text,
                              isPinned: pinned,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            _snack('Announcement created');
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
}

class _CourseList extends StatelessWidget {
  const _CourseList({
    required this.items,
    required this.isWide,
    required this.onView,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final List<AdminCourseItem> items;
  final bool isWide;
  final ValueChanged<AdminCourseItem> onView;
  final ValueChanged<AdminCourseItem> onEdit;
  final ValueChanged<AdminCourseItem> onArchive;
  final ValueChanged<AdminCourseItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: items.map((item) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            title: Text(
              '${item.title} - ${item.code}',
              style: AppTextStyles.label,
            ),
            subtitle: Text(
              '${item.instructorSummary} - ${item.studentsCount} students - ${item.statusLabel}',
              style: AppTextStyles.caption,
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'View',
                  onPressed: () => onView(item),
                  icon: Icon(Icons.visibility_rounded),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => onEdit(item),
                  icon: Icon(Icons.edit_rounded),
                ),
                IconButton(
                  tooltip: 'Archive',
                  onPressed: () => onArchive(item),
                  icon: Icon(
                    Icons.archive_rounded,
                    color: AppColors.amber,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete safely',
                  onPressed: () => onDelete(item),
                  icon: Icon(
                    Icons.delete_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            onTap: () => onView(item),
          );
        }).toList(),
      ),
    );
  }
}

class _CourseMembersSheet extends StatefulWidget {
  const _CourseMembersSheet({required this.course, required this.onChanged});

  final AdminCourseItem course;
  final VoidCallback onChanged;

  @override
  State<_CourseMembersSheet> createState() => _CourseMembersSheetState();
}

class _CourseMembersSheetState extends State<_CourseMembersSheet> {
  late Future<AdminCourseMembers> _future;
  late Future<List<CourseStudentActivity>> _activityFuture;
  List<AdminUser> _instructors = const [];
  List<AdminUser> _students = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = AdminContentService.instance.getCourseMembers(widget.course.id);
    _activityFuture = ActivityService.instance.getCourseStudentsActivity(
      widget.course.id,
    );
    AdminService.instance.listUsers(role: AppRole.instructor).then((users) {
      if (mounted) setState(() => _instructors = users);
    });
    AdminService.instance.listUsers(role: AppRole.student).then((users) {
      if (mounted) setState(() => _students = users);
    });
  }

  void _refresh() {
    setState(_load);
    widget.onChanged();
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<AdminCourseMembers>(
        future: _future,
        builder: (context, snapshot) {
          final members = snapshot.data;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Members - ${widget.course.code}',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Row(
                    children: [
                      Expanded(child: _sectionTitle('Instructors')),
                      OutlinedButton.icon(
                        onPressed: _addInstructor,
                        icon: Icon(Icons.person_add_rounded, size: 16),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if ((members?.instructors ?? const []).isEmpty)
                    Text(
                      'No instructors assigned.',
                      style: AppTextStyles.bodySmall,
                    )
                  else
                    Column(
                      children: members!.instructors.map((instructor) {
                        final isOnly = members.instructors.length == 1;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(instructor.name),
                          subtitle: Text(instructor.email),
                          trailing: IconButton(
                            tooltip: isOnly
                                ? 'At least one instructor is required'
                                : 'Remove instructor',
                            onPressed: isOnly
                                ? null
                                : () => _removeInstructor(instructor),
                            icon: Icon(
                              Icons.remove_circle_outline_rounded,
                              color: isOnly
                                  ? AppColors.textMuted
                                  : AppColors.error,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  Divider(color: AppColors.border),
                  Row(
                    children: [
                      Expanded(
                        child: _sectionTitle(
                          'Students (${members?.students.length ?? 0})',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addStudent,
                        icon: Icon(Icons.person_add_rounded, size: 16),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if ((members?.students ?? const []).isEmpty)
                    Text(
                      'No students enrolled.',
                      style: AppTextStyles.bodySmall,
                    )
                  else
                    FutureBuilder<List<CourseStudentActivity>>(
                      future: _activityFuture,
                      builder: (context, activitySnapshot) {
                        return Column(
                          children: members!.students.map((student) {
                            final meta = [
                              student.email,
                              if (student.enrolledAt != null)
                                'Enrolled ${student.enrolledLabel}',
                            ].join(' - ');
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(student.name),
                              subtitle: Text(meta),
                              onTap: () => showStudentActivitySheet(
                                context: context,
                                courseId: widget.course.id,
                                studentId: student.id,
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'Activity',
                                    onPressed: () => showStudentActivitySheet(
                                      context: context,
                                      courseId: widget.course.id,
                                      studentId: student.id,
                                    ),
                                    icon: Icon(Icons.insights_rounded),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove student',
                                    onPressed: () => _removeStudent(student),
                                    icon: Icon(
                                      Icons.remove_circle_outline_rounded,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: AppTextStyles.h3);
  }

  Future<void> _addInstructor() async {
    if (_instructors.isEmpty) {
      _snack('No instructors available.', isError: true);
      return;
    }
    final current = (await _future).instructors.map((user) => user.id).toSet();
    final available = _instructors
        .where((instructor) => !current.contains(instructor.id))
        .toList();
    if (available.isEmpty) {
      _snack('No available instructors to add.', isError: true);
      return;
    }
    final selected = await _pickUser('Add Instructor', available);
    if (selected == null) return;
    try {
      await AdminContentService.instance.addCourseInstructor(
        courseId: widget.course.id,
        instructorId: selected.id,
      );
      _snack('Instructor added');
      _refresh();
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
  }

  Future<void> _removeInstructor(AdminUser instructor) async {
    try {
      await AdminContentService.instance.removeCourseInstructor(
        courseId: widget.course.id,
        instructorId: instructor.id,
      );
      _snack('Instructor removed');
      _refresh();
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
  }

  Future<void> _addStudent() async {
    final current = (await _future).students.map((user) => user.id).toSet();
    final available = _students
        .where((student) => !current.contains(student.id))
        .toList();
    if (_students.isEmpty) {
      _snack('No student accounts are available.', isError: true);
      return;
    }
    if (available.isEmpty) {
      _snack('All available students are already enrolled.', isError: true);
      return;
    }
    final selected = await _pickUsers('Add Students', available);
    if (selected.isEmpty) return;
    try {
      await AdminContentService.instance.addCourseStudents(
        courseId: widget.course.id,
        studentIds: selected.map((user) => user.id).toList(),
      );
      _snack(
        selected.length == 1
            ? 'Student added'
            : '${selected.length} students added',
      );
      _refresh();
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
  }

  Future<void> _removeStudent(AdminUser student) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Remove Student'),
            content: Text(
              'Remove ${student.name} from ${widget.course.code}? Their previous submissions stay safely stored.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      await AdminContentService.instance.removeCourseStudent(
        courseId: widget.course.id,
        studentId: student.id,
      );
      _snack('Student removed');
      _refresh();
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
  }

  Future<AdminUser?> _pickUser(String title, List<AdminUser> users) {
    final search = TextEditingController();
    var filtered = users;
    return showDialog<AdminUser>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search users...',
                  ),
                  onChanged: (value) {
                    final query = value.toLowerCase();
                    setDlg(() {
                      filtered = users
                          .where(
                            (user) =>
                                user.name.toLowerCase().contains(query) ||
                                user.email.toLowerCase().contains(query),
                          )
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final user = filtered[index];
                      return ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        onTap: () => Navigator.pop(ctx, user),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<AdminUser>> _pickUsers(String title, List<AdminUser> users) {
    final search = TextEditingController();
    var filtered = users;
    final selectedIds = <String>{};
    return showDialog<List<AdminUser>>(
          context: context,
          builder: (_) => StatefulBuilder(
            builder: (ctx, setDlg) => AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Search students...',
                      ),
                      onChanged: (value) {
                        final query = value.toLowerCase();
                        setDlg(() {
                          filtered = users
                              .where(
                                (user) =>
                                    user.name.toLowerCase().contains(query) ||
                                    user.email.toLowerCase().contains(query),
                              )
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No students found.',
                                style: AppTextStyles.bodySmall,
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (_, index) {
                                final user = filtered[index];
                                final selected = selectedIds.contains(user.id);
                                return CheckboxListTile(
                                  value: selected,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(user.name),
                                  subtitle: Text(user.email),
                                  onChanged: (value) {
                                    setDlg(() {
                                      if (value ?? false) {
                                        selectedIds.add(user.id);
                                      } else {
                                        selectedIds.remove(user.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, const <AdminUser>[]),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () {
                          Navigator.pop(
                            ctx,
                            users
                                .where((user) => selectedIds.contains(user.id))
                                .toList(),
                          );
                        },
                  child: Text(
                    selectedIds.isEmpty ? 'Add' : 'Add ${selectedIds.length}',
                  ),
                ),
              ],
            ),
          ),
        )
        .then((value) => value ?? const <AdminUser>[])
        .whenComplete(search.dispose);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onRefresh,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onRefresh;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: AppTextStyles.h1),
                  const SizedBox(width: 10),
                  _Count(count),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: Icon(Icons.refresh_rounded),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: Icon(Icons.add_rounded, size: 16),
            label: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.status,
    required this.statuses,
    required this.onStatus,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final String? status;
  final List<String> statuses;
  final ValueChanged<String?> onStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: hint,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Chip(
                label: 'All',
                selected: status == null,
                onTap: () => onStatus(null),
              ),
              ...statuses.map(
                (value) => _Chip(
                  label: value,
                  selected: status == value,
                  onTap: () => onStatus(value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.count);
  final int count;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType keyboardType;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _InstructorSelector extends StatelessWidget {
  const _InstructorSelector({
    required this.instructors,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<AdminUser> instructors;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = instructors
        .where((user) => selectedIds.contains(user.id))
        .toList();
    final available = instructors
        .where((user) => !selectedIds.contains(user.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isEmpty)
          Text(
            'Select at least one instructor.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected.map((user) {
              return InputChip(
                avatar: Icon(Icons.person_rounded, size: 16),
                label: Text(
                  user.email.isEmpty
                      ? user.name
                      : '${user.name} - ${user.email}',
                ),
                onDeleted: () {
                  onChanged({...selectedIds}..remove(user.id));
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            if (instructors.isEmpty) {
              _showMessage(
                context,
                'No instructors are available. Create an instructor account first.',
                isError: true,
              );
              return;
            }
            if (available.isEmpty) {
              _showMessage(
                context,
                'All available instructors are already assigned.',
              );
              return;
            }
            final picked = await _pickInstructor(context, available);
            if (picked == null) return;
            onChanged({...selectedIds, picked.id});
          },
          icon: Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Add instructor'),
        ),
      ],
    );
  }

  Future<AdminUser?> _pickInstructor(
    BuildContext context,
    List<AdminUser> users,
  ) {
    final search = TextEditingController();
    var filtered = users;
    return showDialog<AdminUser>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Add Instructor'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search instructors...',
                  ),
                  onChanged: (value) {
                    final query = value.toLowerCase();
                    setDlg(() {
                      filtered = users
                          .where(
                            (user) =>
                                user.name.toLowerCase().contains(query) ||
                                user.email.toLowerCase().contains(query),
                          )
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final user = filtered[index];
                      return ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        onTap: () => Navigator.pop(ctx, user),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ).whenComplete(search.dispose);
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h2),
            const SizedBox(height: 16),
            ...rows.entries.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(row.key, style: AppTextStyles.caption),
                    ),
                    Expanded(
                      child: Text(row.value, style: AppTextStyles.label),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text(title, style: AppTextStyles.h3)),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    );
  }
}
