import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/shared/flashcards/flashcard_editor_sheet.dart';
import '../../../models/flashcard_model.dart';
import '../../../services/flashcard_service.dart';

class AdminFlashcardsPage extends StatefulWidget {
  const AdminFlashcardsPage({super.key});

  @override
  State<AdminFlashcardsPage> createState() => _AdminFlashcardsPageState();
}

class _AdminFlashcardsPageState extends State<AdminFlashcardsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _createdRange;
  Future<List<FlashcardModel>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return FutureBuilder<List<FlashcardModel>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <FlashcardModel>[];
        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: 'Flashcards',
                count: items.length,
                onRefresh: _load,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText:
                      'Search title, student, email, course, material, or date...',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children:
                    const [
                      (value: null, label: 'All dates'),
                      (value: 'today', label: 'Today'),
                      (value: '7d', label: 'Last 7 days'),
                      (value: '30d', label: 'Last 30 days'),
                    ].map((range) {
                      return ChoiceChip(
                        label: Text(range.label),
                        selected: _createdRange == range.value,
                        onSelected: (_) {
                          _createdRange = range.value;
                          _load();
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              if (snapshot.hasError)
                _Retry(onRetry: _load)
              else if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (items.isEmpty)
                _Empty(
                  _hasFilters
                      ? 'No results for current filters'
                      : 'No flashcards found',
                )
              else
                _Panel(
                  child: Column(
                    children: items
                        .map(
                          (item) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            leading: Icon(
                              Icons.style_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(item.title, style: AppTextStyles.label),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${item.cardCount} cards - ${item.studentLabel}'
                                '${item.studentSubtitle.isEmpty ? '' : ' (${item.studentSubtitle})'}\n'
                                '${item.courseLabel} - ${item.materialLabel} - ${item.createdLabel}',
                                style: AppTextStyles.caption,
                              ),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'View details',
                                  onPressed: () => _showDetails(item),
                                  icon: Icon(Icons.visibility_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => _edit(item),
                                  icon: Icon(Icons.edit_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _delete(item),
                                  icon: Icon(
                                    Icons.delete_rounded,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _showDetails(item),
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

  bool get _hasFilters {
    return _searchController.text.trim().isNotEmpty || _createdRange != null;
  }

  void _load() {
    setState(() {
      _future = FlashcardService.instance.getAllFlashcards(
        search: _searchController.text,
        createdRange: _createdRange,
      );
    });
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _showDetails(FlashcardModel item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title, style: AppTextStyles.h2),
                const SizedBox(height: 16),
                _DetailRow('Student', item.studentLabel),
                if (item.studentSubtitle.isNotEmpty)
                  _DetailRow('Email', item.studentSubtitle),
                _DetailRow('Course', item.courseLabel),
                _DetailRow('Materials', item.materialLabel),
                _DetailRow('Created', item.createdLabel),
                const SizedBox(height: 16),
                ...item.cards.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      tileColor: AppColors.background,
                      title: Text(entry.value.front),
                      subtitle: Text(entry.value.back),
                      trailing: entry.value.tag.isEmpty
                          ? null
                          : Chip(label: Text(entry.value.tag)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(FlashcardModel item) async {
    final saved = await showModalBottomSheet<FlashcardModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FlashcardEditorSheet(
        initial: item,
        onSave: FlashcardService.instance.updateFlashcards,
      ),
    );
    if (saved == null || !mounted) return;
    _snack('Flashcards updated');
    _load();
  }

  Future<void> _delete(FlashcardModel item) async {
    final ok = await _confirm('Delete Flashcards', 'Delete "${item.title}"?');
    if (!ok) return;
    try {
      await FlashcardService.instance.deleteFlashcards(item.id);
      if (!mounted) return;
      _snack('Flashcards deleted');
      _load();
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.count,
    required this.onRefresh,
  });

  final String title;
  final int count;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.h1)),
        Text(
          '$count',
          style: AppTextStyles.label.copyWith(color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(child: Text(value, style: AppTextStyles.label)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(title, style: AppTextStyles.h3)),
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
  );
}
