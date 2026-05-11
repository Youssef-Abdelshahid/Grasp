class AiControlsConfig {
  const AiControlsConfig({
    required this.enableAiFeatures,
    required this.studentFlashcardGeneration,
    required this.studentStudyNotesGeneration,
    required this.instructorAiQuizGeneration,
    required this.instructorAiAssignmentGeneration,
    required this.adminAiQuizGeneration,
    required this.adminAiAssignmentGeneration,
    required this.singleQuestionGeneration,
    required this.defaultAiModel,
    required this.enableDailyAiRequestLimit,
    required this.studentDailyAiRequests,
    required this.instructorDailyAiRequests,
    required this.adminDailyAiRequests,
    required this.maxMaterialContextSize,
    required this.maxGeneratedQuestionsPerQuiz,
    required this.maxGeneratedFlashcards,
    required this.maxGeneratedStudyNotesLength,
  });

  factory AiControlsConfig.defaults() => const AiControlsConfig(
        enableAiFeatures: true,
        studentFlashcardGeneration: true,
        studentStudyNotesGeneration: true,
        instructorAiQuizGeneration: true,
        instructorAiAssignmentGeneration: true,
        adminAiQuizGeneration: true,
        adminAiAssignmentGeneration: true,
        singleQuestionGeneration: true,
        defaultAiModel: AiModelNames.gemini3Flash,
        enableDailyAiRequestLimit: true,
        studentDailyAiRequests: 20,
        instructorDailyAiRequests: 40,
        adminDailyAiRequests: 100,
        maxMaterialContextSize: 16000,
        maxGeneratedQuestionsPerQuiz: 30,
        maxGeneratedFlashcards: 40,
        maxGeneratedStudyNotesLength: 4000,
      );

  factory AiControlsConfig.fromJson(Map<String, dynamic> json) {
    final defaults = AiControlsConfig.defaults().toJson();
    bool readBool(String key) => json[key] as bool? ?? defaults[key] as bool;
    int readInt(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return defaults[key] as int;
    }

    String readModel(String key) {
      final value = json[key]?.toString();
      return AiModelNames.allowed.contains(value)
          ? value!
          : defaults[key] as String;
    }

    return AiControlsConfig(
      enableAiFeatures: readBool(AiControlKeys.enableAiFeatures),
      studentFlashcardGeneration:
          readBool(AiControlKeys.studentFlashcardGeneration),
      studentStudyNotesGeneration:
          readBool(AiControlKeys.studentStudyNotesGeneration),
      instructorAiQuizGeneration:
          readBool(AiControlKeys.instructorAiQuizGeneration),
      instructorAiAssignmentGeneration:
          readBool(AiControlKeys.instructorAiAssignmentGeneration),
      adminAiQuizGeneration: readBool(AiControlKeys.adminAiQuizGeneration),
      adminAiAssignmentGeneration:
          readBool(AiControlKeys.adminAiAssignmentGeneration),
      singleQuestionGeneration: readBool(AiControlKeys.singleQuestionGeneration),
      defaultAiModel: readModel(AiControlKeys.defaultAiModel),
      enableDailyAiRequestLimit:
          readBool(AiControlKeys.enableDailyAiRequestLimit),
      studentDailyAiRequests: readInt(AiControlKeys.studentDailyAiRequests),
      instructorDailyAiRequests:
          readInt(AiControlKeys.instructorDailyAiRequests),
      adminDailyAiRequests: readInt(AiControlKeys.adminDailyAiRequests),
      maxMaterialContextSize: readInt(AiControlKeys.maxMaterialContextSize),
      maxGeneratedQuestionsPerQuiz:
          readInt(AiControlKeys.maxGeneratedQuestionsPerQuiz),
      maxGeneratedFlashcards: readInt(AiControlKeys.maxGeneratedFlashcards),
      maxGeneratedStudyNotesLength:
          readInt(AiControlKeys.maxGeneratedStudyNotesLength),
    );
  }

  final bool enableAiFeatures;
  final bool studentFlashcardGeneration;
  final bool studentStudyNotesGeneration;
  final bool instructorAiQuizGeneration;
  final bool instructorAiAssignmentGeneration;
  final bool adminAiQuizGeneration;
  final bool adminAiAssignmentGeneration;
  final bool singleQuestionGeneration;
  final String defaultAiModel;
  final bool enableDailyAiRequestLimit;
  final int studentDailyAiRequests;
  final int instructorDailyAiRequests;
  final int adminDailyAiRequests;
  final int maxMaterialContextSize;
  final int maxGeneratedQuestionsPerQuiz;
  final int maxGeneratedFlashcards;
  final int maxGeneratedStudyNotesLength;

  bool get canStudentGenerateFlashcards =>
      enableAiFeatures && studentFlashcardGeneration;
  bool get canStudentGenerateStudyNotes =>
      enableAiFeatures && studentStudyNotesGeneration;
  bool get canInstructorGenerateQuiz =>
      enableAiFeatures && instructorAiQuizGeneration;
  bool get canInstructorGenerateAssignment =>
      enableAiFeatures && instructorAiAssignmentGeneration;
  bool get canAdminGenerateQuiz => enableAiFeatures && adminAiQuizGeneration;
  bool get canAdminGenerateAssignment =>
      enableAiFeatures && adminAiAssignmentGeneration;
  bool get canGenerateSingleQuestion =>
      enableAiFeatures && singleQuestionGeneration;

  String get defaultModelId => AiModelNames.toModelId(defaultAiModel);

  Map<String, dynamic> toJson() => {
        AiControlKeys.enableAiFeatures: enableAiFeatures,
        AiControlKeys.studentFlashcardGeneration: studentFlashcardGeneration,
        AiControlKeys.studentStudyNotesGeneration: studentStudyNotesGeneration,
        AiControlKeys.instructorAiQuizGeneration: instructorAiQuizGeneration,
        AiControlKeys.instructorAiAssignmentGeneration:
            instructorAiAssignmentGeneration,
        AiControlKeys.adminAiQuizGeneration: adminAiQuizGeneration,
        AiControlKeys.adminAiAssignmentGeneration: adminAiAssignmentGeneration,
        AiControlKeys.singleQuestionGeneration: singleQuestionGeneration,
        AiControlKeys.defaultAiModel: defaultAiModel,
        AiControlKeys.enableDailyAiRequestLimit: enableDailyAiRequestLimit,
        AiControlKeys.studentDailyAiRequests: studentDailyAiRequests,
        AiControlKeys.instructorDailyAiRequests: instructorDailyAiRequests,
        AiControlKeys.adminDailyAiRequests: adminDailyAiRequests,
        AiControlKeys.maxMaterialContextSize: maxMaterialContextSize,
        AiControlKeys.maxGeneratedQuestionsPerQuiz:
            maxGeneratedQuestionsPerQuiz,
        AiControlKeys.maxGeneratedFlashcards: maxGeneratedFlashcards,
        AiControlKeys.maxGeneratedStudyNotesLength:
            maxGeneratedStudyNotesLength,
      };

  AiControlsConfig copyWith({
    bool? enableAiFeatures,
    bool? studentFlashcardGeneration,
    bool? studentStudyNotesGeneration,
    bool? instructorAiQuizGeneration,
    bool? instructorAiAssignmentGeneration,
    bool? adminAiQuizGeneration,
    bool? adminAiAssignmentGeneration,
    bool? singleQuestionGeneration,
    String? defaultAiModel,
    bool? enableDailyAiRequestLimit,
    int? studentDailyAiRequests,
    int? instructorDailyAiRequests,
    int? adminDailyAiRequests,
    int? maxMaterialContextSize,
    int? maxGeneratedQuestionsPerQuiz,
    int? maxGeneratedFlashcards,
    int? maxGeneratedStudyNotesLength,
  }) {
    return AiControlsConfig(
      enableAiFeatures: enableAiFeatures ?? this.enableAiFeatures,
      studentFlashcardGeneration:
          studentFlashcardGeneration ?? this.studentFlashcardGeneration,
      studentStudyNotesGeneration:
          studentStudyNotesGeneration ?? this.studentStudyNotesGeneration,
      instructorAiQuizGeneration:
          instructorAiQuizGeneration ?? this.instructorAiQuizGeneration,
      instructorAiAssignmentGeneration: instructorAiAssignmentGeneration ??
          this.instructorAiAssignmentGeneration,
      adminAiQuizGeneration:
          adminAiQuizGeneration ?? this.adminAiQuizGeneration,
      adminAiAssignmentGeneration:
          adminAiAssignmentGeneration ?? this.adminAiAssignmentGeneration,
      singleQuestionGeneration:
          singleQuestionGeneration ?? this.singleQuestionGeneration,
      defaultAiModel: defaultAiModel ?? this.defaultAiModel,
      enableDailyAiRequestLimit:
          enableDailyAiRequestLimit ?? this.enableDailyAiRequestLimit,
      studentDailyAiRequests:
          studentDailyAiRequests ?? this.studentDailyAiRequests,
      instructorDailyAiRequests:
          instructorDailyAiRequests ?? this.instructorDailyAiRequests,
      adminDailyAiRequests: adminDailyAiRequests ?? this.adminDailyAiRequests,
      maxMaterialContextSize:
          maxMaterialContextSize ?? this.maxMaterialContextSize,
      maxGeneratedQuestionsPerQuiz:
          maxGeneratedQuestionsPerQuiz ?? this.maxGeneratedQuestionsPerQuiz,
      maxGeneratedFlashcards:
          maxGeneratedFlashcards ?? this.maxGeneratedFlashcards,
      maxGeneratedStudyNotesLength:
          maxGeneratedStudyNotesLength ?? this.maxGeneratedStudyNotesLength,
    );
  }
}

