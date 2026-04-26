class QuizQuestionModel {
  const QuizQuestionModel({
    required this.type,
    required this.questionText,
    required this.options,
    required this.correctOption,
    required this.marks,
    required this.explanation,
    required this.sampleAnswer,
    this.imagePath = '',
    this.imageName = '',
    this.items = const [],
    this.targets = const [],
    this.categories = const [],
    this.correctMapping = const {},
  });

  final String type;
  final String questionText;
  final List<String> options;
  final int correctOption;
  final double marks;
  final String explanation;
  final String sampleAnswer;
  final String imagePath;
  final String imageName;
  final List<String> items;
  final List<String> targets;
  final List<String> categories;
  final Map<String, String> correctMapping;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final normalizedType = _normalizeType(json['type'] as String? ?? 'MCQ');
    final correctMapping = Map<String, String>.from(
      (json['correct_mapping'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
    final rawTargets = (json['targets'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
    final rawCategories = (json['categories'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
    final matchingTargets = rawTargets.isNotEmpty
        ? rawTargets
        : rawCategories.isNotEmpty
        ? rawCategories
        : correctMapping.values.toSet().toList();

    return QuizQuestionModel(
      type: normalizedType,
      questionText: json['question_text'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      correctOption: (json['correct_option'] as num?)?.toInt() ?? 0,
      marks: (json['marks'] as num?)?.toDouble() ?? 1,
      explanation: json['explanation'] as String? ?? '',
      sampleAnswer: json['sample_answer'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
      imageName: json['image_name'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      targets: normalizedType == 'Matching' ? matchingTargets : const [],
      categories: const [],
      correctMapping: normalizedType == 'Matching' ? correctMapping : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': _normalizeType(type),
      'question_text': questionText,
      'options': options,
      'correct_option': correctOption,
      'marks': marks,
      'explanation': explanation,
      'sample_answer': sampleAnswer,
      'image_path': imagePath,
      'image_name': imageName,
      'items': items,
      'targets': targets,
      'categories': const <String>[],
      'correct_mapping': correctMapping,
    };
  }

  static String _normalizeType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'essay' || normalized == 'short answer') {
      return 'Short Answer';
    }
    if (normalized == 'true / false' || normalized == 'true/false') {
      return 'True / False';
    }
    if (normalized == 'matching' ||
        normalized == 'drag and drop' ||
        normalized == 'classification') {
      return 'Matching';
    }
    if (normalized == 'mcq') return 'MCQ';
    return 'MCQ';
  }
}
