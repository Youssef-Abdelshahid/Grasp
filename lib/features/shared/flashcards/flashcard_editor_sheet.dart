import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/flashcard_model.dart';

class FlashcardEditorSheet extends StatefulWidget {
  const FlashcardEditorSheet({
    super.key,
    required this.initial,
    required this.onSave,
  });

  final FlashcardModel initial;
  final Future<FlashcardModel> Function(FlashcardModel flashcards) onSave;

  @override
  State<FlashcardEditorSheet> createState() => _FlashcardEditorSheetState();
}

class _FlashcardEditorSheetState extends State<FlashcardEditorSheet> {
  late final TextEditingController _title;
  late List<_CardControllers> _cards;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial.title);
    _cards = widget.initial.cards
        .map((card) => _CardControllers.fromCard(card))
        .toList();
    if (_cards.isEmpty) _cards.add(_CardControllers.empty());
  }

  @override
  void dispose() {
    _title.dispose();
    for (final card in _cards) {
      card.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Edit Flashcards', style: AppTextStyles.h2),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set title', style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _title,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        hintText: 'Flashcard set title',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 2,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Cards', style: AppTextStyles.label),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _saving ? null : _addCard,
                          icon: Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add card'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._cards.asMap().entries.map(
                      (entry) => _EditableCard(
                        index: entry.key,
                        controllers: entry.value,
                        enabled: !_saving,
                        canRemove: _cards.length > 1,
                        onRemove: () => _removeCard(entry.key),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_saving) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: Icon(Icons.save_rounded, size: 16),
                    label: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addCard() {
    setState(() => _cards.add(_CardControllers.empty()));
  }

  void _removeCard(int index) {
    final removed = _cards.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    final cards = _cards
        .map((controllers) => controllers.toCard())
        .where(
          (card) => card.front.trim().isNotEmpty && card.back.trim().isNotEmpty,
        )
        .toList();
    if (_title.text.trim().isEmpty) {
      _snack('Add a title before saving.', isError: true);
      return;
    }
    if (cards.isEmpty) {
      _snack('Add at least one complete card.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await widget.onSave(
        widget.initial.copyWith(title: _title.text, cards: cards),
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
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

class _EditableCard extends StatelessWidget {
  const _EditableCard({
    required this.index,
    required this.controllers,
    required this.enabled,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _CardControllers controllers;
  final bool enabled;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Card ${index + 1}', style: AppTextStyles.label),
              ),
              IconButton(
                tooltip: 'Remove card',
                onPressed: enabled && canRemove ? onRemove : null,
                icon: Icon(Icons.delete_rounded, color: AppColors.error),
              ),
            ],
          ),
          TextField(
            controller: controllers.front,
            enabled: enabled,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Front / question'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controllers.back,
            enabled: enabled,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Back / answer'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controllers.tag,
            enabled: enabled,
            decoration: const InputDecoration(labelText: 'Tag / topic'),
          ),
        ],
      ),
    );
  }
}

class _CardControllers {
  _CardControllers({
    required this.front,
    required this.back,
    required this.tag,
    required this.sourceReference,
  });

  factory _CardControllers.fromCard(FlashcardItem card) {
    return _CardControllers(
      front: TextEditingController(text: card.front),
      back: TextEditingController(text: card.back),
      tag: TextEditingController(text: card.tag),
      sourceReference: card.sourceReference,
    );
  }

  factory _CardControllers.empty() {
    return _CardControllers(
      front: TextEditingController(),
      back: TextEditingController(),
      tag: TextEditingController(),
      sourceReference: const {},
    );
  }

  final TextEditingController front;
  final TextEditingController back;
  final TextEditingController tag;
  final Map<String, dynamic> sourceReference;

  FlashcardItem toCard() {
    return FlashcardItem(
      front: front.text,
      back: back.text,
      tag: tag.text,
      sourceReference: sourceReference,
    );
  }

  void dispose() {
    front.dispose();
    back.dispose();
    tag.dispose();
  }
}
