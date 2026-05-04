class CourseInstructor {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final bool isPrimary;

  const CourseInstructor({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'instructor',
    this.status = 'active',
    this.isPrimary = false,
  });

  factory CourseInstructor.fromJson(Map<String, dynamic> json) {
    return CourseInstructor(
      id: json['id'] as String? ?? '',
      name:
          json['name'] as String? ??
          json['full_name'] as String? ??
          json['instructor_name'] as String? ??
          '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'instructor',
      status: json['status'] as String? ?? 'active',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String code;
  final int studentsCount;
  final int lecturesCount;
  final String instructor;
  final String instructorId;
  final List<CourseInstructor> instructors;
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
    this.instructors = const [],
    required this.description,
    this.status = 'draft',
    this.semester = '',
    this.maxStudents = 0,
    this.allowSelfEnrollment = false,
    this.isVisible = false,
    this.createdAt,
  });

  String get instructorSummary {
    if (instructors.isEmpty) {
      return instructor;
    }
    if (instructors.length == 1) {
      return instructors.first.name;
    }
    return '${instructors.first.name} +${instructors.length - 1} more';
  }

  String get instructorsCountLabel {
    if (instructors.isEmpty) {
      return instructor.isEmpty ? 'No instructors' : instructor;
    }
    return instructors.length == 1
        ? instructors.first.name
        : '${instructors.length} instructors';
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final instructors = _parseInstructors(json['instructors']);
    final legacyInstructor =
        json['instructor_name'] as String? ??
        json['instructor'] as String? ??
        '';
    return CourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      code: json['code'] as String,
      studentsCount: (json['students_count'] as num? ?? 0).toInt(),
      lecturesCount: (json['lectures_count'] as num? ?? 0).toInt(),
      instructor: instructors.isNotEmpty
          ? instructors.first.name
          : legacyInstructor,
      instructorId: json['instructor_id'] as String? ?? '',
      instructors: instructors,
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

List<CourseInstructor> _parseInstructors(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map((item) => CourseInstructor.fromJson(Map<String, dynamic>.from(item)))
      .where((item) => item.id.isNotEmpty || item.name.isNotEmpty)
      .toList();
}
