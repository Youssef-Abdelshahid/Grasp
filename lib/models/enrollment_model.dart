class EnrollmentModel {
  const EnrollmentModel({
    required this.id,
    required this.courseId,
    required this.studentId,
    this.studentName = '',
    this.studentEmail = '',
    required this.status,
    required this.enrolledAt,
  });

  final String id;
  final String courseId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String status;
  final DateTime enrolledAt;

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    final student = json['profiles'];
    String studentName = '';
    String studentEmail = '';
    if (student is Map<String, dynamic>) {
      studentName = student['full_name'] as String? ?? '';
      studentEmail = student['email'] as String? ?? '';
    } else if (student is Map) {
      studentName = student['full_name'] as String? ?? '';
      studentEmail = student['email'] as String? ?? '';
    }

    return EnrollmentModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      studentId: json['student_id'] as String,
      studentName: studentName,
      studentEmail: studentEmail,
      status: json['status'] as String? ?? 'active',
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
    );
  }
}
