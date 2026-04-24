import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quiz_model.dart';

class QuizService {
  QuizService._();

  static final instance = QuizService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<QuizModel>> getCourseQuizzes(String courseId) async {
    final response = await _client
        .from('quizzes')
        .select()
        .eq('course_id', courseId)
        .order('is_published', ascending: false)
        .order('due_at', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => QuizModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<QuizModel> getQuizDetails(String quizId) async {
    final response =
        await _client.from('quizzes').select().eq('id', quizId).single();
    return QuizModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<QuizModel> createQuiz({
    required String courseId,
    required String title,
    required String description,
    required String instructions,
    required DateTime? dueAt,
    required int maxPoints,
    required int? durationMinutes,
    required bool isPublished,
    required List<Map<String, dynamic>> questionSchema,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('quizzes')
        .insert({
          'course_id': courseId,
          'title': title.trim(),
          'description': description.trim(),
          'instructions': instructions.trim(),
          'due_at': dueAt?.toUtc().toIso8601String(),
          'max_points': maxPoints,
          'duration_minutes': durationMinutes,
          'is_published': isPublished,
          'published_at': isPublished ? DateTime.now().toUtc().toIso8601String() : null,
          'question_schema': questionSchema,
          'created_by': userId,
        })
        .select()
        .single();

    return QuizModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<QuizModel> updateQuiz({
    required String quizId,
    required String title,
    required String description,
    required String instructions,
    required DateTime? dueAt,
    required int maxPoints,
    required int? durationMinutes,
    required bool isPublished,
    required List<Map<String, dynamic>> questionSchema,
  }) async {
    final response = await _client
        .from('quizzes')
        .update({
          'title': title.trim(),
          'description': description.trim(),
          'instructions': instructions.trim(),
          'due_at': dueAt?.toUtc().toIso8601String(),
          'max_points': maxPoints,
          'duration_minutes': durationMinutes,
          'is_published': isPublished,
          'published_at':
              isPublished ? DateTime.now().toUtc().toIso8601String() : null,
          'question_schema': questionSchema,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', quizId)
        .select()
        .single();

    return QuizModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<QuizModel> setPublished({
    required String quizId,
    required bool isPublished,
  }) async {
    final response = await _client
        .from('quizzes')
        .update({
          'is_published': isPublished,
          'published_at':
              isPublished ? DateTime.now().toUtc().toIso8601String() : null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', quizId)
        .select()
        .single();

    return QuizModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteQuiz(String quizId) async {
    await _client.from('quizzes').delete().eq('id', quizId);
  }
}
