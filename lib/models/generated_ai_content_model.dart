class GeneratedAiContentModel {
  const GeneratedAiContentModel({
    required this.id,
    required this.courseId,
    required this.materialId,
    required this.generatedBy,
    required this.contentType,
    required this.status,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String materialId;
  final String generatedBy;
  final String contentType;
  final String status;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory GeneratedAiContentModel.fromJson(Map<String, dynamic> json) {
    return GeneratedAiContentModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      materialId: json['material_id'] as String,
      generatedBy: json['generated_by'] as String,
      contentType: json['content_type'] as String,
      status: json['status'] as String? ?? 'draft',
      payload: (json['payload'] as Map<String, dynamic>? ?? const {}),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
