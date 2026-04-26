import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../models/assignment_model.dart';
import '../../../models/assignment_rubric_item_model.dart';
import '../../../models/submission_model.dart';
import '../../../services/assignment_service.dart';
import '../../../services/submission_service.dart';
import '../../activity/activity_sheets.dart';

class AssignmentSubmissionPage extends StatefulWidget {
  const AssignmentSubmissionPage({
    super.key,
    required this.assignment,
    this.latestSubmission,
  });

  final AssignmentModel assignment;
  final SubmissionModel? latestSubmission;

  @override
  State<AssignmentSubmissionPage> createState() =>
      _AssignmentSubmissionPageState();
}

class _AssignmentSubmissionPageState extends State<AssignmentSubmissionPage> {
  final _textController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  SubmissionModel? _submission;

  @override
  void initState() {
    super.initState();
    _submission = widget.latestSubmission;
    final existingText =
        widget.latestSubmission?.content['text_answer'] as String? ?? '';
    _textController.text = existingText;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context, _submission),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.assignment.title,
              style: AppTextStyles.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
            _HeaderCard(assignment: widget.assignment, submission: _submission),
            const SizedBox(height: 20),
            _InstructionsCard(assignment: widget.assignment),
            const SizedBox(height: 20),
            _AssignmentAttachmentsCard(
              attachments: widget.assignment.attachments,
            ),
            if (widget.assignment.attachments.isNotEmpty)
              const SizedBox(height: 20),
            _RubricCard(rubric: widget.assignment.rubric),
            const SizedBox(height: 20),
            _ExistingSubmissionCard(
              submission: _submission,
              onOpenFile: _submission?.storagePath == null
                  ? null
                  : _openSubmittedFile,
              onViewResult: _submission == null ? null : _viewResult,
            ),
            if (_submission != null) const SizedBox(height: 20),
            _UploadCard(
              selectedFile: _selectedFile,
              onPickFile: _pickFile,
              onClearFile: () => setState(() => _selectedFile = null),
            ),
            const SizedBox(height: 20),
            _WrittenResponseCard(controller: _textController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSubmit ? _submit : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Assignment',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit {
    return _selectedFile != null || _textController.text.trim().isNotEmpty;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() => _selectedFile = result.files.single);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final submission = await SubmissionService.instance.submitAssignment(
        assignment: widget.assignment,
        textAnswer: _textController.text,
        file: _selectedFile,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submission = submission;
        _selectedFile = null;
      });
      _showMessage('Assignment submitted successfully.');
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openSubmittedFile() async {
    final submission = _submission;
    if (submission == null) {
      return;
    }

    final url = await SubmissionService.instance.createSubmissionFileUrl(
      submission,
    );
    if (url == null) {
      _showMessage('No submitted file found.');
      return;
    }

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _showMessage('Unable to open the submitted file.');
    }
  }

  Future<void> _viewResult() async {
    final submission = _submission;
    if (submission == null) return;
    await showStudentSubmissionResultSheet(
      context: context,
      submissionId: submission.id,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.assignment, required this.submission});

  final AssignmentModel assignment;
  final SubmissionModel? submission;

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(
              Icons.assignment_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  assignment.dueAt == null
                      ? 'No deadline'
                      : 'Due: ${FileUtils.formatDateTime(assignment.dueAt!)}',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
                if (submission != null)
                  Text(
                    'Latest attempt: #${submission!.attemptNumber}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.assignment});

  final AssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Instructions',
      icon: Icons.description_rounded,
      iconColor: AppColors.primary,
      child: Text(
        assignment.instructions.isEmpty
            ? 'No extra instructions were provided.'
            : assignment.instructions,
        style: AppTextStyles.body,
      ),
    );
  }
}

class _RubricCard extends StatelessWidget {
  const _RubricCard({required this.rubric});

  final List<Map<String, dynamic>> rubric;

  @override
  Widget build(BuildContext context) {
    final items = rubric.map(AssignmentRubricItemModel.fromJson).toList();
    return _SectionCard(
      title: 'Grading Rubric',
      icon: Icons.grade_rounded,
      iconColor: AppColors.violet,
      child: items.isEmpty
          ? Text(
              'No rubric has been added yet.',
              style: AppTextStyles.bodySmall,
            )
          : Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.violetLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${item.marks}',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.violet,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.criterion,
                                  style: AppTextStyles.label,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _AssignmentAttachmentsCard extends StatelessWidget {
  const _AssignmentAttachmentsCard({required this.attachments});

  final List<Map<String, dynamic>> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    return _SectionCard(
      title: 'Assignment Files',
      icon: Icons.attach_file_rounded,
      iconColor: AppColors.primary,
      child: Column(
        children: attachments.map((attachment) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file_rounded),
            title: Text(
              attachment['name']?.toString() ?? 'Attachment',
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: attachment['size'] is num
                ? Text(
                    FileUtils.formatBytes((attachment['size'] as num).toInt()),
                  )
                : null,
            trailing: TextButton(
              onPressed: () => _openAttachment(context, attachment),
              child: const Text('Open'),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openAttachment(
    BuildContext context,
    Map<String, dynamic> attachment,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = await AssignmentService.instance.createAttachmentUrl(
      attachment,
    );
    if (url == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No attachment available.')),
      );
      return;
    }
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open attachment.')),
      );
    }
  }
}

class _ExistingSubmissionCard extends StatelessWidget {
  const _ExistingSubmissionCard({
    required this.submission,
    required this.onOpenFile,
    required this.onViewResult,
  });

  final SubmissionModel? submission;
  final VoidCallback? onOpenFile;
  final VoidCallback? onViewResult;

  @override
  Widget build(BuildContext context) {
    if (submission == null) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'Latest Submission',
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submitted ${FileUtils.formatDateTime(submission!.submittedAt)}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          Text('Status: ${submission!.status}', style: AppTextStyles.bodySmall),
          if (submission!.fileName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    submission!.fileName!,
                    style: AppTextStyles.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(onPressed: onOpenFile, child: const Text('Open')),
              ],
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onViewResult,
            icon: const Icon(Icons.grade_rounded, size: 16),
            label: const Text('View Result'),
          ),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.selectedFile,
    required this.onPickFile,
    required this.onClearFile,
  });

  final PlatformFile? selectedFile;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'File Upload',
      icon: Icons.upload_file_rounded,
      iconColor: AppColors.emerald,
      child: selectedFile == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload a document, archive, or image as part of your submission.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onPickFile,
                  icon: const Icon(Icons.folder_open_rounded, size: 14),
                  label: const Text('Choose File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedFile!.name, style: AppTextStyles.label),
                      Text(
                        FileUtils.formatBytes(selectedFile!.size),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClearFile,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
    );
  }
}

class _WrittenResponseCard extends StatelessWidget {
  const _WrittenResponseCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Written Response',
      icon: Icons.edit_rounded,
      iconColor: AppColors.amber,
      child: TextField(
        controller: controller,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Add notes or a written answer for your instructor...',
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
