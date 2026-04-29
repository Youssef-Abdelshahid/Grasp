class FlashcardModel {
  const FlashcardModel({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.title,
    required this.prompt,
    required this.difficulty,
    required this.materialIds,
    required this.cards,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String courseId;
  final String studentId;
  final String title;
  final String prompt;
  final String difficulty;
  final List<String> materialIds;
  final List<FlashcardItem> cards;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get cardCount => cards.length;

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      studentId: json['student_id'] as String,
      title: json['title'] as String? ?? 'Study Flashcards',
      prompt: json['prompt'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      materialIds: (json['selected_material_ids'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      cards: (json['cards'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => FlashcardItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
        (json['updated_at'] ?? json['created_at']) as String,
      ),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title.trim(),
      'prompt': prompt.trim(),
      'difficulty': difficulty.trim(),
      'selected_material_ids': materialIds,
      'cards': cards.map((card) => card.toJson()).toList(),
    };
  }
}

class FlashcardItem {
  const FlashcardItem({
    required this.front,
    required this.back,
    this.difficulty = '',
    this.tag = '',
    this.sourceReference = const {},
  });

  final String front;
  final String back;
  final String difficulty;
  final String tag;
  final Map<String, dynamic> sourceReference;

  factory FlashcardItem.fromJson(Map<String, dynamic> json) {
    return FlashcardItem(
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      sourceReference: Map<String, dynamic>.from(
        json['source_ref'] as Map? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'front': front.trim(),
      'back': back.trim(),
      if (difficulty.trim().isNotEmpty) 'difficulty': difficulty.trim(),
      if (tag.trim().isNotEmpty) 'tag': tag.trim(),
      if (sourceReference.isNotEmpty) 'source_ref': sourceReference,
    };
  }
}
