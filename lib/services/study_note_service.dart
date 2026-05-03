import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/study_note_model.dart';

class StudyNoteService {
  StudyNoteService._();

  static final instance = StudyNoteService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<StudyNoteModel>> getCourseNotes(String courseId) async {
    final response = await _client
        .from('study_notes')
        .select('*, courses!study_notes_course_id_fkey(title, code)')
        .eq('course_id', courseId)
        .order('created_at', ascending: false);

    final items = _mapList(response);
    return _withMaterialNames(items);
  }

  Future<List<StudyNoteModel>> getAllNotes({
    String search = '',
    String? createdRange,
  }) async {
    try {
      final response = await _client.rpc(
        'list_admin_study_notes',
        params: {
          'p_search': search,
          'p_created_range': _nullableFilter(createdRange),
        },
      );
      return _mapList(response);
    } on PostgrestException catch (error) {
      if (!_isRpcSignatureError(error)) rethrow;
      return _listAdminNotesFromTables(
        search: search,
        createdRange: createdRange,
      );
    }
  }

  Future<StudyNoteModel> createNote({
    required String courseId,
    required String title,
    required String prompt,
    required List<String> materialIds,
    required String content,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('study_notes')
        .insert({
          'course_id': courseId,
          'student_id': userId,
          'title': title.trim(),
          'prompt': prompt.trim(),
          'selected_material_ids': materialIds,
          'content': content.trim(),
        })
        .select('*, courses!study_notes_course_id_fkey(title, code)')
        .single();

    final items = await _withMaterialNames([
      StudyNoteModel.fromJson(Map<String, dynamic>.from(response)),
    ]);
    return items.single;
  }

  Future<StudyNoteModel> updateNote(StudyNoteModel note) async {
    final response = await _client
        .from('study_notes')
        .update({
          ...note.toUpdateJson(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', note.id)
        .select('*, courses!study_notes_course_id_fkey(title, code)')
        .single();

    final items = await _withMaterialNames([
      StudyNoteModel.fromJson(Map<String, dynamic>.from(response)),
    ]);
    return items.single;
  }

  Future<void> deleteNote(String noteId) async {
    await _client.from('study_notes').delete().eq('id', noteId);
  }

  Future<List<StudyNoteModel>> _listAdminNotesFromTables({
    required String search,
    required String? createdRange,
  }) async {
    final rows =
        (await _client
                .from('study_notes')
                .select(
                  '*, courses!study_notes_course_id_fkey(title, code), '
                  'profiles!study_notes_student_id_fkey(full_name, email)',
                )
                .order('created_at', ascending: false))
            as List<dynamic>;
    var items = await _withMaterialNames(_mapList(rows));

    final cutoff = _rangeCutoff(createdRange);
    if (cutoff != null) {
      items = items.where((item) => item.createdAt.isAfter(cutoff)).toList();
    }

    final needle = search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      items = items.where((item) {
        final haystack = [
          item.title,
          item.content,
          item.studentName,
          item.studentEmail,
          item.courseTitle,
          item.courseCode,
          ...item.materialNames,
          item.createdLabel,
        ].join(' ').toLowerCase();
        return haystack.contains(needle);
      }).toList();
    }

    return items;
  }

  List<StudyNoteModel> _mapList(dynamic response) {
    return (response as List<dynamic>? ?? const [])
        .map(
          (item) =>
              StudyNoteModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<StudyNoteModel>> _withMaterialNames(
    List<StudyNoteModel> items,
  ) async {
    final materialIds = {
      for (final item in items) ...item.materialIds,
    }.where((id) => id.isNotEmpty).toList();
    if (materialIds.isEmpty) return items;

    final response = await _client
        .from('materials')
        .select('id, title')
        .inFilter('id', materialIds);
    final namesById = {
      for (final row in response as List<dynamic>)
        (row as Map)['id'] as String: row['title'] as String? ?? '',
    };

    return items
        .map(
          (item) => item.copyWith(
            materialNames: item.materialIds
                .map((id) => namesById[id] ?? '')
                .where((name) => name.trim().isNotEmpty)
                .toList(),
          ),
        )
        .toList();
  }

  String? _nullableFilter(String? value) {
    if (value == null || value.trim().isEmpty || value == 'all') return null;
    return value.trim();
  }

  DateTime? _rangeCutoff(String? value) {
    final now = DateTime.now();
    switch (_nullableFilter(value)) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
    }
    return null;
  }

  bool _isRpcSignatureError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return message.contains('function') ||
        message.contains('schema cache') ||
        message.contains('could not choose') ||
        message.contains('ambiguous');
  }
}
