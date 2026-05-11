import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity_models.dart';
import '../models/permissions_model.dart';
import 'permissions_service.dart';
import 'submission_service.dart';

class ActivityService {
  ActivityService._();

  static final instance = ActivityService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<CourseStudentActivity>> getCourseStudentsActivity(
    String courseId,
  ) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.viewStudentActivity,
    );
    final response = await _client.rpc(
      'get_course_students_activity',
      params: {'p_course_id': courseId},
    );
    return (response as List<dynamic>? ?? const [])
        .map(
          (item) => CourseStudentActivity.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<StudentCourseActivityDetail> getStudentCourseActivity({
    required String courseId,
    required String studentId,
  }) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.viewStudentActivity,
    );
    final response = await _client.rpc(
      'get_student_course_activity',
      params: {'p_course_id': courseId, 'p_student_id': studentId},
    );
    return StudentCourseActivityDetail.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<AssessmentActivity> getQuizActivity(String quizId) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.viewStudentActivity,
    );
    final response = await _client.rpc(
      'get_quiz_activity',
      params: {'p_quiz_id': quizId},
    );
    return AssessmentActivity.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<AssessmentActivity> getAssignmentActivity(String assignmentId) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.viewStudentActivity,
    );
    final response = await _client.rpc(
      'get_assignment_activity',
      params: {'p_assignment_id': assignmentId},
    );
    return AssessmentActivity.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<SubmissionDetail> getSubmissionDetail(String submissionId) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.viewStudentActivity,
    );
    final response = await _client.rpc(
      'get_submission_detail',
      params: {'p_submission_id': submissionId},
    );
    return SubmissionDetail.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<SubmissionDetail> getMySubmissionResult(String submissionId) async {
    final response = await _client.rpc(
      'get_my_submission_result',
      params: {'p_submission_id': submissionId},
    );
    return SubmissionDetail.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<SubmissionDetail> gradeSubmission({
    required String submissionId,
    required double score,
    required String feedback,
    required Map<String, dynamic> gradingDetails,
    required bool gradeVisible,
    required bool feedbackVisible,
    bool attemptVisible = false,
  }) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.gradeStudentWork,
    );
    final response = await _client.rpc(
      'grade_submission',
      params: {
        'p_submission_id': submissionId,
        'p_score': score,
        'p_feedback': feedback,
        'p_grading_details': gradingDetails,
        'p_grade_visible': gradeVisible,
        'p_feedback_visible': feedbackVisible,
        'p_attempt_visible': attemptVisible,
      },
    );
    return SubmissionDetail.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<String?> createSubmissionFileUrl(SubmissionDetail detail) {
    final path = detail.storagePath;
    if (path == null || path.isEmpty) {
      return Future.value();
    }
    return _client.storage
        .from(SubmissionService.assignmentBucketName)
        .createSignedUrl(path, 3600);
  }
}
