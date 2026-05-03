import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flashcard_model.dart';

class FlashcardService {
  FlashcardService._();

  static final instance = FlashcardService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<FlashcardModel>> getCourseFlashcards(String courseId) async {
    final response = await _client
        .from('flashcard_sets')
        .select('*, courses!flashcard_sets_course_id_fkey(title, code)')
        .eq('course_id', courseId)
        .order('created_at', ascending: false);

    final items = _mapList(response);
    return _withMaterialNames(items);
  }

  Future<List<FlashcardModel>> getAllFlashcards({
    String search = '',
    String? courseId,
    String? materialId,
    String? createdRange,
  }) async {
    try {
      final response = await _client.rpc(
        'list_admin_flashcards',
        params: {
          'p_search': search,
          'p_course_id': _nullableUuid(courseId),
          'p_material_id': _nullableUuid(materialId),
          'p_created_range': _nullableFilter(createdRange),
        },
      );
      return _mapList(response);
    } on PostgrestException catch (error) {
      if (!_isRpcSignatureError(error)) rethrow;
      return _listAdminFlashcardsFromTables(
        search: search,
        courseId: courseId,
        materialId: materialId,
        createdRange: createdRange,
      );
    }
  }

  Future<List<FlashcardModel>> _listAdminFlashcardsFromTables({
    required String search,
    required String? courseId,
    required String? materialId,
    required String? createdRange,
  }) async {
    dynamic query = _client
        .from('flashcard_sets')
        .select(
          '*, courses!flashcard_sets_course_id_fkey(title, code), '
          'profiles!flashcard_sets_student_id_fkey(full_name, email)',
        );

    final selectedCourseId = _nullableUuid(courseId);
    if (selectedCourseId != null) {
      query = query.eq('course_id', selectedCourseId);
    }

    final rows =
        (await query.order('created_at', ascending: false)) as List<dynamic>;
    var items = await _withMaterialNames(_mapList(rows));

    final selectedMaterialId = _nullableUuid(materialId);
    if (selectedMaterialId != null) {
      items = items
          .where((item) => item.materialIds.contains(selectedMaterialId))
          .toList();
    }

    final cutoff = _rangeCutoff(createdRange);
    if (cutoff != null) {
      items = items.where((item) => item.createdAt.isAfter(cutoff)).toList();
    }

    final needle = search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      items = items.where((item) {
        final haystack = [
          item.title,
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

  Future<FlashcardModel> createFlashcards({
    required String courseId,
    required String title,
    required String prompt,
    required String difficulty,
    required List<String> materialIds,
    required List<FlashcardItem> cards,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('flashcard_sets')
        .insert({
          'course_id': courseId,
          'student_id': userId,
          'title': title.trim(),
          'prompt': prompt.trim(),
          'difficulty': difficulty.trim(),
          'selected_material_ids': materialIds,
          'cards': cards.map((card) => card.toJson()).toList(),
        })
        .select('*, courses!flashcard_sets_course_id_fkey(title, code)')
        .single();

    final items = await _withMaterialNames([
      FlashcardModel.fromJson(Map<String, dynamic>.from(response)),
    ]);
    return items.single;
  }

  Future<FlashcardModel> updateFlashcards(FlashcardModel flashcards) async {
    final response = await _client
        .from('flashcard_sets')
        .update({
          ...flashcards.toUpdateJson(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', flashcards.id)
        .select('*, courses!flashcard_sets_course_id_fkey(title, code)')
        .single();

    final items = await _withMaterialNames([
      FlashcardModel.fromJson(Map<String, dynamic>.from(response)),
    ]);
    return items.single;
  }

  Future<void> deleteFlashcards(String flashcardSetId) async {
    await _client.from('flashcard_sets').delete().eq('id', flashcardSetId);
  }

  List<FlashcardModel> _mapList(dynamic response) {
    return (response as List<dynamic>? ?? const [])
        .map(
          (item) =>
              FlashcardModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<FlashcardModel>> _withMaterialNames(
    List<FlashcardModel> items,
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

  String? _nullableUuid(String? value) {
    if (value == null || value.trim().isEmpty || value == 'all') return null;
    return value.trim();
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
