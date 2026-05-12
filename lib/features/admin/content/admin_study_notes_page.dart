import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/shared/study_notes/study_note_reader_page.dart';
import '../../../models/study_note_model.dart';
import '../../../services/study_note_service.dart';

class AdminStudyNotesPage extends StatefulWidget {
  const AdminStudyNotesPage({super.key});

  @override
  State<AdminStudyNotesPage> createState() => _AdminStudyNotesPageState();
}

class _AdminStudyNotesPageState extends State<AdminStudyNotesPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _createdRange;
  Future<List<StudyNoteModel>>? _future;

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

    return FutureBuilder<List<StudyNoteModel>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <StudyNoteModel>[];
        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: 'Study Notes',
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
                      : 'No study notes found',
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
                              Icons.note_alt_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(item.title, style: AppTextStyles.label),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${item.studentLabel}'
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
                                  onPressed: () => _openNotePage(item),
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
                            onTap: () => _openNotePage(item),
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
      _future = StudyNoteService.instance.getAllNotes(
        search: _searchController.text,
        createdRange: _createdRange,
      );
    });
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _openNotePage(
    StudyNoteModel item, {
    bool initialEditing = false,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StudyNoteReaderPage(
          initialNote: item,
          initialEditing: initialEditing,
          showStudent: true,
          onSave: StudyNoteService.instance.updateNote,
          onDelete: StudyNoteService.instance.deleteNote,
        ),
      ),
    );
    if (changed == true && mounted) _load();
  }

  Future<void> _edit(StudyNoteModel item) async {
    await _openNotePage(item, initialEditing: true);
  }

  Future<void> _delete(StudyNoteModel item) async {
    final ok = await _confirm('Delete Study Notes', 'Delete "${item.title}"?');
    if (!ok) return;
    try {
      await StudyNoteService.instance.deleteNote(item.id);
      if (!mounted) return;
      _snack('Study notes deleted');
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
