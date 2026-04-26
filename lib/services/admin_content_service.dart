import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_content_models.dart';
import '../models/admin_models.dart';
import 'material_service.dart';

class AdminContentService {
  AdminContentService._();

  static final instance = AdminContentService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<AdminCourseItem>> listCourses({
    String search = '',
    String? status,
  }) async {
    final response = await _client.rpc(
      'list_admin_courses',
      params: {'p_search': search, 'p_status': status},
    );
    return _mapList(response, AdminCourseItem.fromJson);
  }

  Future<void> saveCourse({
    String? courseId,
    required String title,
    required String code,
    required String description,
    required String instructorId,
    required String status,
    required String semester,
    required int maxStudents,
    required bool allowSelfEnrollment,
    required bool isVisible,
  }) async {
    await _client.rpc(
      'admin_save_course',
      params: {
        'p_course_id': courseId,
        'p_title': title,
        'p_code': code,
        'p_description': description,
        'p_instructor_id': instructorId,
        'p_status': status,
        'p_semester': semester,
        'p_max_students': maxStudents,
        'p_allow_self_enrollment': allowSelfEnrollment,
        'p_is_visible': isVisible,
      },
    );
  }

  Future<void> archiveCourse(String courseId) async {
    await _client.rpc(
      'admin_archive_course',
      params: {'p_course_id': courseId},
    );
  }

  Future<void> deleteCourseSafely(String courseId) async {
    await _client.rpc(
      'admin_delete_course_safe',
      params: {'p_course_id': courseId},
    );
  }

