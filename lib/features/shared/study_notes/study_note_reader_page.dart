import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/study_note_model.dart';
import 'study_note_formatting.dart';

class StudyNoteReaderPage extends StatefulWidget {
  const StudyNoteReaderPage({
    super.key,
    required this.initialNote,
    required this.onSave,
    required this.onDelete,
    this.showStudent = false,
    this.initialEditing = false,
  });

  final StudyNoteModel initialNote;
  final Future<StudyNoteModel> Function(StudyNoteModel note) onSave;
  final Future<void> Function(String noteId) onDelete;
  final bool showStudent;
  final bool initialEditing;

  @override
  State<StudyNoteReaderPage> createState() => _StudyNoteReaderPageState();
}

class _StudyNoteReaderPageState extends State<StudyNoteReaderPage> {
  late StudyNoteModel _note;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _editing = false;
  bool _saving = false;
  bool _deleting = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _note = widget.initialNote;
    _editing = widget.initialEditing;
    _titleController = TextEditingController(text: _note.title);
    _contentController = TextEditingController(text: _note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: Text(
            _editing ? 'Edit Study Notes' : 'Study Notes',
            style: AppTextStyles.label,
          ),
          actions: [
            if (_editing) ...[
              TextButton(
                onPressed: _saving ? null : _cancelEdit,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: Icon(Icons.save_rounded, size: 16),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ),
            ] else ...[
              IconButton(
                tooltip: 'Edit',
                onPressed: _deleting
                    ? null
                    : () => setState(() => _editing = true),
                icon: Icon(Icons.edit_rounded),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: _deleting ? null : _delete,
                icon: Icon(Icons.delete_rounded, color: AppColors.error),
              ),
              const SizedBox(width: 8),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: _editing ? _buildEditor() : _buildReader(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(_note.title, style: AppTextStyles.h1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.menu_book_rounded,
                label: _note.courseLabel,
              ),
              _MetaChip(
                icon: Icons.attach_file_rounded,
                label: _note.materialLabel,
              ),
              _MetaChip(
                icon: Icons.schedule_rounded,
                label: _note.createdLabel,
              ),
              if (widget.showStudent)
                _MetaChip(
                  icon: Icons.person_rounded,
                  label: _note.studentLabel,
                ),
            ],
          ),
          if (_note.updatedAt.isAfter(_note.createdAt)) ...[
            const SizedBox(height: 8),
            Text('Updated ${_note.updatedLabel}', style: AppTextStyles.caption),
          ],
          const SizedBox(height: 24),
          Divider(height: 1),
          const SizedBox(height: 8),
          StudyNoteContentView(content: _note.content),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            enabled: !_saving,
            minLines: 24,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Content',
              alignLabelWithHint: true,
            ),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _cancelEdit() {
    _titleController.text = _note.title;
    _contentController.text = _note.content;
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.length < 40) {
      _snack('Add a title and detailed note content.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await widget.onSave(
        _note.copyWith(title: title, content: cleanStudyNoteText(content)),
      );
      if (!mounted) return;
      setState(() {
        _note = saved;
        _titleController.text = saved.title;
        _contentController.text = saved.content;
        _editing = false;
        _saving = false;
        _changed = true;
      });
      _snack('Study notes updated.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(error.toString(), isError: true);
    }
  }

  Future<void> _delete() async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Study Notes'),
            content: Text('Delete "${_note.title}"?'),
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

    setState(() => _deleting = true);
    try {
      await widget.onDelete(_note.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _snack(error.toString(), isError: true);
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
