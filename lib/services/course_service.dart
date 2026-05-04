import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_model.dart';

class CourseService {
  CourseService._();

  static final instance = CourseService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<CourseModel>> getInstructorCourses() async {
    final userId = _client.auth.currentUser!.id;
    final assignments = await _client
        .from('course_instructors')
        .select('course_id')
        .eq('instructor_id', userId);
    final assignedIds = (assignments as List<dynamic>)
        .map((item) => (item as Map)['course_id'] as String)
        .toSet();

    final response = await _client
        .from('courses')
        .select('*, profiles!courses_instructor_id_fkey(full_name)')
        .or(
          assignedIds.isEmpty
              ? 'instructor_id.eq.$userId'
              : 'instructor_id.eq.$userId,id.in.(${assignedIds.join(',')})',
        )
        .neq('status', 'archived')
        .order('created_at', ascending: false);

    return _mapCourses(response as List<dynamic>);
  }

  Future<List<CourseModel>> getStudentCourses() async {
    final userId = _client.auth.currentUser!.id;
    final enrollments = await _client
        .from('enrollments')
        .select('course_id')
        .eq('student_id', userId)
        .eq('status', 'active');

    final courseIds = (enrollments as List<dynamic>)
        .map((item) => (item as Map)['course_id'] as String)
        .toList();
    if (courseIds.isEmpty) {
      return [];
    }

    final response = await _client
        .from('courses')
        .select('*, profiles!courses_instructor_id_fkey(full_name)')
        .inFilter('id', courseIds)
        .neq('status', 'archived')
        .order('created_at', ascending: false);

    return _mapCourses(response as List<dynamic>);
  }

  Future<CourseModel> getCourseDetails(String courseId) async {
    final response = await _client
        .from('courses')
        .select('*, profiles!courses_instructor_id_fkey(full_name)')
        .eq('id', courseId)
        .single();

    final course = CourseModel.fromJson(
      await _normalizeCourseJson(Map<String, dynamic>.from(response)),
    );
    final counts = await _getCountsForCourse(course.id);

    return CourseModel(
      id: course.id,
      title: course.title,
      code: course.code,
      studentsCount: counts.studentsCount,
      lecturesCount: counts.materialsCount,
      instructor: course.instructor,
      instructorId: course.instructorId,
      instructors: course.instructors,
      description: course.description,
      status: course.status,
      semester: course.semester,
      maxStudents: course.maxStudents,
      allowSelfEnrollment: course.allowSelfEnrollment,
      isVisible: course.isVisible,
      createdAt: course.createdAt,
    );
  }

