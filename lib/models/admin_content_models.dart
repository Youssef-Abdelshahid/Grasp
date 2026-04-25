import 'package:intl/intl.dart';

class AdminCourseItem {
  const AdminCourseItem({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.status,
    required this.instructorId,
    required this.instructorName,
    this.semester = '',
    this.maxStudents = 50,
    this.allowSelfEnrollment = false,
    this.isVisible = false,
    this.studentsCount = 0,
    this.materialsCount = 0,
    this.quizzesCount = 0,
    this.assignmentsCount = 0,
    this.announcementsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String code;
  final String description;
  final String status;
  final String instructorId;
  final String instructorName;
  final String semester;
  final int maxStudents;
  final bool allowSelfEnrollment;
  final bool isVisible;
  final int studentsCount;
  final int materialsCount;
  final int quizzesCount;
  final int assignmentsCount;
  final int announcementsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get statusLabel => _label(status);
  String get createdLabel => _date(createdAt);

  factory AdminCourseItem.fromJson(Map<String, dynamic> json) {
    return AdminCourseItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      instructorId: json['instructor_id'] as String? ?? '',
      instructorName: json['instructor_name'] as String? ?? '',
      semester: json['semester'] as String? ?? '',
      maxStudents: (json['max_students'] as num? ?? 50).toInt(),
      allowSelfEnrollment: json['allow_self_enrollment'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? false,
      studentsCount: (json['students_count'] as num? ?? 0).toInt(),
      materialsCount: (json['materials_count'] as num? ?? 0).toInt(),
      quizzesCount: (json['quizzes_count'] as num? ?? 0).toInt(),
      assignmentsCount: (json['assignments_count'] as num? ?? 0).toInt(),
      announcementsCount: (json['announcements_count'] as num? ?? 0).toInt(),
      createdAt: _parse(json['created_at']),
      updatedAt: _parse(json['updated_at']),
    );
  }
}

class AdminMaterialItem {
  const AdminMaterialItem({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
    required this.instructorName,
    required this.title,
    required this.description,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.mimeType,
    this.storagePath,
    required this.uploadedByName,
    this.createdAt,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String courseCode;
  final String instructorName;
  final String title;
  final String description;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final String mimeType;
  final String? storagePath;
  final String uploadedByName;
  final DateTime? createdAt;

  String get createdLabel => _date(createdAt);
  String get sizeLabel => _bytes(fileSizeBytes);

  factory AdminMaterialItem.fromJson(Map<String, dynamic> json) {
    return AdminMaterialItem(
      id: json['id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      courseCode: json['course_code'] as String? ?? '',
      instructorName: json['instructor_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileType: json['file_type'] as String? ?? '',
      fileSizeBytes: (json['file_size_bytes'] as num? ?? 0).toInt(),
      mimeType: json['mime_type'] as String? ?? '',
      storagePath: json['storage_path'] as String?,
      uploadedByName: json['uploaded_by_name'] as String? ?? '',
      createdAt: _parse(json['created_at']),
    );
  }
}

class AdminAssessmentItem {
  const AdminAssessmentItem({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
    required this.instructorName,
    required this.title,
    required this.description,
    required this.instructions,
    required this.maxPoints,
    required this.isPublished,
    this.dueAt,
    this.durationMinutes,
    this.schemaCount = 0,
    this.schema = const [],
    this.attachmentRequirements = '',
    this.rubric = const [],
    required this.createdByName,
    this.createdAt,
    this.publishedAt,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String courseCode;
  final String instructorName;
  final String title;
  final String description;
  final String instructions;
  final int maxPoints;
  final bool isPublished;
  final DateTime? dueAt;
  final int? durationMinutes;
  final int schemaCount;
  final List<Map<String, dynamic>> schema;
  final String attachmentRequirements;
  final List<Map<String, dynamic>> rubric;
  final String createdByName;
  final DateTime? createdAt;
  final DateTime? publishedAt;

  String get statusLabel => isPublished ? 'Published' : 'Draft';
  String get dueLabel => dueAt == null ? 'No deadline' : _date(dueAt);
  String get createdLabel => _date(createdAt);

  factory AdminAssessmentItem.quiz(Map<String, dynamic> json) {
    return AdminAssessmentItem(
      id: json['id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      courseCode: json['course_code'] as String? ?? '',
      instructorName: json['instructor_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      maxPoints: (json['max_points'] as num? ?? 100).toInt(),
      isPublished: json['is_published'] as bool? ?? false,
      dueAt: _parse(json['due_at']),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      schemaCount: (json['question_count'] as num? ?? 0).toInt(),
      schema: _jsonList(json['question_schema']),
      createdByName: json['created_by_name'] as String? ?? '',
      createdAt: _parse(json['created_at']),
      publishedAt: _parse(json['published_at']),
    );
  }

  factory AdminAssessmentItem.assignment(Map<String, dynamic> json) {
    return AdminAssessmentItem(
      id: json['id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      courseCode: json['course_code'] as String? ?? '',
      instructorName: json['instructor_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: '',
      instructions: json['instructions'] as String? ?? '',
      maxPoints: (json['max_points'] as num? ?? 100).toInt(),
      isPublished: json['is_published'] as bool? ?? false,
      dueAt: _parse(json['due_at']),
      schemaCount: (json['rubric_count'] as num? ?? 0).toInt(),
      attachmentRequirements: json['attachment_requirements'] as String? ?? '',
      rubric: _jsonList(json['rubric']),
      createdByName: json['created_by_name'] as String? ?? '',
      createdAt: _parse(json['created_at']),
      publishedAt: _parse(json['published_at']),
    );
  }
}

class AdminAnnouncementItem {
  const AdminAnnouncementItem({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
    required this.instructorName,
    required this.title,
    required this.body,
    required this.isPinned,
    required this.createdByName,
    this.createdAt,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String courseCode;
  final String instructorName;
  final String title;
  final String body;
  final bool isPinned;
  final String createdByName;
  final DateTime? createdAt;

  String get createdLabel => _date(createdAt);

  factory AdminAnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AdminAnnouncementItem(
      id: json['id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      courseCode: json['course_code'] as String? ?? '',
      instructorName: json['instructor_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isPinned: json['is_pinned'] as bool? ?? false,
      createdByName: json['created_by_name'] as String? ?? '',
      createdAt: _parse(json['created_at']),
    );
  }
}

DateTime? _parse(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}

List<Map<String, dynamic>> _jsonList(dynamic value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _date(DateTime? value) {
  if (value == null) {
    return 'Unknown';
  }
  return DateFormat('MMM d, yyyy').format(value);
}

String _label(String value) {
  if (value.isEmpty) {
    return '';
  }
  return value[0].toUpperCase() + value.substring(1);
}

String _bytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
