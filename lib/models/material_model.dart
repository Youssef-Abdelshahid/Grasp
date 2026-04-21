class MaterialModel {
  const MaterialModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.storagePath,
    required this.uploadedBy,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;
  final String? storagePath;
  final String uploadedBy;
  final DateTime createdAt;

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      storagePath: json['storage_path'] as String?,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
