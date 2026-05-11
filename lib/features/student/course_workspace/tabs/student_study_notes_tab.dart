import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../features/shared/study_notes/study_note_reader_page.dart';
import '../../../../models/material_model.dart';
import '../../../../models/study_note_model.dart';
import '../../../../services/gemini_ai_service.dart';
import '../../../../services/material_service.dart';
import '../../../../services/study_note_service.dart';
import '../../../ai_controls/providers/ai_controls_provider.dart';
import '../../../permissions/providers/permissions_provider.dart';

class StudentStudyNotesTab extends ConsumerStatefulWidget {
  const StudentStudyNotesTab({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<StudentStudyNotesTab> createState() => _StudentStudyNotesTabState();
}

class _StudentStudyNotesTabState extends ConsumerState<StudentStudyNotesTab> {
  late Future<_StudyNotesTabData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StudyNotesTabData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _StudyNotesTabData([], []);
        final aiControls = ref.watch(aiControlsProvider).valueOrDefaults;
        final canGenerate =
            ref.watch(permissionsProvider).valueOrDefaults.generateStudyNotes &&
            aiControls.canStudentGenerateStudyNotes;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Study Notes', style: AppTextStyles.h2)),
                  if (canGenerate)
                    ElevatedButton.icon(
                      onPressed:
                          snapshot.connectionState == ConnectionState.done
                          ? () => _openGenerateDialog(data.materials)
                          : null,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('Generate'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${data.notes.length} private revision sheets',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (data.notes.isEmpty)
                const EmptyState(
                  icon: Icons.note_alt_rounded,
                  title: 'No study notes yet',
                  subtitle:
                      'Generate private revision sheets from your course materials.',
                )
              else
                ...data.notes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StudyNoteCard(
                      note: note,
                      onOpen: () => _openNotePage(note),
                      onEdit: () => _edit(note),
                      onDelete: () => _delete(note),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<_StudyNotesTabData> _load() async {
    final notes = await StudyNoteService.instance.getCourseNotes(
      widget.courseId,
    );
    final materials = await MaterialService.instance.getCourseMaterials(
      widget.courseId,
    );
    return _StudyNotesTabData(notes, materials);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openGenerateDialog(List<MaterialModel> materials) async {
    if (materials.isEmpty) {
      _showMessage('No course materials are available yet.', isError: true);
      return;
    }
    final promptController = TextEditingController();
    var selectedIds = materials.map((material) => material.id).toSet();
    var isGenerating = false;

    final generated = await showDialog<StudyNoteModel>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> generate() async {
              if (selectedIds.isEmpty) {
                _showMessage('Select at least one material.', isError: true);
                return;
              }
              setDialogState(() => isGenerating = true);
              try {
                final selectedMaterials = materials
                    .where((material) => selectedIds.contains(material.id))
                    .toList();
                final draft = await GeminiAiService.instance
                    .generateStudyNoteDraft(
                      courseId: widget.courseId,
                      materials: selectedMaterials,
                      prompt: promptController.text,
                    );
                final saved = await StudyNoteService.instance.createNote(
                  courseId: widget.courseId,
                  title: draft.title,
                  prompt: promptController.text,
                  materialIds: draft.materialIds.isEmpty
                      ? selectedMaterials
                            .map((material) => material.id)
                            .toList()
                      : draft.materialIds,
                  content: draft.content,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, saved);
                }
              } catch (error) {
                setDialogState(() => isGenerating = false);
                _showMessage(error.toString(), isError: true);
              }
            }

            return AlertDialog(
              title: const Text('Generate Study Notes'),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: promptController,
                        enabled: !isGenerating,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Optional prompt',
                          hintText: 'Focus on definitions, examples, steps...',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text('Materials', style: AppTextStyles.label),
                          const Spacer(),
                          TextButton(
                            onPressed: isGenerating
                                ? null
                                : () => setDialogState(() {
                                    selectedIds = materials
                                        .map((material) => material.id)
                                        .toSet();
                                  }),
                            child: const Text('All'),
                          ),
                          TextButton(
                            onPressed: isGenerating
                                ? null
                                : () => setDialogState(selectedIds.clear),
                            child: const Text('None'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...materials.map(
                        (material) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: selectedIds.contains(material.id),
                          onChanged: isGenerating
                              ? null
                              : (checked) => setDialogState(() {
                                  if (checked ?? false) {
                                    selectedIds.add(material.id);
                                  } else {
                                    selectedIds.remove(material.id);
                                  }
                                }),
                          title: Text(
                            material.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(material.fileType),
                        ),
                      ),
                      if (isGenerating)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isGenerating
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isGenerating ? null : generate,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(isGenerating ? 'Generating...' : 'Generate'),
                ),
              ],
            );
          },
        );
      },
    );

    promptController.dispose();
    if (!mounted || generated == null) return;
    _showMessage('Study notes generated.');
    _refresh();
    _openNotePage(generated);
  }

  Future<void> _openNotePage(
    StudyNoteModel note, {
    bool initialEditing = false,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StudyNoteReaderPage(
          initialNote: note,
          initialEditing: initialEditing,
          onSave: StudyNoteService.instance.updateNote,
          onDelete: StudyNoteService.instance.deleteNote,
        ),
      ),
    );
    if (changed == true && mounted) _refresh();
  }

  Future<void> _edit(StudyNoteModel note) async {
    await _openNotePage(note, initialEditing: true);
  }

  Future<void> _delete(StudyNoteModel note) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Study Notes'),
            content: Text('Delete "${note.title}"?'),
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
    await StudyNoteService.instance.deleteNote(note.id);
    if (!mounted) return;
    _showMessage('Study notes deleted.');
    _refresh();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }
}

class _StudyNoteCard extends StatelessWidget {
  const _StudyNoteCard({
    required this.note,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final StudyNoteModel note;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;
          return Flex(
            direction: isCompact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isCompact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.violetLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.note_alt_rounded,
                      color: AppColors.violet,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: isCompact ? constraints.maxWidth - 48 : 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: AppTextStyles.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${note.materialLabel} - ${note.createdLabel}',
                          style: AppTextStyles.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isCompact) const Spacer() else const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text('Open'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudyNotesTabData {
  const _StudyNotesTabData(this.notes, this.materials);

  final List<StudyNoteModel> notes;
  final List<MaterialModel> materials;
}
