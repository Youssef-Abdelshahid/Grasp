import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AssignmentSubmissionPage extends StatefulWidget {
  final String title;
  final String deadline;
  final String instructions;

  const AssignmentSubmissionPage({
    super.key,
    required this.title,
    required this.deadline,
    this.instructions = '',
  });

  @override
  State<AssignmentSubmissionPage> createState() => _AssignmentSubmissionPageState();
}

class _AssignmentSubmissionPageState extends State<AssignmentSubmissionPage> {
  final _textController = TextEditingController();
  bool _fileAdded = false;
  bool _submitted = false;
  bool _isUploading = false;
  bool _isHovered = false;

  static const _rubric = [
    (criteria: 'Project Structure', points: 20, desc: 'Well-organized code with clear separation of concerns.'),
    (criteria: 'Functionality', points: 40, desc: 'All required features work correctly without major bugs.'),
    (criteria: 'Documentation', points: 20, desc: 'Code comments, README, and API docs are complete.'),
    (criteria: 'Testing', points: 20, desc: 'Unit tests and integration tests with adequate coverage.'),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Assignment Submission', style: AppTextStyles.caption),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeadlineBanner(),
            const SizedBox(height: 20),
            _buildInstructions(),
            const SizedBox(height: 20),
            _buildRubric(),
            const SizedBox(height: 20),
            _buildUploadArea(),
            const SizedBox(height: 20),
            _buildTextAnswer(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTextStyles.h3.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text('Due: ${widget.deadline}',
                        style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final instructions = widget.instructions.isNotEmpty
        ? widget.instructions
        : 'Build a functional mobile application using Flutter that demonstrates the concepts covered in this course. Your submission must include:\n\n1. A working Flutter project with all source code\n2. A README file explaining setup and usage\n3. Screenshots of the app running on a device or emulator\n4. A brief report (PDF) describing your implementation choices\n\nThe app must implement at least 3 screens with proper navigation, state management, and UI design consistent with Material Design guidelines.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Instructions', style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(instructions, style: AppTextStyles.body),
        ),
      ],
    );
  }

  Widget _buildRubric() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: AppColors.violetLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.grade_rounded, color: AppColors.violet, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Grading Rubric', style: AppTextStyles.h3),
            const Spacer(),
            Text('100 pts total', style: AppTextStyles.caption.copyWith(color: AppColors.violet, fontWeight: FontWeight.w600)),
          ],
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
            itemCount: _rubric.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) {
              final r = _rubric[i];
              return Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.violetLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${r.points}',
                          style: AppTextStyles.label.copyWith(color: AppColors.violet, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.criteria, style: AppTextStyles.label),
                          const SizedBox(height: 2),
                          Text(r.desc, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: AppColors.emeraldLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.upload_file_rounded, color: AppColors.emerald, size: 16),
            ),
            const SizedBox(width: 10),
            Text('File Upload', style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: 12),
        if (_fileAdded)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('project_submission.zip', style: AppTextStyles.label),
                      Text('3.8 MB · Ready to submit', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _fileAdded = false),
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          )
        else
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: () => setState(() => _fileAdded = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? AppColors.emeraldLight.withValues(alpha: 0.6)
                      : AppColors.emeraldLight.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isHovered ? AppColors.emerald : AppColors.emerald.withValues(alpha: 0.35),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_rounded,
                      color: AppColors.emerald,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text('Drop files here or tap to browse',
                        style: AppTextStyles.label, textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text('ZIP, PDF, DOCX · Maximum 50MB',
                        style: AppTextStyles.caption, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _fileAdded = true),
                      icon: const Icon(Icons.folder_open_rounded, size: 14),
                      label: const Text('Browse Files'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextAnswer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.edit_rounded, color: AppColors.amber, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Written Response', style: AppTextStyles.h3),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text('Optional', style: AppTextStyles.caption),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _textController,
            maxLines: 6,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Describe your approach, challenges faced, and any additional notes for the instructor...',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _fileAdded || _textController.text.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canSubmit ? _handleSubmit : null,
            icon: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 16),
            label: Text(_isUploading ? 'Submitting...' : 'Submit Assignment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              disabledBackgroundColor: AppColors.border,
            ),
          ),
        ),
        if (!canSubmit) ...[
          const SizedBox(height: 8),
          Text(
            'Please upload a file or write a response before submitting.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  void _handleSubmit() async {
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() { _isUploading = false; _submitted = true; });
  }

  Widget _buildSuccessScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.emerald, Color(0xFF059669)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              Text('Assignment Submitted!', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'Your submission has been received successfully. The instructor will review your work.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _SubmitDetail(icon: Icons.assignment_rounded, label: 'Assignment', value: widget.title),
                    const SizedBox(height: 10),
                    _SubmitDetail(icon: Icons.schedule_rounded, label: 'Submitted', value: 'Apr 7, 2025 · 2:45 PM'),
                    const SizedBox(height: 10),
                    _SubmitDetail(icon: Icons.attach_file_rounded, label: 'File', value: _fileAdded ? 'project_submission.zip' : 'Written response only'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back to Assignments'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SubmitDetail({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text('$label:', style: AppTextStyles.caption),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