class AiUsageStats {
  const AiUsageStats({
    required this.totalAiRequests,
    required this.quizDraftsGenerated,
    required this.assignmentDraftsGenerated,
    required this.flashcardSetsGenerated,
    required this.studyNotesGenerated,
    required this.failedAiRequests,
    required this.geminiFallbacksUsed,
  });

  factory AiUsageStats.empty() => const AiUsageStats(
        totalAiRequests: 0,
        quizDraftsGenerated: 0,
        assignmentDraftsGenerated: 0,
        flashcardSetsGenerated: 0,
        studyNotesGenerated: 0,
        failedAiRequests: 0,
        geminiFallbacksUsed: 0,
      );

  factory AiUsageStats.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return AiUsageStats(
      totalAiRequests: read('total_ai_requests'),
      quizDraftsGenerated: read('quiz_drafts_generated'),
      assignmentDraftsGenerated: read('assignment_drafts_generated'),
      flashcardSetsGenerated: read('flashcard_sets_generated'),
      studyNotesGenerated: read('study_notes_generated'),
      failedAiRequests: read('failed_ai_requests'),
      geminiFallbacksUsed: read('gemini_fallbacks_used'),
    );
  }

  final int totalAiRequests;
  final int quizDraftsGenerated;
  final int assignmentDraftsGenerated;
  final int flashcardSetsGenerated;
  final int studyNotesGenerated;
  final int failedAiRequests;
  final int geminiFallbacksUsed;
}

