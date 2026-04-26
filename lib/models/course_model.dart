class CourseModel {
  final String id;
  final String title;
  final String code;
  final int studentsCount;
  final int lecturesCount;
  final String instructor;
  final String instructorId;
  final String description;
  final String status;
  final String semester;
  final int maxStudents;
  final bool allowSelfEnrollment;
  final bool isVisible;
  final DateTime? createdAt;

  const CourseModel({
    required this.id,
    required this.title,
    required this.code,
    required this.studentsCount,
    required this.lecturesCount,
    required this.instructor,
    this.instructorId = '',
    required this.description,
    this.status = 'draft',
    this.semester = '',
    this.maxStudents = 0,
    this.allowSelfEnrollment = false,
    this.isVisible = false,
    this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      code: json['code'] as String,
      studentsCount: (json['students_count'] as num? ?? 0).toInt(),
      lecturesCount: (json['lectures_count'] as num? ?? 0).toInt(),
      instructor:
          json['instructor_name'] as String? ??
          json['instructor'] as String? ??
          '',
      instructorId: json['instructor_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      semester: json['semester'] as String? ?? '',
      maxStudents: (json['max_students'] as num? ?? 0).toInt(),
      allowSelfEnrollment: json['allow_self_enrollment'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}
