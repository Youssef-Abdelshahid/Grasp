class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.body,
    required this.isPinned,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String body;
  final bool isPinned;
  final String createdBy;
  final DateTime createdAt;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