class AiGenerationReservation {
  const AiGenerationReservation({
    required this.logId,
    required this.config,
  });

  factory AiGenerationReservation.fromJson(Map<String, dynamic> json) {
    return AiGenerationReservation(
      logId: json['log_id']?.toString() ?? '',
      config: AiControlsConfig.fromJson(
        Map<String, dynamic>.from(json['config'] as Map? ?? const {}),
      ),
    );
  }

  final String logId;
  final AiControlsConfig config;
}

class AiFeatureTypes {
  const AiFeatureTypes._();

  static const quizDraft = 'quiz_draft';
  static const assignmentDraft = 'assignment_draft';
  static const singleQuestion = 'single_question';
  static const flashcards = 'flashcards';
  static const studyNotes = 'study_notes';
}

class AiControlKeys {
  const AiControlKeys._();

  static const enableAiFeatures = 'enable_ai_features';
  static const studentFlashcardGeneration = 'student_flashcard_generation';
  static const studentStudyNotesGeneration = 'student_study_notes_generation';
  static const instructorAiQuizGeneration = 'instructor_ai_quiz_generation';
  static const instructorAiAssignmentGeneration =
      'instructor_ai_assignment_generation';
  static const adminAiQuizGeneration = 'admin_ai_quiz_generation';
  static const adminAiAssignmentGeneration = 'admin_ai_assignment_generation';
  static const singleQuestionGeneration = 'single_question_generation';
  static const defaultAiModel = 'default_ai_model';
  static const enableDailyAiRequestLimit = 'enable_daily_ai_request_limit';
  static const studentDailyAiRequests = 'student_daily_ai_requests';
  static const instructorDailyAiRequests = 'instructor_daily_ai_requests';
  static const adminDailyAiRequests = 'admin_daily_ai_requests';
  static const maxMaterialContextSize = 'max_material_context_size';
  static const maxGeneratedQuestionsPerQuiz =
      'max_generated_questions_per_quiz';
  static const maxGeneratedFlashcards = 'max_generated_flashcards';
  static const maxGeneratedStudyNotesLength =
      'max_generated_study_notes_length';
}

class AiModelNames {
  const AiModelNames._();

  static const gemini3Flash = 'Gemini 3 Flash';
  static const gemini25Flash = 'Gemini 2.5 Flash';
  static const gemini31FlashLite = 'Gemini 3.1 Flash Lite';

  static const allowed = {
    gemini3Flash,
    gemini25Flash,
    gemini31FlashLite,
  };

  static String toModelId(String displayName) {
    switch (displayName) {
      case gemini25Flash:
        return 'gemini-2.5-flash';
      case gemini31FlashLite:
        return 'gemini-2.5-flash-lite';
      case gemini3Flash:
      default:
        return 'gemini-3-flash-preview';
    }
  }
}
