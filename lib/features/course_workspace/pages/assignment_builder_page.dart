import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AssignmentBuilderPage extends StatefulWidget {
  const AssignmentBuilderPage({super.key});

  @override
  State<AssignmentBuilderPage> createState() => _AssignmentBuilderPageState();
}

class _AssignmentBuilderPageState extends State<AssignmentBuilderPage> {
  final _titleCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController(text: 'May 15, 2025');
  final _marksCtrl = TextEditingController(text: '100');

  final List<_RubricRow> _rubric = [
    _RubricRow('Code Quality', 'Clean, well-structured code', 30),
    _RubricRow('Functionality', 'All features working correctly', 40),
    _RubricRow('Documentation', 'README and inline documentation', 20),
    _RubricRow('Presentation', 'Demo video or live demo', 10),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    _deadlineCtrl.dispose();
    _marksCtrl.dispose();
    for (final r in _rubric) {
      r.dispose();
    }
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
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Assignment Builder', style: AppTextStyles.h3),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Save Draft')),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(onPressed: () {}, child: const Text('Publish')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildDetails(),
          const SizedBox(height: 20),
          _buildAiBanner(context),
          const SizedBox(height: 20),
          _buildAttachments(),
          const SizedBox(height: 20),
          _buildRubric(),
        ]),
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Assignment Details', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        _label('Assignment Title *'),
        const SizedBox(height: 6),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(hintText: 'e.g. Assignment 2: Implementation Phase'),
        ),
        const SizedBox(height: 16),
        _label('Instructions'),
        const SizedBox(height: 6),
        TextField(
          controller: _instructionsCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Detailed instructions for students...'),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (_, constraints) {
          final narrow = constraints.maxWidth < 360;
          final deadlineField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Deadline'),
            const SizedBox(height: 6),
            TextField(
              controller: _deadlineCtrl,
              decoration: const InputDecoration(
                hintText: 'May 15, 2025',
                prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
              ),
            ),
          ]);
          final marksField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Total Marks'),
            const SizedBox(height: 6),
            TextField(
              controller: _marksCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '100'),
            ),
          ]);
          if (narrow) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              deadlineField, const SizedBox(height: 16), marksField,
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: deadlineField),
            const SizedBox(width: 16),
            Expanded(child: marksField),
          ]);
        }),
      ]),
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emeraldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: AppColors.emerald, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Assignment Generator', style: AppTextStyles.label.copyWith(color: AppColors.emerald)),
          Text(
            'Generate rubric-based assignments with AI assistance',
            style: AppTextStyles.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ])),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _showAiSheet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          child: const Text('Generate'),
        ),
      ]),
    );
  }

  Widget _buildAttachments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Attachments', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('No files attached', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
            TextButton(onPressed: () {}, child: const Text('Add Files')),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Supported: PDF, DOCX, PPTX, ZIP (max 100 MB each)', style: AppTextStyles.caption),
      ]),
    );
  }

  Widget _buildRubric() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Grading Rubric', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
              ),
              child: Row(children: [
                Expanded(flex: 2, child: Text('Criterion', style: AppTextStyles.label)),
                Expanded(flex: 3, child: Text('Description', style: AppTextStyles.label)),
                SizedBox(width: 56, child: Text('Marks', style: AppTextStyles.label, textAlign: TextAlign.center)),
                const SizedBox(width: 32),
              ]),
            ),
            const Divider(height: 1, color: AppColors.border),
            ...List.generate(_rubric.length, (i) {
              final r = _rubric[i];
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    Expanded(flex: 2, child: TextField(
                      controller: r.criterionCtrl,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Criterion',
                      ),
                      style: AppTextStyles.body,
                    )),
                    Expanded(flex: 3, child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: r.descCtrl,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Description',
                        ),
                        style: AppTextStyles.bodySmall,
                      ),
                    )),
                    SizedBox(width: 56, child: TextField(
                      controller: r.marksCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: '10',
                      ),
                      style: AppTextStyles.body,
                    )),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                      onPressed: () {
                        r.dispose();
                        setState(() => _rubric.removeAt(i));
                      },
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ]),
                ),
                if (i < _rubric.length - 1) const Divider(height: 1, color: AppColors.border),
              ]);
            }),
          ]),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() => _rubric.add(_RubricRow('', '', 10))),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Criterion'),
        ),
      ]),
    );
  }

  void _showAiSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AiAssignmentSheet(),
    );
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.label);
}

class _RubricRow {
  final TextEditingController criterionCtrl;
  final TextEditingController descCtrl;
  final TextEditingController marksCtrl;

  _RubricRow(String criterion, String desc, int marks)
      : criterionCtrl = TextEditingController(text: criterion),
        descCtrl = TextEditingController(text: desc),
        marksCtrl = TextEditingController(text: '$marks');

  void dispose() {
    criterionCtrl.dispose();
    descCtrl.dispose();
    marksCtrl.dispose();
  }
}

class _AiAssignmentSheet extends StatelessWidget {
  const _AiAssignmentSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: AppColors.emeraldLight, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.emerald, size: 28),
          ),
          const SizedBox(height: 16),
          Text('AI Assignment Generator', style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Describe the assignment and AI will generate complete instructions and a grading rubric.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. A project on mobile app development with implementation and testing phases...',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Generate Assignment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
            ),
          )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          )),
        ]),
      ),
    );
  }
}
