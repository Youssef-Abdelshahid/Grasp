class AssignmentModel {
  const AssignmentModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.instructions,
    required this.attachmentRequirements,
    required this.dueAt,
    required this.maxPoints,
    required this.isPublished,
    required this.rubric,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String instructions;
  final String attachmentRequirements;
  final DateTime? dueAt;
  final int maxPoints;
  final bool isPublished;
  final List<Map<String, dynamic>> rubric;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  int get rubricCount => rubric.length;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final rawRubric = json['rubric'] as List<dynamic>? ?? const [];
    return AssignmentModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String? ?? '',
      attachmentRequirements:
          json['attachment_requirements'] as String? ?? '',
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      maxPoints: json['max_points'] as int? ?? 100,
      isPublished: json['is_published'] as bool? ?? false,
      rubric: rawRubric
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
        (json['updated_at'] ?? json['created_at']) as String,
      ),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
    );
  }
}
