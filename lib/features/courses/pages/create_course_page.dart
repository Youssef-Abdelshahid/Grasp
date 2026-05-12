import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/course_model.dart';
import '../../../services/course_service.dart';
import '../../../services/permissions_service.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key, this.course});

  final CourseModel? course;

  bool get isEditing => course != null;

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _descCtrl;
  late String _semester;
  late double _maxStudents;
  late bool _selfEnrollment;
  late bool _visible;
  bool _isSubmitting = false;

  static const _semesters = [
    'Spring 2025',
    'Fall 2025',
    'Spring 2026',
    'Fall 2026',
  ];

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    _titleCtrl = TextEditingController(text: course?.title ?? '');
    _codeCtrl = TextEditingController(text: course?.code ?? '');
    _descCtrl = TextEditingController(text: course?.description ?? '');
    _semester = course?.semester.isNotEmpty == true
        ? course!.semester
        : _semesters.first;
    _maxStudents = (course?.maxStudents ?? 50).toDouble();
    _selfEnrollment = course?.allowSelfEnrollment ?? false;
    _visible = course?.isVisible ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Course' : 'Create Course';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTextStyles.h3),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Basic Information', [
                _buildField(
                  'Course Title *',
                  TextFormField(
                    controller: _titleCtrl,
                    validator: _requiredField,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Mobile Device Programming',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (_, constraints) {
                    final narrow = constraints.maxWidth < 400;
                    final codeField = _buildField(
                      'Course Code *',
                      TextFormField(
                        controller: _codeCtrl,
                        validator: _requiredField,
                        decoration: const InputDecoration(
                          hintText: 'e.g. CS401',
                        ),
                      ),
                    );
                    final semesterField = _buildField(
                      'Semester',
                      _DropdownField<String>(
                        value: _semester,
                        items: _semesters,
                        onChanged: (value) => setState(() => _semester = value),
                      ),
                    );
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          codeField,
                          const SizedBox(height: 16),
                          semesterField,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: codeField),
                        const SizedBox(width: 16),
                        Expanded(child: semesterField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildField(
                  'Description',
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Brief description of the course...',
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              _buildSection('Enrollment Settings', [
                _buildField(
                  'Max Students: ${_maxStudents.round()}',
                  Slider(
                    value: _maxStudents,
                    min: 10,
                    max: 200,
                    divisions: 19,
                    label: '${_maxStudents.round()}',
                    onChanged: (value) => setState(() => _maxStudents = value),
                  ),
                ),
                const SizedBox(height: 8),
                _buildToggle(
                  'Allow self-enrollment',
                  _selfEnrollment,
                  (value) => setState(() => _selfEnrollment = value),
                ),
                Divider(color: AppColors.border, height: 24),
                _buildToggle(
                  'Visible to students',
                  _visible,
                  (value) => setState(() => _visible = value),
                ),
              ]),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Save Changes'
                                  : 'Create Course',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.body)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final course = widget.isEditing
          ? await CourseService.instance.updateCourse(
              courseId: widget.course!.id,
              title: _titleCtrl.text,
              code: _codeCtrl.text,
              description: _descCtrl.text,
              semester: _semester,
              maxStudents: _maxStudents.round(),
              allowSelfEnrollment: _selfEnrollment,
              isVisible: _visible,
            )
          : await CourseService.instance.createCourse(
              title: _titleCtrl.text,
              code: _codeCtrl.text,
              description: _descCtrl.text,
              semester: _semester,
              maxStudents: _maxStudents.round(),
              allowSelfEnrollment: _selfEnrollment,
              isVisible: _visible,
            );

      if (!mounted) {
        return;
      }
      Navigator.pop(context, course);
    } on PermissionsException catch (error) {
      _showError(error.message);
    } on PostgrestException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        color: AppColors.textSecondary,
      ),
      style: AppTextStyles.body,
      items: items
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(item.toString())),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
