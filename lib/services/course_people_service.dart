import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/basic_profile_model.dart';

class CoursePeopleService {
  CoursePeopleService._();

  static final instance = CoursePeopleService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<BasicProfileModel>> listCourseStudents(String courseId) async {
    try {
      final response = await _client.rpc(
        'list_course_students_basic',
        params: {'p_course_id': courseId},
      );
      return (response as List<dynamic>? ?? const [])
          .map(
            (item) => BasicProfileModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw CoursePeopleException(_friendlyError(error));
    }
  }

  String _friendlyError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('not found')) {
      return 'Profile not found.';
    }
    if (message.contains('access') || message.contains('permission')) {
      return 'You do not have access to view this profile.';
    }
    return 'Profile could not be loaded.';
  }
}

class CoursePeopleException implements Exception {
  const CoursePeopleException(this.message);

  final String message;

  @override
  String toString() => message;
}
