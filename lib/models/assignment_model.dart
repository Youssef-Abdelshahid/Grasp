class AssignmentModel {
  const AssignmentModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.instructions,
    required this.dueAt,
    required this.maxPoints,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String instructions;
  final DateTime? dueAt;
  final int maxPoints;
  final String createdBy;
  final DateTime createdAt;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String? ?? '',
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      maxPoints: json['max_points'] as int? ?? 100,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