  Future<void> logAdminAction({
    required String action,
    required String summary,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _client.rpc(
      'admin_log_activity',
      params: {
        'p_action': action,
        'p_summary': summary,
        'p_metadata': metadata,
      },
    );
  }

  Future<AdminCourseMembers> getCourseMembers(String courseId) async {
    final response = await _client.rpc(
      'get_admin_course_members',
      params: {'p_course_id': courseId},
    );
    return AdminCourseMembers.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<void> assignCourseInstructor({
    required String courseId,
    required String instructorId,
  }) async {
    await _client.rpc(
      'admin_assign_course_instructor',
      params: {'p_course_id': courseId, 'p_instructor_id': instructorId},
    );
  }

  Future<void> addCourseStudent({
    required String courseId,
    required String studentId,
  }) async {
    await _client.rpc(
      'admin_add_course_student',
      params: {'p_course_id': courseId, 'p_student_id': studentId},
    );
  }

  Future<void> removeCourseStudent({
    required String courseId,
    required String studentId,
  }) async {
    await _client.rpc(
      'admin_remove_course_student',
      params: {'p_course_id': courseId, 'p_student_id': studentId},
    );
  }

  Future<List<AdminMaterialItem>> listMaterials({
    String search = '',
    String? courseId,
    String? fileType,
  }) async {
    final response = await _client.rpc(
      'list_admin_materials',
      params: {
        'p_search': search,
        'p_course_id': _nullableUuid(courseId),
        'p_file_type': fileType,
      },
    );
    return _mapList(response, AdminMaterialItem.fromJson);
  }

  Future<void> updateMaterial({
    required String materialId,
    required String title,
    required String description,
  }) async {
    await _client.rpc(
      'admin_update_material',
      params: {
        'p_material_id': materialId,
        'p_title': title,
        'p_description': description,
      },
    );
  }

  Future<void> deleteMaterial(AdminMaterialItem item) async {
    final storagePath = await _client.rpc(
      'admin_delete_material',
      params: {'p_material_id': item.id},
    );
    final path = storagePath as String?;
    if (path != null && path.isNotEmpty) {
      await _client.storage.from(MaterialService.bucketName).remove([path]);
    }
  }

  Future<String?> createMaterialUrl(AdminMaterialItem item) async {
    final path = item.storagePath;
    if (path == null || path.isEmpty) {
      return null;
    }
    return _client.storage
        .from(MaterialService.bucketName)
        .createSignedUrl(path, 3600);
  }

  Future<List<AdminAssessmentItem>> listQuizzes({
    String search = '',
    String? courseId,
    String? status,
  }) async {
    final params = <String, dynamic>{'p_search': search, 'p_status': status};
    final courseUuid = _nullableUuid(courseId);
    if (courseUuid != null) {
      params['p_course_id'] = courseUuid;
    }

    dynamic response;
    try {
      response = await _client.rpc('list_admin_quizzes', params: params);
    } on PostgrestException catch (error) {
      try {
        if (!_isRpcSignatureError(error)) rethrow;
        response = await _client.rpc(
          'list_admin_quizzes',
          params: {
            'p_search': search,
            'p_course_id': courseUuid,
            'p_status': status,
            'p_instructor_id': null,
          },
        );
      } on PostgrestException {
        return _listQuizzesFromTables(
          search: search,
          courseId: courseId,
          status: status,
        );
      }
    }
    return _mapList(response, AdminAssessmentItem.quiz);
  }

  bool _isRpcSignatureError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return message.contains('function') ||
        message.contains('schema cache') ||
        message.contains('could not choose') ||
        message.contains('ambiguous');
  }

  Future<List<AdminAssessmentItem>> _listQuizzesFromTables({
    required String search,
    required String? courseId,
    required String? status,
  }) async {
    final quizRows = await _client.from('quizzes').select();
    final courseRows = await _client
        .from('courses')
        .select('id,title,code,instructor_id');

    final coursesById = {
      for (final row in courseRows as List<dynamic>)
        (row as Map)['id'] as String: Map<String, dynamic>.from(row),
    };
    final profileIds = <String>{
      for (final course in coursesById.values)
        if ((course['instructor_id'] as String?)?.isNotEmpty ?? false)
          course['instructor_id'] as String,
      for (final row in quizRows as List<dynamic>)
        if (((row as Map)['created_by'] as String?)?.isNotEmpty ?? false)
          row['created_by'] as String,
    }.toList();

    final profilesById = <String, Map<String, dynamic>>{};
    if (profileIds.isNotEmpty) {
      final profileRows = await _client
          .from('profiles')
          .select('id,full_name')
          .inFilter('id', profileIds);
      for (final row in profileRows as List<dynamic>) {
        final profile = Map<String, dynamic>.from(row as Map);
        profilesById[profile['id'] as String] = profile;
      }
    }

    final normalizedSearch = search.trim().toLowerCase();
    final normalizedStatus = status?.trim().toLowerCase();
    final selectedCourseId = _nullableUuid(courseId);
    final items = <AdminAssessmentItem>[];

    for (final row in quizRows) {
      final quiz = Map<String, dynamic>.from(row as Map);
      final quizCourseId = quiz['course_id'] as String? ?? '';
      if (selectedCourseId != null && quizCourseId != selectedCourseId) {
        continue;
      }
      final course = coursesById[quizCourseId] ?? const <String, dynamic>{};
      final courseTitle = course['title'] as String? ?? '';
      final courseCode = course['code'] as String? ?? '';
      final quizTitle = quiz['title'] as String? ?? '';
      final isPublished = quiz['is_published'] as bool? ?? false;

      if (normalizedStatus == 'published' && !isPublished) continue;
      if (normalizedStatus == 'draft' && isPublished) continue;
      if (normalizedSearch.isNotEmpty &&
          !quizTitle.toLowerCase().contains(normalizedSearch) &&
          !courseTitle.toLowerCase().contains(normalizedSearch) &&
          !courseCode.toLowerCase().contains(normalizedSearch)) {
        continue;
      }

      final instructorId = course['instructor_id'] as String?;
      final creatorId = quiz['created_by'] as String?;
      items.add(
        AdminAssessmentItem.quiz({
          ...quiz,
          'course_title': courseTitle,
          'course_code': courseCode,
          'instructor_name':
              profilesById[instructorId]?['full_name'] ?? 'Unknown instructor',
          'created_by_name':
              profilesById[creatorId]?['full_name'] ?? 'Unknown creator',
          'question_count':
              (quiz['question_schema'] as List<dynamic>? ?? const []).length,
          'show_question_marks': quiz['show_question_marks'] as bool? ?? true,
        }),
      );
    }

    items.sort((a, b) {
      final aDate =
          a.dueAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.dueAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return items;
  }

  Future<void> updateQuiz({
    required String quizId,
    required String title,
    required String description,
    required String instructions,
    required DateTime? dueAt,
    required int maxPoints,
    required int? durationMinutes,
    required bool isPublished,
  }) async {
    await _client.rpc(
      'admin_update_quiz',
      params: {
        'p_quiz_id': quizId,
        'p_title': title,
        'p_description': description,
        'p_instructions': instructions,
        'p_due_at': dueAt?.toUtc().toIso8601String(),
        'p_max_points': maxPoints,
        'p_duration_minutes': durationMinutes,
        'p_is_published': isPublished,
      },
    );
  }

  Future<void> setQuizPublished(String quizId, bool isPublished) async {
    await _client.rpc(
      'admin_set_quiz_published',
      params: {'p_quiz_id': quizId, 'p_is_published': isPublished},
    );
  }

  Future<void> deleteQuiz(String quizId) async {
    await _client.rpc('admin_delete_quiz', params: {'p_quiz_id': quizId});
  }

  Future<List<AdminAssessmentItem>> listAssignments({
    String search = '',
    String? courseId,
    String? status,
  }) async {
    final response = await _client.rpc(
      'list_admin_assignments',
      params: {
        'p_search': search,
        'p_course_id': _nullableUuid(courseId),
        'p_status': status,
      },
    );
    return _mapList(response, AdminAssessmentItem.assignment);
  }

  Future<void> updateAssignment({
    required String assignmentId,
    required String title,
    required String instructions,
    required String attachmentRequirements,
    required DateTime? dueAt,
    required int maxPoints,
    required bool isPublished,
  }) async {
    await _client.rpc(
      'admin_update_assignment',
      params: {
        'p_assignment_id': assignmentId,
        'p_title': title,
        'p_instructions': instructions,
        'p_attachment_requirements': attachmentRequirements,
        'p_due_at': dueAt?.toUtc().toIso8601String(),
        'p_max_points': maxPoints,
        'p_is_published': isPublished,
      },
    );
  }

  Future<void> setAssignmentPublished(
    String assignmentId,
    bool isPublished,
  ) async {
    await _client.rpc(
      'admin_set_assignment_published',
      params: {'p_assignment_id': assignmentId, 'p_is_published': isPublished},
    );
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _client.rpc(
      'admin_delete_assignment',
      params: {'p_assignment_id': assignmentId},
    );
  }

  Future<List<AdminAnnouncementItem>> listAnnouncements({
    String search = '',
    String? courseId,
  }) async {
    final response = await _client.rpc(
      'list_admin_announcements',
      params: {'p_search': search, 'p_course_id': _nullableUuid(courseId)},
    );
    return _mapList(response, AdminAnnouncementItem.fromJson);
  }

  Future<void> saveAnnouncement({
    String? announcementId,
    required String courseId,
    required String title,
    required String body,
    required bool isPinned,
  }) async {
    await _client.rpc(
      'admin_save_announcement',
      params: {
        'p_announcement_id': announcementId,
        'p_course_id': courseId,
        'p_title': title,
        'p_body': body,
        'p_is_pinned': isPinned,
      },
    );
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _client.rpc(
      'admin_delete_announcement',
      params: {'p_announcement_id': announcementId},
    );
  }

  List<T> _mapList<T>(dynamic response, T Function(Map<String, dynamic>) map) {
    return (response as List<dynamic>? ?? [])
        .map((item) => map(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  String? _nullableUuid(String? value) {
    if (value == null || value.trim().isEmpty || value == 'all') {
      return null;
    }
    return value;
  }
}

class AdminCourseMembers {
  const AdminCourseMembers({this.instructor, required this.students});

  final AdminUser? instructor;
  final List<AdminUser> students;

  factory AdminCourseMembers.fromJson(Map<String, dynamic> json) {
    final instructorJson = json['instructor'];
    return AdminCourseMembers(
      instructor: instructorJson is Map
          ? AdminUser.fromJson(Map<String, dynamic>.from(instructorJson))
          : null,
      students: (json['students'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                AdminUser.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}
