import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class QuizBuilderPage extends StatefulWidget {
  const QuizBuilderPage({super.key});

  @override
  State<QuizBuilderPage> createState() => _QuizBuilderPageState();
}

class _QuizBuilderPageState extends State<QuizBuilderPage> {
  final _titleCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController(text: 'Apr 30, 2025');
  final _timeLimitCtrl = TextEditingController(text: '30');

  final List<_QuestionData> _questions = [
    _QuestionData(),
    _QuestionData()..type = 'True / False',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    _dueDateCtrl.dispose();
    _timeLimitCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() => setState(() => _questions.add(_QuestionData()));

  void _removeQuestion(int i) {
    _questions[i].dispose();
    setState(() => _questions.removeAt(i));
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
        title: Text('Quiz Builder', style: AppTextStyles.h3),
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
          _buildSettings(),
          const SizedBox(height: 20),
          _buildAiBanner(context),
          const SizedBox(height: 20),
          _buildQuestionsSection(),
          const SizedBox(height: 16),
          _buildAddButtons(context),
        ]),
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quiz Details', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        _label('Quiz Title *'),
        const SizedBox(height: 6),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(hintText: 'e.g. Quiz 1: Introduction Concepts'),
        ),
        const SizedBox(height: 16),
        _label('Instructions'),
        const SizedBox(height: 6),
        TextField(
          controller: _instructionsCtrl,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Instructions for students...'),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (_, constraints) {
          final narrow = constraints.maxWidth < 360;
          final dateField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Due Date'),
            const SizedBox(height: 6),
            TextField(controller: _dueDateCtrl, decoration: const InputDecoration(hintText: 'Apr 30, 2025')),
          ]);
          final timeField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Time Limit (min)'),
            const SizedBox(height: 6),
            TextField(controller: _timeLimitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '30')),
          ]);
          if (narrow) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              dateField, const SizedBox(height: 16), timeField,
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: dateField),
            const SizedBox(width: 16),
            Expanded(child: timeField),
          ]);
        }),
      ]),
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Question Generator', style: AppTextStyles.label.copyWith(color: Colors.white)),
          Text(
            'Upload materials and generate quiz questions automatically',
            style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ])),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _showAiSheet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.violet,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          child: const Text('Generate'),
        ),
      ]),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Questions', style: AppTextStyles.h3)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(100)),
          child: Text(
            '${_questions.length}',
            style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      ...List.generate(_questions.length, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _QuestionCard(
          number: i + 1,
          data: _questions[i],
          onDelete: () => _removeQuestion(i),
          onChanged: () => setState(() {}),
        ),
      )),
    ]);
  }

  Widget _buildAddButtons(BuildContext context) {
    return Row(children: [
      Expanded(child: OutlinedButton.icon(
        onPressed: _addQuestion,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Add Question'),
      )),
      const SizedBox(width: 10),
      Expanded(child: OutlinedButton.icon(
        onPressed: () => _showAiSheet(context),
        icon: const Icon(Icons.auto_awesome_rounded, size: 14),
        label: const Text('AI Generate'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.violet,
          side: const BorderSide(color: AppColors.violet),
        ),
      )),
    ]);
  }

  void _showAiSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiGenerateSheet(),
    );
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.label);
}

class _QuestionData {
  String type = 'MCQ';
  int correctOption = 0;
  final textCtrl = TextEditingController();
  final optionCtrls = List.generate(4, (_) => TextEditingController());
  final marksCtrl = TextEditingController(text: '1');
  final explanationCtrl = TextEditingController();

  void dispose() {
    textCtrl.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }
    marksCtrl.dispose();
    explanationCtrl.dispose();
  }
}

