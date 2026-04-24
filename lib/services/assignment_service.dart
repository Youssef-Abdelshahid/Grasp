import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment_model.dart';

class AssignmentService {
  AssignmentService._();

  static final instance = AssignmentService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<AssignmentModel>> getCourseAssignments(String courseId) async {
    final response = await _client
        .from('assignments')
        .select()
        .eq('course_id', courseId)
        .order('is_published', ascending: false)
        .order('due_at', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) =>
            AssignmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<AssignmentModel> getAssignmentDetails(String assignmentId) async {
    final response = await _client
        .from('assignments')
        .select()
        .eq('id', assignmentId)
        .single();
    return AssignmentModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AssignmentModel> createAssignment({
    required String courseId,
    required String title,
    required String instructions,
    required String attachmentRequirements,
    required DateTime? dueAt,
    required int maxPoints,
    required bool isPublished,
    required List<Map<String, dynamic>> rubric,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('assignments')
        .insert({
          'course_id': courseId,
          'title': title.trim(),
          'instructions': instructions.trim(),
          'attachment_requirements': attachmentRequirements.trim(),
          'due_at': dueAt?.toUtc().toIso8601String(),
          'max_points': maxPoints,
          'is_published': isPublished,
          'published_at': isPublished ? DateTime.now().toUtc().toIso8601String() : null,
          'rubric': rubric,
          'created_by': userId,
        })
        .select()
        .single();

    return AssignmentModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AssignmentModel> updateAssignment({
    required String assignmentId,
    required String title,
    required String instructions,
    required String attachmentRequirements,
    required DateTime? dueAt,
    required int maxPoints,
    required bool isPublished,
    required List<Map<String, dynamic>> rubric,
  }) async {
    final response = await _client
        .from('assignments')
        .update({
          'title': title.trim(),
          'instructions': instructions.trim(),
          'attachment_requirements': attachmentRequirements.trim(),
          'due_at': dueAt?.toUtc().toIso8601String(),
          'max_points': maxPoints,
          'is_published': isPublished,
          'published_at':
              isPublished ? DateTime.now().toUtc().toIso8601String() : null,
          'rubric': rubric,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', assignmentId)
        .select()
        .single();

    return AssignmentModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AssignmentModel> setPublished({
    required String assignmentId,
    required bool isPublished,
  }) async {
    final response = await _client
        .from('assignments')
        .update({
          'is_published': isPublished,
          'published_at':
              isPublished ? DateTime.now().toUtc().toIso8601String() : null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', assignmentId)
        .select()
        .single();

    return AssignmentModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _client.from('assignments').delete().eq('id', assignmentId);
  }
}
