import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../shared/flashcards/flashcard_editor_sheet.dart';
import '../../../../models/flashcard_model.dart';
import '../../../../models/material_model.dart';
import '../../../../services/flashcard_service.dart';
import '../../../../services/gemini_ai_service.dart';
import '../../../../services/material_service.dart';
import '../../../permissions/providers/permissions_provider.dart';

class StudentFlashcardsTab extends ConsumerStatefulWidget {
  const StudentFlashcardsTab({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<StudentFlashcardsTab> createState() => _StudentFlashcardsTabState();
}

class _StudentFlashcardsTabState extends ConsumerState<StudentFlashcardsTab> {
  late Future<_FlashcardTabData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FlashcardTabData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _FlashcardTabData([], []);
        final canGenerate =
            ref.watch(permissionsProvider).valueOrDefaults.generateFlashcards;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Flashcards', style: AppTextStyles.h2)),
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
                '${data.flashcards.length} private study sets',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (data.flashcards.isEmpty)
                const EmptyState(
                  icon: Icons.style_rounded,
                  title: 'No flashcards yet',
                  subtitle:
                      'Generate private study flashcards from your course materials.',
                )
              else
                ...data.flashcards.map(
                  (set) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FlashcardSetCard(
                      flashcards: set,
                      onStudy: () => _openStudySheet(set),
                      onEdit: () => _edit(set),
                      onDelete: () => _delete(set),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<_FlashcardTabData> _load() async {
    final flashcards = await FlashcardService.instance.getCourseFlashcards(
      widget.courseId,
    );
    final materials = await MaterialService.instance.getCourseMaterials(
      widget.courseId,
    );
    return _FlashcardTabData(flashcards, materials);
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
    final countController = TextEditingController(text: '12');
    var difficulty = 'mixed';
    var selectedIds = materials.map((material) => material.id).toSet();
    var isGenerating = false;

    final generated = await showDialog<FlashcardModel>(
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
                    .generateFlashcardDraft(
                      courseId: widget.courseId,
                      materials: selectedMaterials,
                      prompt: promptController.text,
                      cardCount: int.tryParse(countController.text) ?? 12,
                      difficulty: difficulty,
                    );
                final saved = await FlashcardService.instance.createFlashcards(
                  courseId: widget.courseId,
                  title: draft.title,
                  prompt: promptController.text,
                  difficulty: difficulty,
                  materialIds: draft.materialIds.isEmpty
                      ? selectedMaterials
                            .map((material) => material.id)
                            .toList()
                      : draft.materialIds,
                  cards: draft.cards,
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
              title: const Text('Generate Flashcards'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: countController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cards',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: difficulty,
                              decoration: const InputDecoration(
                                labelText: 'Difficulty',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'mixed',
                                  child: Text('Mixed'),
                                ),
                                DropdownMenuItem(
                                  value: 'easy',
                                  child: Text('Easy'),
                                ),
                                DropdownMenuItem(
                                  value: 'medium',
                                  child: Text('Medium'),
                                ),
                                DropdownMenuItem(
                                  value: 'hard',
                                  child: Text('Hard'),
                                ),
                              ],
                              onChanged: isGenerating
                                  ? null
                                  : (value) => setDialogState(
                                      () => difficulty = value ?? difficulty,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: promptController,
                        enabled: !isGenerating,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Optional prompt',
                          hintText: 'Focus on formulas, examples, key terms...',
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
                                : () => setDialogState(() {
                                    selectedIds.clear();
                                  }),
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
    countController.dispose();
    if (!mounted || generated == null) return;
    _showMessage('Flashcards generated.');
    _refresh();
    _openStudySheet(generated);
  }

  void _openStudySheet(FlashcardModel flashcards) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FlashcardStudySheet(flashcards: flashcards),
    );
  }

  Future<void> _edit(FlashcardModel flashcards) async {
    final saved = await showModalBottomSheet<FlashcardModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FlashcardEditorSheet(
        initial: flashcards,
        onSave: FlashcardService.instance.updateFlashcards,
      ),
    );
    if (saved == null || !mounted) return;
    _showMessage('Flashcards updated.');
    _refresh();
  }

  Future<void> _delete(FlashcardModel flashcards) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Flashcards'),
            content: Text('Delete "${flashcards.title}"?'),
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
    await FlashcardService.instance.deleteFlashcards(flashcards.id);
    if (!mounted) return;
    _showMessage('Flashcards deleted.');
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

class _FlashcardSetCard extends StatelessWidget {
  const _FlashcardSetCard({
    required this.flashcards,
    required this.onStudy,
    required this.onEdit,
    required this.onDelete,
  });

  final FlashcardModel flashcards;
  final VoidCallback onStudy;
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
                      color: AppColors.cyanLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.style_rounded,
                      color: AppColors.cyan,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: isCompact ? constraints.maxWidth - 48 : 260,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flashcards.title,
                          style: AppTextStyles.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${flashcards.cardCount} cards - ${flashcards.materialLabel} - ${flashcards.createdLabel}',
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
                    onPressed: onStudy,
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Study'),
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

class _FlashcardStudySheet extends StatefulWidget {
  const _FlashcardStudySheet({required this.flashcards});

  final FlashcardModel flashcards;

  @override
  State<_FlashcardStudySheet> createState() => _FlashcardStudySheetState();
}

class _FlashcardStudySheetState extends State<_FlashcardStudySheet> {
  int _index = 0;
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final cards = widget.flashcards.cards;
    final card = cards[_index];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.flashcards.title, style: AppTextStyles.h2),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _showBack = !_showBack),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 220),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _showBack ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showBack ? card.back : card.front,
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                    if (card.tag.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Chip(label: Text(card.tag)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('${_index + 1} of ${cards.length}'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _index == 0
                      ? null
                      : () => setState(() {
                          _index--;
                          _showBack = false;
                        }),
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Previous'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _index == cards.length - 1
                      ? null
                      : () => setState(() {
                          _index++;
                          _showBack = false;
                        }),
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardTabData {
  const _FlashcardTabData(this.flashcards, this.materials);

  final List<FlashcardModel> flashcards;
  final List<MaterialModel> materials;
}
