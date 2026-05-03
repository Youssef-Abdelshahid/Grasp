import 'package:intl/intl.dart';

class StudyNoteModel {
  const StudyNoteModel({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.title,
    required this.prompt,
    required this.materialIds,
    required this.content,
    this.studentName = '',
    this.studentEmail = '',
    this.courseTitle = '',
    this.courseCode = '',
    this.materialNames = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String courseId;
  final String studentId;
  final String title;
  final String prompt;
  final List<String> materialIds;
  final String content;
  final String studentName;
  final String studentEmail;
  final String courseTitle;
  final String courseCode;
  final List<String> materialNames;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get createdLabel => DateFormat('MMM d, yyyy h:mm a').format(createdAt);
  String get updatedLabel => DateFormat('MMM d, yyyy h:mm a').format(updatedAt);
  String get studentLabel =>
      studentName.trim().isEmpty ? 'Unknown student' : studentName.trim();
  String get studentSubtitle => studentEmail.trim();

  String get courseLabel {
    final title = courseTitle.trim();
    final code = courseCode.trim();
    if (title.isEmpty && code.isEmpty) return 'Unknown course';
    if (title.isEmpty) return code;
    if (code.isEmpty) return title;
    return '$title - $code';
  }

  String get materialLabel {
    final names = materialNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) return 'No material linked';
    if (names.length == 1) return names.first;
    if (names.length <= 2) return names.join(', ');
    return '${names.length} materials';
  }

  factory StudyNoteModel.fromJson(Map<String, dynamic> json) {
    final student =
        _mapValue(json['student']) ??
        _mapValue(json['profiles']) ??
        _mapValue(json['student_profile']);
    final course =
        _mapValue(json['course']) ??
        _mapValue(json['courses']) ??
        _mapValue(json['course_info']);

    return StudyNoteModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      studentId: json['student_id'] as String,
      title: json['title'] as String? ?? 'Study Notes',
      prompt: json['prompt'] as String? ?? '',
      materialIds: (json['selected_material_ids'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      content: json['content'] as String? ?? '',
      studentName:
          json['student_name'] as String? ??
          student?['full_name'] as String? ??
          student?['name'] as String? ??
          '',
      studentEmail:
          json['student_email'] as String? ??
          student?['email'] as String? ??
          '',
      courseTitle:
          json['course_title'] as String? ?? course?['title'] as String? ?? '',
      courseCode:
          json['course_code'] as String? ?? course?['code'] as String? ?? '',
      materialNames: (json['material_names'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
        (json['updated_at'] ?? json['created_at']) as String,
      ),
    );
  }

  StudyNoteModel copyWith({
    String? title,
    String? prompt,
    List<String>? materialIds,
    List<String>? materialNames,
    String? content,
  }) {
    return StudyNoteModel(
      id: id,
      courseId: courseId,
      studentId: studentId,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      materialIds: materialIds ?? this.materialIds,
      content: content ?? this.content,
      studentName: studentName,
      studentEmail: studentEmail,
      courseTitle: courseTitle,
      courseCode: courseCode,
      materialNames: materialNames ?? this.materialNames,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title.trim(),
      'prompt': prompt.trim(),
      'selected_material_ids': materialIds,
      'content': content.trim(),
    };
  }
}

Map<String, dynamic>? _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
