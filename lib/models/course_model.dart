class CourseModel {
  final String id;
  final String title;
  final String code;
  final int studentsCount;
  final int lecturesCount;
  final String instructor;
  final String description;

  const CourseModel({
    required this.id,
    required this.title,
    required this.code,
    required this.studentsCount,
    required this.lecturesCount,
    required this.instructor,
    required this.description,
  });
}
