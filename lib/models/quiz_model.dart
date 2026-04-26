class QuizModel {
  const QuizModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.instructions,
    required this.dueAt,
    required this.maxPoints,
    required this.durationMinutes,
    required this.isPublished,
    required this.questionSchema,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.showCorrectAnswers = false,
    this.allowRetakes = false,
    this.showQuestionMarks = true,
    this.publishedAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;
  final String instructions;
  final DateTime? dueAt;
  final int maxPoints;
  final int? durationMinutes;
  final bool isPublished;
  final List<Map<String, dynamic>> questionSchema;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool showCorrectAnswers;
  final bool allowRetakes;
  final bool showQuestionMarks;
  final DateTime? publishedAt;

  int get questionCount => questionSchema.length;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawSchema = json['question_schema'] as List<dynamic>? ?? const [];
    return QuizModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      maxPoints: json['max_points'] as int? ?? 100,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      isPublished: json['is_published'] as bool? ?? false,
      questionSchema: rawSchema
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
        (json['updated_at'] ?? json['created_at']) as String,
      ),
      showCorrectAnswers: json['show_correct_answers'] as bool? ?? false,
      allowRetakes: json['allow_retakes'] as bool? ?? false,
      showQuestionMarks: json['show_question_marks'] as bool? ?? true,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
    );
  }
}
