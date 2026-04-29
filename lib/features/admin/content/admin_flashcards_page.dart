import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/flashcard_model.dart';
import '../../../services/flashcard_service.dart';

class AdminFlashcardsPage extends StatefulWidget {
  const AdminFlashcardsPage({super.key});

  @override
  State<AdminFlashcardsPage> createState() => _AdminFlashcardsPageState();
}

class _AdminFlashcardsPageState extends State<AdminFlashcardsPage> {
  late Future<List<FlashcardModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FlashcardService.instance.getAllFlashcards();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FlashcardModel>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <FlashcardModel>[];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Flashcards', style: AppTextStyles.h1)),
                  IconButton.filledTonal(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                _Panel(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No flashcards found',
                        style: AppTextStyles.h3,
                      ),
                    ),
                  ),
                )
              else
                _Panel(
                  child: Column(
                    children: items
                        .map(
                          (item) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            leading: const Icon(
                              Icons.style_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(item.title, style: AppTextStyles.label),
                            subtitle: Text(
                              '${item.cardCount} cards - student ${item.studentId}',
                              style: AppTextStyles.caption,
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'View',
                                  onPressed: () => _showDetails(item),
                                  icon: const Icon(Icons.visibility_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => _edit(item),
                                  icon: const Icon(Icons.edit_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _delete(item),
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _refresh() {
    setState(() {
      _future = FlashcardService.instance.getAllFlashcards();
    });
  }

  void _showDetails(FlashcardModel item) {
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
              const SizedBox(height: 8),
              Text(
                'Owner: ${item.studentId}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              ...item.cards.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    tileColor: AppColors.background,
                    title: Text(card.front),
                    subtitle: Text(card.back),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(FlashcardModel item) async {
    final titleController = TextEditingController(text: item.title);
    final cardControllers = item.cards
        .map(
          (card) => (
            front: TextEditingController(text: card.front),
            back: TextEditingController(text: card.back),
            tag: TextEditingController(text: card.tag),
          ),
        )
        .toList();

    final saved = await showDialog<FlashcardModel>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Flashcards'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                ...cardControllers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: entry.value.front,
                          decoration: InputDecoration(
                            labelText: 'Card ${entry.key + 1} front',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: entry.value.back,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Card ${entry.key + 1} back',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: entry.value.tag,
                          decoration: const InputDecoration(labelText: 'Tag'),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = FlashcardModel(
                id: item.id,
                courseId: item.courseId,
                studentId: item.studentId,
                title: titleController.text,
                prompt: item.prompt,
                difficulty: item.difficulty,
                materialIds: item.materialIds,
                cards: cardControllers
                    .map(
                      (controllers) => FlashcardItem(
                        front: controllers.front.text,
                        back: controllers.back.text,
                        tag: controllers.tag.text,
                      ),
                    )
                    .where(
                      (card) =>
                          card.front.trim().isNotEmpty &&
                          card.back.trim().isNotEmpty,
                    )
                    .toList(),
                createdAt: item.createdAt,
                updatedAt: DateTime.now(),
              );
              final result = await FlashcardService.instance.updateFlashcards(
                updated,
              );
              if (context.mounted) Navigator.pop(context, result);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    titleController.dispose();
    for (final controllers in cardControllers) {
      controllers.front.dispose();
      controllers.back.dispose();
      controllers.tag.dispose();
    }
    if (saved == null || !mounted) return;
    _refresh();
  }

  Future<void> _delete(FlashcardModel item) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Flashcards'),
            content: Text('Delete "${item.title}"?'),
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
    await FlashcardService.instance.deleteFlashcards(item.id);
    if (mounted) _refresh();
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
