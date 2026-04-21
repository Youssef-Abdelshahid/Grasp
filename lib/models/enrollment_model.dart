class EnrollmentModel {
  const EnrollmentModel({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.status,
    required this.enrolledAt,
  });

  final String id;
  final String courseId;
  final String studentId;
  final String status;
  final DateTime enrolledAt;

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      studentId: json['student_id'] as String,
      status: json['status'] as String? ?? 'active',
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
    );
  }
}