class _QuestionCard extends StatefulWidget {
  final int number;
  final _QuestionData data;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _QuestionCard({
    required this.number,
    required this.data,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  static const _types = ['MCQ', 'True / False', 'Short Answer'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
              child: Text(
                'Q${widget.number}',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.data.type, style: AppTextStyles.label)),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textSecondary),
              onPressed: widget.onDelete,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Question Text', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: widget.data.textCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Enter your question here...'),
            ),
            const SizedBox(height: 14),
            Text('Question Type', style: AppTextStyles.label),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _types.map((t) {
                final selected = widget.data.type == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      widget.data.type = t;
                      widget.onChanged();
                    }),
                    selectedColor: AppColors.primaryLight,
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 14),
            if (widget.data.type == 'MCQ') _buildMcqOptions(),
            if (widget.data.type == 'True / False') _buildTrueFalseOptions(),
            if (widget.data.type == 'Short Answer') _buildShortAnswerHint(),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (_, constraints) {
              final narrow = constraints.maxWidth < 340;
              final marksField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Marks', style: AppTextStyles.label),
                const SizedBox(height: 6),
                TextField(
                  controller: widget.data.marksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '1'),
                ),
              ]);
              final explanationField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Explanation (optional)', style: AppTextStyles.label),
                const SizedBox(height: 6),
                TextField(
                  controller: widget.data.explanationCtrl,
                  decoration: const InputDecoration(hintText: 'Why is this correct?'),
                ),
              ]);
              if (narrow) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  marksField, const SizedBox(height: 12), explanationField,
                ]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: marksField),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: explanationField),
              ]);
            }),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMcqOptions() {
    const labels = ['A', 'B', 'C', 'D'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Options', style: AppTextStyles.label),
      const SizedBox(height: 8),
      RadioGroup<int>(
        groupValue: widget.data.correctOption,
        onChanged: (v) { if (v != null) setState(() => widget.data.correctOption = v); },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Radio<int>(value: i, visualDensity: VisualDensity.compact),
              const SizedBox(width: 4),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: widget.data.correctOption == i ? AppColors.primaryLight : AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: AppTextStyles.caption.copyWith(
                    color: widget.data.correctOption == i ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                controller: widget.data.optionCtrls[i],
                decoration: InputDecoration(hintText: 'Option ${labels[i]}'),
              )),
            ]),
          )),
        ),
      ),
    ]);
  }

  Widget _buildTrueFalseOptions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Correct Answer', style: AppTextStyles.label),
      const SizedBox(height: 8),
      RadioGroup<int>(
        groupValue: widget.data.correctOption,
        onChanged: (v) { if (v != null) setState(() => widget.data.correctOption = v); },
        child: Row(children: [
          Radio<int>(value: 0, visualDensity: VisualDensity.compact),
          const SizedBox(width: 4),
          const Text('True'),
          const SizedBox(width: 20),
          Radio<int>(value: 1, visualDensity: VisualDensity.compact),
          const SizedBox(width: 4),
          const Text('False'),
        ]),
      ),
    ]);
  }

  Widget _buildShortAnswerHint() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Sample Answer (reference)', style: AppTextStyles.label),
      const SizedBox(height: 6),
      const TextField(decoration: InputDecoration(hintText: 'Expected answer...')),
    ]);
  }
}

class _AiGenerateSheet extends StatefulWidget {
  const _AiGenerateSheet();

  @override
  State<_AiGenerateSheet> createState() => _AiGenerateSheetState();
}

class _AiGenerateSheetState extends State<_AiGenerateSheet> {
  String _selectedCount = '10';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(color: AppColors.violetLight, shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.violet, size: 28),
        ),
        const SizedBox(height: 16),
        Text('AI Question Generator', style: AppTextStyles.h3, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'How many questions would you like to generate?',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: ['5', '10', '15', '20'].map((n) => ChoiceChip(
          label: Text('$n questions'),
          selected: _selectedCount == n,
          onSelected: (_) => setState(() => _selectedCount = n),
          selectedColor: AppColors.violetLight,
          labelStyle: AppTextStyles.caption.copyWith(
            color: _selectedCount == n ? AppColors.violet : AppColors.textSecondary,
            fontWeight: _selectedCount == n ? FontWeight.w600 : FontWeight.w400,
          ),
        )).toList()),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Generate Questions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.violet,
            foregroundColor: Colors.white,
          ),
        )),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        )),
      ]),
    );
  }
}
