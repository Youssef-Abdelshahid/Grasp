class SubmissionModel {
  const SubmissionModel({
    required this.id,
    required this.studentId,
    this.quizId,
    this.assignmentId,
    required this.content,
    this.score,
    required this.status,
    required this.submittedAt,
    required this.attemptNumber,
    this.fileName,
    this.fileSizeBytes,
    this.storagePath,
    this.gradedAt,
    this.feedback = '',
    this.gradingDetails = const {},
    this.gradeVisible = false,
    this.feedbackVisible = false,
    this.attemptVisible = false,
    this.showCorrectAnswers = false,
  });

  final String id;
  final String studentId;
  final String? quizId;
  final String? assignmentId;
  final Map<String, dynamic> content;
  final double? score;
  final String status;
  final DateTime submittedAt;
  final int attemptNumber;
  final String? fileName;
  final int? fileSizeBytes;
  final String? storagePath;
  final DateTime? gradedAt;
  final String feedback;
  final Map<String, dynamic> gradingDetails;
  final bool gradeVisible;
  final bool feedbackVisible;
  final bool attemptVisible;
  final bool showCorrectAnswers;

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      quizId: json['quiz_id'] as String?,
      assignmentId: json['assignment_id'] as String?,
      content: (json['content'] as Map<String, dynamic>? ?? const {}),
      score: (json['score'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'submitted',
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 1,
      fileName: json['file_name'] as String?,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      storagePath: json['storage_path'] as String?,
      gradedAt: json['graded_at'] == null
          ? null
          : DateTime.parse(json['graded_at'] as String),
      feedback: json['feedback'] as String? ?? '',
      gradingDetails: Map<String, dynamic>.from(
        json['grading_details'] as Map? ?? const {},
      ),
      gradeVisible: json['grade_visible'] as bool? ?? false,
      feedbackVisible: json['feedback_visible'] as bool? ?? false,
      attemptVisible: json['attempt_visible'] as bool? ?? false,
      showCorrectAnswers: json['show_correct_answers'] as bool? ?? false,
    );
  }
}
