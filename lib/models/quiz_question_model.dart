class QuizQuestionModel {
  const QuizQuestionModel({
    required this.type,
    required this.questionText,
    required this.options,
    required this.correctOption,
    required this.marks,
    required this.explanation,
    required this.sampleAnswer,
  });

  final String type;
  final String questionText;
  final List<String> options;
  final int correctOption;
  final int marks;
  final String explanation;
  final String sampleAnswer;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      type: json['type'] as String? ?? 'MCQ',
      questionText: json['question_text'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      correctOption: (json['correct_option'] as num?)?.toInt() ?? 0,
      marks: (json['marks'] as num?)?.toInt() ?? 1,
      explanation: json['explanation'] as String? ?? '',
      sampleAnswer: json['sample_answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'question_text': questionText,
      'options': options,
      'correct_option': correctOption,
      'marks': marks,
      'explanation': explanation,
      'sample_answer': sampleAnswer,
    };
  }
}
