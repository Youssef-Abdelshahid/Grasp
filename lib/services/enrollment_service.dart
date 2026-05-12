import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enrollment_model.dart';
import 'permissions_service.dart';

class EnrollmentService {
  EnrollmentService._();

  static final instance = EnrollmentService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<EnrollmentModel>> getCourseEnrollments(String courseId) async {
    final response = await _client
        .from('enrollments')
        .select('*, profiles!enrollments_student_id_fkey(full_name, email)')
        .eq('course_id', courseId)
        .order('enrolled_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) =>
              EnrollmentModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> enrollStudent({
    required String courseId,
    required String studentEmail,
  }) async {
    await PermissionsService.instance
        .requireInstructorCourseStudentsManagement();
    final normalizedEmail = studentEmail.trim().toLowerCase();
    final profile = await _client
        .from('profiles')
        .select('id, role')
        .eq('email', normalizedEmail)
        .maybeSingle();

    if (profile == null) {
      throw const EnrollmentException(
        'No student account was found with that email, or your account is not allowed to view it yet.',
      );
    }

    final data = Map<String, dynamic>.from(profile);
    if ((data['role'] as String? ?? '') != 'student') {
      throw const EnrollmentException('Only student accounts can be enrolled.');
    }

    await _client.from('enrollments').upsert({
      'course_id': courseId,
      'student_id': data['id'] as String,
      'status': 'active',
    });
  }

  Future<void> unenrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    await PermissionsService.instance
        .requireInstructorCourseStudentsManagement();
    await _client
        .from('enrollments')
        .delete()
        .eq('course_id', courseId)
        .eq('student_id', studentId);
  }
}

class EnrollmentException implements Exception {
  const EnrollmentException(this.message);

  final String message;

  @override
  String toString() => message;
}
