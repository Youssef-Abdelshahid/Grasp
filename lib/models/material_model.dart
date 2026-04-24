class MaterialModel {
  const MaterialModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.storagePath,
    required this.uploadedBy,
    this.uploadedByName = '',
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final String mimeType;
  final String? storagePath;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime createdAt;

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    final uploader = json['profiles'];
    String uploadedByName = '';
    if (uploader is Map<String, dynamic>) {
      uploadedByName = uploader['full_name'] as String? ?? '';
    } else if (uploader is Map) {
      uploadedByName = uploader['full_name'] as String? ?? '';
    }

    return MaterialModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      fileName: json['file_name'] as String? ?? json['title'] as String,
      fileType: json['file_type'] as String? ?? '',
      fileSizeBytes: (json['file_size_bytes'] as num? ?? 0).toInt(),
      mimeType: json['mime_type'] as String? ?? '',
      storagePath: json['storage_path'] as String?,
      uploadedBy: json['uploaded_by'] as String,
      uploadedByName: uploadedByName,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
