import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _titleCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _instructorCtrl = TextEditingController(text: 'Dr. Ahmed Ali');
  String _semester = 'Spring 2025';
  double _maxStudents = 50;
  bool _selfEnrollment = true;
  bool _aiEnabled = true;
  bool _visible = false;

  static const _semesters = ['Spring 2025', 'Fall 2025', 'Spring 2026', 'Fall 2026'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _instructorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Course', style: AppTextStyles.h3),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Basic Information', [
              _buildField('Course Title *', TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'e.g. Mobile Device Programming'),
              )),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (_, constraints) {
                final narrow = constraints.maxWidth < 400;
                final codeField = _buildField('Course Code *', TextField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. CS401'),
                ));
                final semesterField = _buildField('Semester', _DropdownField<String>(
                  value: _semester,
                  items: _semesters,
                  onChanged: (v) => setState(() => _semester = v),
                ));
                if (narrow) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    codeField, const SizedBox(height: 16), semesterField,
                  ]);
                }
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: codeField),
                  const SizedBox(width: 16),
                  Expanded(child: semesterField),
                ]);
              }),
              const SizedBox(height: 16),
              _buildField('Description', TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Brief description of the course...'),
              )),
            ]),
            const SizedBox(height: 20),
            _buildSection('Instructor & Capacity', [
              _buildField('Instructor Name', TextField(
                controller: _instructorCtrl,
                decoration: const InputDecoration(hintText: 'Full name'),
              )),
              const SizedBox(height: 20),
              _buildField(
                'Max Students: ${_maxStudents.round()}',
                Slider(
                  value: _maxStudents,
                  min: 10,
                  max: 200,
                  divisions: 19,
                  label: '${_maxStudents.round()}',
                  onChanged: (v) => setState(() => _maxStudents = v),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _buildSection('Settings', [
              _buildToggle('Allow self-enrollment', _selfEnrollment, (v) => setState(() => _selfEnrollment = v)),
              const Divider(color: AppColors.border, height: 24),
              _buildToggle('Enable AI assistance', _aiEnabled, (v) => setState(() => _aiEnabled = v)),
              const Divider(color: AppColors.border, height: 24),
              _buildToggle('Visible to students', _visible, (v) => setState(() => _visible = v)),
            ]),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Create Course'),
              )),
            ]),
          ],
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.h3),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildField(String label, Widget child) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      child,
    ]);
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(children: [
      Expanded(child: Text(label, style: AppTextStyles.body)),
      Switch(value: value, onChanged: onChanged),
    ]);
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;

  const _DropdownField({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
      style: AppTextStyles.body,
      items: items.map((i) => DropdownMenuItem<T>(value: i, child: Text(i.toString()))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
