import 'package:intl/intl.dart';

class CourseStudentActivity {
  const CourseStudentActivity({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.enrolledAt,
    this.totalQuizzes = 0,
    this.quizzesCompleted = 0,
    this.totalAssignments = 0,
    this.assignmentsSubmitted = 0,
    this.overdueCount = 0,
    this.latestActivityAt,
  });

  final String studentId;
  final String studentName;
  final String studentEmail;
  final DateTime? enrolledAt;
  final int totalQuizzes;
  final int quizzesCompleted;
  final int totalAssignments;
  final int assignmentsSubmitted;
  final int overdueCount;
  final DateTime? latestActivityAt;

  int get completedCount => quizzesCompleted + assignmentsSubmitted;
  int get totalCount => totalQuizzes + totalAssignments;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
  String get enrolledLabel => _date(enrolledAt);
  String get latestLabel =>
      latestActivityAt == null ? 'No activity' : _date(latestActivityAt);

  factory CourseStudentActivity.fromJson(Map<String, dynamic> json) {
    return CourseStudentActivity(
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      studentEmail: json['student_email'] as String? ?? '',
      enrolledAt: _parse(json['enrolled_at']),
      totalQuizzes: (json['total_quizzes'] as num? ?? 0).toInt(),
      quizzesCompleted: (json['quizzes_completed'] as num? ?? 0).toInt(),
      totalAssignments: (json['total_assignments'] as num? ?? 0).toInt(),
      assignmentsSubmitted: (json['assignments_submitted'] as num? ?? 0)
          .toInt(),
      overdueCount: (json['overdue_count'] as num? ?? 0).toInt(),
      latestActivityAt: _parse(json['latest_activity_at']),
    );
  }
}

class StudentActivityItem {
  const StudentActivityItem({
    this.id = '',
    required this.title,
    required this.type,
    required this.status,
    this.submissionId,
    this.dueAt,
    this.submittedAt,
    this.score,
  });

  final String id;
  final String title;
  final String type;
  final String status;
  final String? submissionId;
  final DateTime? dueAt;
  final DateTime? submittedAt;
  final double? score;

  String get dueLabel => dueAt == null ? 'No due date' : _date(dueAt);
  String get submittedLabel =>
      submittedAt == null ? 'Not submitted' : _date(submittedAt);
  String get scoreLabel => score == null ? '-' : score!.toStringAsFixed(1);

  factory StudentActivityItem.fromJson(Map<String, dynamic> json) {
    return StudentActivityItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? 'missing',
      submissionId: json['submission_id'] as String?,
      dueAt: _parse(json['due_at']),
      submittedAt: _parse(json['submitted_at']),
      score: (json['score'] as num?)?.toDouble(),
    );
  }
}

class StudentCourseActivityDetail {
  const StudentCourseActivityDetail({
    required this.student,
    required this.quizzes,
    required this.assignments,
    required this.timeline,
  });

  final CourseStudentActivity student;
  final List<StudentActivityItem> quizzes;
  final List<StudentActivityItem> assignments;
  final List<StudentActivityItem> timeline;

  factory StudentCourseActivityDetail.fromJson(Map<String, dynamic> json) {
    final studentJson = Map<String, dynamic>.from(
      json['student'] as Map? ?? const {},
    );
    return StudentCourseActivityDetail(
      student: CourseStudentActivity.fromJson(studentJson),
      quizzes: _items(json['quizzes']),
      assignments: _items(json['assignments']),
      timeline: _items(json['timeline']),
    );
  }
}

class AssessmentActivity {
  const AssessmentActivity({required this.stats, required this.items});

  final AssessmentStats stats;
  final List<AssessmentSubmissionItem> items;

  factory AssessmentActivity.fromJson(Map<String, dynamic> json) {
    return AssessmentActivity(
      stats: AssessmentStats.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? const {}),
      ),
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (item) => AssessmentSubmissionItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class AssessmentStats {
  const AssessmentStats({
    this.totalStudents = 0,
    this.submittedCount = 0,
    this.missingCount = 0,
    this.overdueCount = 0,
    this.averageScore,
    this.highestScore,
    this.lowestScore,
  });

  final int totalStudents;
  final int submittedCount;
  final int missingCount;
  final int overdueCount;
  final double? averageScore;
  final double? highestScore;
  final double? lowestScore;

  double get submissionRate =>
      totalStudents == 0 ? 0 : submittedCount / totalStudents;

  factory AssessmentStats.fromJson(Map<String, dynamic> json) {
    return AssessmentStats(
      totalStudents: (json['total_students'] as num? ?? 0).toInt(),
      submittedCount: (json['submitted_count'] as num? ?? 0).toInt(),
      missingCount: (json['missing_count'] as num? ?? 0).toInt(),
      overdueCount: (json['overdue_count'] as num? ?? 0).toInt(),
      averageScore: (json['average_score'] as num?)?.toDouble(),
      highestScore: (json['highest_score'] as num?)?.toDouble(),
      lowestScore: (json['lowest_score'] as num?)?.toDouble(),
    );
  }
}

class AssessmentSubmissionItem {
  const AssessmentSubmissionItem({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    this.submissionId,
    this.submittedAt,
    this.score,
    this.fileName,
    this.storagePath,
  });

