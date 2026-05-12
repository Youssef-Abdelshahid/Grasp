import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/assignment_model.dart';
import '../../../models/admin_content_models.dart';
import '../../../models/quiz_model.dart';
import '../../../services/admin_content_service.dart';
import '../../activity/activity_sheets.dart';
import '../../course_workspace/pages/assignment_builder_page.dart';
import '../../course_workspace/pages/quiz_builder_page.dart';

class AdminAssessmentsPage extends StatefulWidget {
  const AdminAssessmentsPage.quizzes({super.key})
    : type = AdminAssessmentType.quiz;
  const AdminAssessmentsPage.assignments({super.key})
    : type = AdminAssessmentType.assignment;

  final AdminAssessmentType type;

  @override
  State<AdminAssessmentsPage> createState() => _AdminAssessmentsPageState();
}

enum AdminAssessmentType { quiz, assignment }

class _AdminAssessmentsPageState extends State<AdminAssessmentsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _status;
  Future<List<AdminAssessmentItem>>? _future;
  List<AdminCourseItem> _courses = const [];

  bool get _isQuiz => widget.type == AdminAssessmentType.quiz;
  String get _title => _isQuiz ? 'Quizzes' : 'Assignments';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminAssessmentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _debounce?.cancel();
      _status = null;
      _searchController.clear();
      _load();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = _isQuiz
          ? AdminContentService.instance.listQuizzes(
              search: _searchController.text,
              status: _status,
            )
          : AdminContentService.instance.listAssignments(
              search: _searchController.text,
              status: _status,
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

    return FutureBuilder<List<AdminAssessmentItem>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AdminAssessmentItem>[];
        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_title, style: AppTextStyles.h1)),
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
                    onPressed: _create,
                    icon: Icon(Icons.add_rounded, size: 16),
                    label: const Text('Create'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText:
                      'Search ${_title.toLowerCase()}, courses, or codes...',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [null, 'published', 'draft', if (!_isQuiz) 'overdue']
                    .map((status) {
                      return ChoiceChip(
                        label: Text(status ?? 'All'),
                        selected: _status == status,
                        onSelected: (_) {
                          _status = status;
                          _load();
                        },
                      );
                    })
                    .toList(),
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
                        'No ${_title.toLowerCase()} found',
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
                          _isQuiz
                              ? Icons.quiz_rounded
                              : Icons.assignment_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(item.title, style: AppTextStyles.label),
                        subtitle: Text(
                          '${item.courseCode} - ${item.instructorName} - ${item.statusLabel} - ${item.dueLabel}',
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
                              onPressed: () => _openBuilder(item),
                              icon: Icon(Icons.edit_rounded),
                            ),
                            IconButton(
                              tooltip: item.isPublished
                                  ? 'Unpublish'
                                  : 'Publish',
                              onPressed: () => _togglePublished(item),
                              icon: Icon(
                                item.isPublished
                                    ? Icons.visibility_off_rounded
                                    : Icons.publish_rounded,
                                color: item.isPublished
                                    ? AppColors.amber
                                    : AppColors.success,
                              ),
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

  void _showDetails(AdminAssessmentItem item) {
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
              const SizedBox(height: 16),
              _Row('Course', '${item.courseTitle} - ${item.courseCode}'),
              _Row('Instructor', item.instructorName),
              _Row('Status', item.statusLabel),
              _Row('Due', item.dueLabel),
              _Row('Points', '${item.maxPoints}'),
              _Row(
                _isQuiz ? 'Questions' : 'Rubric Items',
                '${item.schemaCount}',
              ),
              if (_isQuiz)
                _Row(
                  'Duration',
                  item.durationMinutes == null
                      ? 'Not set'
                      : '${item.durationMinutes} minutes',
                ),
              if (_isQuiz)
                _Row(
                  'Correct Answers',
                  item.showCorrectAnswers ? 'Visible to students' : 'Hidden',
                ),
              if (_isQuiz)
                _Row('Retakes', item.allowRetakes ? 'Allowed' : 'Not allowed'),
              if (!_isQuiz)
                _Row(
                  'Attachment Rules',
                  item.attachmentRequirements.isEmpty
                      ? 'Not set'
                      : item.attachmentRequirements,
                ),
              _Row('Created By', item.createdByName),
              _Row('Created', item.createdLabel),
              _Row(
                'Instructions',
                item.instructions.isEmpty
                    ? 'No instructions'
                    : item.instructions,
              ),
              AssessmentActivityPanel(assessmentId: item.id, isQuiz: _isQuiz),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (_courses.isEmpty) {
      _snack('Create a course before adding content.', isError: true);
      return;
    }
    final courseId = await _pickCourse();
    if (courseId == null || !mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _isQuiz
            ? QuizBuilderPage(courseId: courseId)
            : AssignmentBuilderPage(courseId: courseId),
      ),
    );
    if (result != null) {
      await AdminContentService.instance.logAdminAction(
        action: _isQuiz ? 'quiz_created' : 'assignment_created',
        summary: _isQuiz
            ? 'Created quiz from admin'
            : 'Created assignment from admin',
        metadata: {'course_id': courseId},
      );
      _snack('Created');
      _load();
    }
  }

  Future<void> _openBuilder(AdminAssessmentItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _isQuiz
            ? QuizBuilderPage(courseId: item.courseId, quiz: _toQuiz(item))
            : AssignmentBuilderPage(
                courseId: item.courseId,
                assignment: _toAssignment(item),
              ),
      ),
    );
    if (result != null) {
      await AdminContentService.instance.logAdminAction(
        action: _isQuiz ? 'quiz_edited' : 'assignment_edited',
        summary: 'Edited ${item.title} from admin',
        metadata: {'course_id': item.courseId, 'item_id': item.id},
      );
      _snack('Saved');
      _load();
    }
  }

  Future<String?> _pickCourse() {
    var selected = _courses.first.id;
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Course'),
        content: StatefulBuilder(
          builder: (ctx, setDlg) => DropdownButtonFormField<String>(
            initialValue: selected,
            items: _courses
                .map(
                  (course) => DropdownMenuItem(
                    value: course.id,
                    child: Text('${course.title} - ${course.code}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setDlg(() => selected = value ?? selected),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  QuizModel _toQuiz(AdminAssessmentItem item) {
    return QuizModel(
      id: item.id,
      courseId: item.courseId,
      title: item.title,
      description: item.description,
      instructions: item.instructions,
      dueAt: item.dueAt,
      maxPoints: item.maxPoints,
      durationMinutes: item.durationMinutes,
      isPublished: item.isPublished,
      questionSchema: item.schema,
      createdBy: '',
      createdAt: item.createdAt ?? DateTime.now(),
      updatedAt: item.createdAt ?? DateTime.now(),
      publishedAt: item.publishedAt,
      showCorrectAnswers: item.showCorrectAnswers,
      allowRetakes: item.allowRetakes,
      showQuestionMarks: item.showQuestionMarks,
    );
  }

  AssignmentModel _toAssignment(AdminAssessmentItem item) {
    return AssignmentModel(
      id: item.id,
      courseId: item.courseId,
      title: item.title,
      instructions: item.instructions,
      attachmentRequirements: item.attachmentRequirements,
      dueAt: item.dueAt,
      maxPoints: item.maxPoints,
      isPublished: item.isPublished,
      rubric: item.rubric,
      attachments: item.attachments,
      createdBy: '',
      createdAt: item.createdAt ?? DateTime.now(),
      updatedAt: item.createdAt ?? DateTime.now(),
      publishedAt: item.publishedAt,
    );
  }

  Future<void> _togglePublished(AdminAssessmentItem item) async {
    try {
      if (_isQuiz) {
        await AdminContentService.instance.setQuizPublished(
          item.id,
          !item.isPublished,
        );
      } else {
        await AdminContentService.instance.setAssignmentPublished(
          item.id,
          !item.isPublished,
        );
      }
      if (!mounted) return;
      _snack(item.isPublished ? 'Unpublished' : 'Published');
      _load();
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
  }

  Future<void> _delete(AdminAssessmentItem item) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Delete ${_isQuiz ? 'Quiz' : 'Assignment'}'),
            content: Text(
              'Delete ${item.title}? Related submissions may also be affected by database constraints.',
            ),
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
      if (_isQuiz) {
        await AdminContentService.instance.deleteQuiz(item.id);
      } else {
        await AdminContentService.instance.deleteAssignment(item.id);
      }
      if (!mounted) return;
      _snack('Deleted');
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(child: Text(value, style: AppTextStyles.label)),
        ],
      ),
    );
  }
}
