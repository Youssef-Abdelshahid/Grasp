import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flashcard_model.dart';

class FlashcardService {
  FlashcardService._();

  static final instance = FlashcardService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<FlashcardModel>> getCourseFlashcards(String courseId) async {
    final response = await _client
        .from('flashcard_sets')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) =>
              FlashcardModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<FlashcardModel>> getAllFlashcards() async {
    final response = await _client
        .from('flashcard_sets')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) =>
              FlashcardModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
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
        .select()
        .single();

    return FlashcardModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<FlashcardModel> updateFlashcards(FlashcardModel flashcards) async {
    final response = await _client
        .from('flashcard_sets')
        .update({
          ...flashcards.toUpdateJson(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', flashcards.id)
        .select()
        .single();

    return FlashcardModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteFlashcards(String flashcardSetId) async {
    await _client.from('flashcard_sets').delete().eq('id', flashcardSetId);
  }
}