  final String studentId;
  final String studentName;
  final String studentEmail;
  final String status;
  final String? submissionId;
  final DateTime? submittedAt;
  final double? score;
  final String? fileName;
  final String? storagePath;

  String get submittedLabel =>
      submittedAt == null ? 'Not submitted' : _date(submittedAt);
  String get scoreLabel => score == null ? '-' : score!.toStringAsFixed(1);

  factory AssessmentSubmissionItem.fromJson(Map<String, dynamic> json) {
    return AssessmentSubmissionItem(
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      studentEmail: json['student_email'] as String? ?? '',
      status: json['status'] as String? ?? '',
      submissionId: json['submission_id'] as String?,
      submittedAt: _parse(json['submitted_at']),
      score: (json['score'] as num?)?.toDouble(),
      fileName: json['file_name'] as String?,
      storagePath: json['storage_path'] as String?,
    );
  }
}

class SubmissionDetail {
  const SubmissionDetail({
    required this.id,
    required this.studentName,
    required this.studentEmail,
    required this.title,
    required this.type,
    required this.status,
    required this.content,
    this.feedback = '',
    this.gradingDetails = const {},
    this.gradeVisible = false,
    this.feedbackVisible = false,
    this.attemptVisible = false,
    this.showCorrectAnswers = false,
    this.dueAt,
    this.submittedAt,
    this.score,
    this.fileName,
    this.fileSizeBytes,
    this.storagePath,
    this.attemptNumber,
    this.questionSchema = const [],
    this.rubric = const [],
  });

  final String id;
  final String studentName;
  final String studentEmail;
  final String title;
  final String type;
  final String status;
  final Map<String, dynamic> content;
  final String feedback;
  final Map<String, dynamic> gradingDetails;
  final bool gradeVisible;
  final bool feedbackVisible;
  final bool attemptVisible;
  final bool showCorrectAnswers;
  final DateTime? dueAt;
  final DateTime? submittedAt;
  final double? score;
  final String? fileName;
  final int? fileSizeBytes;
  final String? storagePath;
  final int? attemptNumber;
  final List<Map<String, dynamic>> questionSchema;
  final List<Map<String, dynamic>> rubric;

  bool get isLate =>
      dueAt != null && submittedAt != null && submittedAt!.isAfter(dueAt!);
  String get submittedLabel =>
      submittedAt == null ? 'Not submitted' : _date(submittedAt);
  String get dueLabel => dueAt == null ? 'No due date' : _date(dueAt);
  String get scoreLabel => score == null ? '-' : score!.toStringAsFixed(1);

  factory SubmissionDetail.fromJson(Map<String, dynamic> json) {
    return SubmissionDetail(
      id: json['id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      studentEmail: json['student_email'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      content: Map<String, dynamic>.from(json['content'] as Map? ?? const {}),
      feedback: json['feedback'] as String? ?? '',
      gradingDetails: Map<String, dynamic>.from(
        json['grading_details'] as Map? ?? const {},
      ),
      gradeVisible: json['grade_visible'] as bool? ?? false,
      feedbackVisible: json['feedback_visible'] as bool? ?? false,
      attemptVisible: json['attempt_visible'] as bool? ?? false,
      showCorrectAnswers: json['show_correct_answers'] as bool? ?? false,
      dueAt: _parse(json['due_at']),
      submittedAt: _parse(json['submitted_at']),
      score: (json['score'] as num?)?.toDouble(),
      fileName: json['file_name'] as String?,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      storagePath: json['storage_path'] as String?,
      attemptNumber: (json['attempt_number'] as num?)?.toInt(),
      questionSchema: _jsonList(json['question_schema']),
      rubric: _jsonList(json['rubric']),
    );
  }
}

List<StudentActivityItem> _items(dynamic value) {
  return (value as List<dynamic>? ?? [])
      .map(
        (item) => StudentActivityItem.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
      .toList();
}

List<Map<String, dynamic>> _jsonList(dynamic value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

DateTime? _parse(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

String _date(DateTime? value) {
  if (value == null) return 'Unknown';
  return DateFormat('MMM d, yyyy h:mm a').format(value);
}
