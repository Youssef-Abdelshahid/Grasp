class QuizModel {
  const QuizModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.maxPoints,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime? dueAt;
  final int maxPoints;
  final String createdBy;
  final DateTime createdAt;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      maxPoints: json['max_points'] as int? ?? 100,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