  Future<CourseModel> createCourse({
    required String title,
    required String code,
    required String description,
    required String semester,
    required int maxStudents,
    required bool allowSelfEnrollment,
    required bool isVisible,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('courses')
        .insert({
          'title': title.trim(),
          'code': code.trim().toUpperCase(),
          'description': description.trim(),
          'semester': semester.trim(),
          'max_students': maxStudents,
          'allow_self_enrollment': allowSelfEnrollment,
          'is_visible': isVisible,
          'status': isVisible ? 'published' : 'draft',
          'instructor_id': userId,
        })
        .select('*, profiles!courses_instructor_id_fkey(full_name)')
        .single();

    final created = CourseModel.fromJson(
      await _normalizeCourseJson(Map<String, dynamic>.from(response)),
    );
    await _client.from('course_instructors').upsert({
      'course_id': created.id,
      'instructor_id': userId,
      'assigned_by': userId,
    });

    return getCourseDetails(created.id);
  }

  Future<CourseModel> updateCourse({
    required String courseId,
    required String title,
    required String code,
    required String description,
    required String semester,
    required int maxStudents,
    required bool allowSelfEnrollment,
    required bool isVisible,
  }) async {
    final response = await _client
        .from('courses')
        .update({
          'title': title.trim(),
          'code': code.trim().toUpperCase(),
          'description': description.trim(),
          'semester': semester.trim(),
          'max_students': maxStudents,
          'allow_self_enrollment': allowSelfEnrollment,
          'is_visible': isVisible,
          'status': isVisible ? 'published' : 'draft',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', courseId)
        .select('*, profiles!courses_instructor_id_fkey(full_name)')
        .single();

    final course = CourseModel.fromJson(
      await _normalizeCourseJson(Map<String, dynamic>.from(response)),
    );
    final counts = await _getCountsForCourse(course.id);

    return CourseModel(
      id: course.id,
      title: course.title,
      code: course.code,
      studentsCount: counts.studentsCount,
      lecturesCount: counts.materialsCount,
      instructor: course.instructor,
      instructorId: course.instructorId,
      instructors: course.instructors,
      description: course.description,
      status: course.status,
      semester: course.semester,
      maxStudents: course.maxStudents,
      allowSelfEnrollment: course.allowSelfEnrollment,
      isVisible: course.isVisible,
      createdAt: course.createdAt,
    );
  }

  Future<void> archiveCourse(String courseId) async {
    await _client
        .from('courses')
        .update({
          'status': 'archived',
          'archived_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', courseId);
  }

  Future<void> deleteCourse(String courseId) async {
    await _client.from('courses').delete().eq('id', courseId);
  }

  Future<({int studentsCount, int materialsCount})> _getCountsForCourse(
    String courseId,
  ) async {
    final students = await _client
        .from('enrollments')
        .select('id')
        .eq('course_id', courseId)
        .eq('status', 'active');
    final materials = await _client
        .from('materials')
        .select('id')
        .eq('course_id', courseId);

    return (
      studentsCount: (students as List).length,
      materialsCount: (materials as List).length,
    );
  }

  Future<Map<String, ({int studentsCount, int materialsCount})>> _getCounts(
    List<String> courseIds,
  ) async {
    if (courseIds.isEmpty) {
      return {};
    }

    final students = await _client
        .from('enrollments')
        .select('course_id')
        .inFilter('course_id', courseIds)
        .eq('status', 'active');
    final materials = await _client
        .from('materials')
        .select('course_id')
        .inFilter('course_id', courseIds);

    final studentCounts = <String, int>{};
    for (final item in students as List<dynamic>) {
      final courseId = (item as Map)['course_id'] as String;
      studentCounts.update(courseId, (value) => value + 1, ifAbsent: () => 1);
    }

    final materialCounts = <String, int>{};
    for (final item in materials as List<dynamic>) {
      final courseId = (item as Map)['course_id'] as String;
      materialCounts.update(courseId, (value) => value + 1, ifAbsent: () => 1);
    }

    final result = <String, ({int studentsCount, int materialsCount})>{};
    for (final courseId in courseIds) {
      result[courseId] = (
        studentsCount: studentCounts[courseId] ?? 0,
        materialsCount: materialCounts[courseId] ?? 0,
      );
    }
    return result;
  }

  Future<List<CourseModel>> _mapCourses(List<dynamic> rows) async {
    final normalized = rows
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    for (final item in normalized) {
      await _normalizeCourseJson(item);
    }
    final ids = normalized.map((item) => item['id'] as String).toList();
    final counts = await _getCounts(ids);

    return normalized.map((item) {
      final base = CourseModel.fromJson(item);
      final courseCounts =
          counts[base.id] ?? (studentsCount: 0, materialsCount: 0);
      return CourseModel(
        id: base.id,
        title: base.title,
        code: base.code,
        studentsCount: courseCounts.studentsCount,
        lecturesCount: courseCounts.materialsCount,
        instructor: base.instructor,
        instructorId: base.instructorId,
        instructors: base.instructors,
        description: base.description,
        status: base.status,
        semester: base.semester,
        maxStudents: base.maxStudents,
        allowSelfEnrollment: base.allowSelfEnrollment,
        isVisible: base.isVisible,
        createdAt: base.createdAt,
      );
    }).toList();
  }

  Future<Map<String, dynamic>> _normalizeCourseJson(
    Map<String, dynamic> json,
  ) async {
    final profile = json['profiles'];
    if (profile is Map<String, dynamic>) {
      json['instructor_name'] = profile['full_name'];
    } else if (profile is Map) {
      json['instructor_name'] = profile['full_name'];
    }
    json['instructors'] = await _getCourseInstructors(json['id'] as String);
    return json;
  }

  Future<List<Map<String, dynamic>>> _getCourseInstructors(
    String courseId,
  ) async {
    final response = await _client.rpc(
      'course_instructor_summary',
      params: {'p_course_id': courseId},
    );
    return (response as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
