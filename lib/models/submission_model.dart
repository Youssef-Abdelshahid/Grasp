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
  });

  final String id;
  final String studentId;
  final String? quizId;
  final String? assignmentId;
  final Map<String, dynamic> content;
  final double? score;
  final String status;
  final DateTime submittedAt;

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
    );
  }
}
