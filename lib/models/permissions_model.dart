class AppPermissions {
  const AppPermissions({
    required this.downloadMaterials,
    required this.takeQuizzes,
    required this.submitAssignments,
    required this.generateFlashcards,
    required this.generateStudyNotes,
    required this.viewCourseStudentList,
    required this.createCourses,
    required this.manageCourses,
    required this.manageCourseStudents,
    required this.uploadMaterials,
    required this.manageQuizzes,
    required this.manageAssignments,
    required this.postAnnouncements,
    required this.useAiQuizGeneration,
    required this.useAiAssignmentGeneration,
    required this.gradeStudentWork,
    required this.viewStudentActivity,
    required this.allowPublicStudentRegistration,
    required this.allowPublicInstructorRegistration,
    required this.allowInstructorsToCreateCourses,
    required this.requireReviewBeforeAiContentPublished,
  });

  factory AppPermissions.defaults() => const AppPermissions(
        downloadMaterials: true,
        takeQuizzes: true,
        submitAssignments: true,
        generateFlashcards: true,
        generateStudyNotes: true,
        viewCourseStudentList: true,
        createCourses: true,
        manageCourses: true,
        manageCourseStudents: true,
        uploadMaterials: true,
        manageQuizzes: true,
        manageAssignments: true,
        postAnnouncements: true,
        useAiQuizGeneration: true,
        useAiAssignmentGeneration: true,
        gradeStudentWork: true,
        viewStudentActivity: true,
        allowPublicStudentRegistration: true,
        allowPublicInstructorRegistration: false,
        allowInstructorsToCreateCourses: true,
        requireReviewBeforeAiContentPublished: true,
      );

  factory AppPermissions.fromJson(Map<String, dynamic> json) {
    final defaults = AppPermissions.defaults().toJson();
    bool read(String key) => json[key] as bool? ?? defaults[key] as bool;

    return AppPermissions(
      downloadMaterials: read(PermissionKeys.downloadMaterials),
      takeQuizzes: read(PermissionKeys.takeQuizzes),
      submitAssignments: read(PermissionKeys.submitAssignments),
      generateFlashcards: read(PermissionKeys.generateFlashcards),
      generateStudyNotes: read(PermissionKeys.generateStudyNotes),
      viewCourseStudentList: read(PermissionKeys.viewCourseStudentList),
      createCourses:
          json[PermissionKeys.createCourses] as bool? ??
          json[PermissionKeys.manageCourses] as bool? ??
          true,
      manageCourses:
          json[PermissionKeys.manageCourses] as bool? ??
          json[PermissionKeys.createCourses] as bool? ??
          defaults[PermissionKeys.manageCourses] as bool,
      manageCourseStudents: read(PermissionKeys.manageCourseStudents),
      uploadMaterials: read(PermissionKeys.uploadMaterials),
      manageQuizzes: read(PermissionKeys.manageQuizzes),
      manageAssignments: read(PermissionKeys.manageAssignments),
      postAnnouncements: read(PermissionKeys.postAnnouncements),
      useAiQuizGeneration: read(PermissionKeys.useAiQuizGeneration),
      useAiAssignmentGeneration: read(PermissionKeys.useAiAssignmentGeneration),
      gradeStudentWork: read(PermissionKeys.gradeStudentWork),
      viewStudentActivity: read(PermissionKeys.viewStudentActivity),
      allowPublicStudentRegistration:
          read(PermissionKeys.allowPublicStudentRegistration),
      allowPublicInstructorRegistration:
          read(PermissionKeys.allowPublicInstructorRegistration),
      allowInstructorsToCreateCourses:
          read(PermissionKeys.allowInstructorsToCreateCourses),
      requireReviewBeforeAiContentPublished:
          read(PermissionKeys.requireReviewBeforeAiContentPublished),
    );
  }

  final bool downloadMaterials;
  final bool takeQuizzes;
  final bool submitAssignments;
  final bool generateFlashcards;
  final bool generateStudyNotes;
  final bool viewCourseStudentList;

  final bool createCourses;
  final bool manageCourses;
  final bool manageCourseStudents;
  final bool uploadMaterials;
  final bool manageQuizzes;
  final bool manageAssignments;
  final bool postAnnouncements;
  final bool useAiQuizGeneration;
  final bool useAiAssignmentGeneration;
  final bool gradeStudentWork;
  final bool viewStudentActivity;

  final bool allowPublicStudentRegistration;
  final bool allowPublicInstructorRegistration;
  final bool allowInstructorsToCreateCourses;
  final bool requireReviewBeforeAiContentPublished;

  bool get canInstructorCreateCourses =>
      manageCourses && allowInstructorsToCreateCourses;

  bool get canInstructorManageCourses => manageCourses;

  int get enabledStudentCount => studentValues.where((value) => value).length;
  int get enabledInstructorCount =>
      instructorValues.where((value) => value).length;

  List<bool> get studentValues => [
        downloadMaterials,
        takeQuizzes,
        submitAssignments,
        generateFlashcards,
        generateStudyNotes,
        viewCourseStudentList,
      ];

  List<bool> get instructorValues => [
        manageCourses,
        manageCourseStudents,
        uploadMaterials,
        manageQuizzes,
        manageAssignments,
        postAnnouncements,
        useAiQuizGeneration,
        useAiAssignmentGeneration,
        gradeStudentWork,
        viewStudentActivity,
      ];

  Map<String, bool> toJson() => {
        PermissionKeys.downloadMaterials: downloadMaterials,
        PermissionKeys.takeQuizzes: takeQuizzes,
        PermissionKeys.submitAssignments: submitAssignments,
        PermissionKeys.generateFlashcards: generateFlashcards,
        PermissionKeys.generateStudyNotes: generateStudyNotes,
        PermissionKeys.viewCourseStudentList: viewCourseStudentList,
        PermissionKeys.manageCourses: manageCourses,
        PermissionKeys.manageCourseStudents: manageCourseStudents,
        PermissionKeys.uploadMaterials: uploadMaterials,
        PermissionKeys.manageQuizzes: manageQuizzes,
        PermissionKeys.manageAssignments: manageAssignments,
        PermissionKeys.postAnnouncements: postAnnouncements,
        PermissionKeys.useAiQuizGeneration: useAiQuizGeneration,
        PermissionKeys.useAiAssignmentGeneration: useAiAssignmentGeneration,
        PermissionKeys.gradeStudentWork: gradeStudentWork,
        PermissionKeys.viewStudentActivity: viewStudentActivity,
        PermissionKeys.allowPublicStudentRegistration:
            allowPublicStudentRegistration,
        PermissionKeys.allowPublicInstructorRegistration:
            allowPublicInstructorRegistration,
        PermissionKeys.allowInstructorsToCreateCourses:
            allowInstructorsToCreateCourses,
        PermissionKeys.requireReviewBeforeAiContentPublished:
            requireReviewBeforeAiContentPublished,
      };

  AppPermissions copyWithKey(String key, bool value) {
    final json = toJson();
    if (!PermissionKeys.all.contains(key)) {
      throw ArgumentError.value(key, 'key', 'Unknown permission key');
    }
    json[key] = value;
    return AppPermissions.fromJson(json);
  }
}

class PermissionKeys {
  const PermissionKeys._();

  static const downloadMaterials = 'download_materials';
  static const takeQuizzes = 'take_quizzes';
  static const submitAssignments = 'submit_assignments';
  static const generateFlashcards = 'generate_flashcards';
  static const generateStudyNotes = 'generate_study_notes';
  static const viewCourseStudentList = 'view_course_student_list';

  static const createCourses = 'create_courses';
  static const manageCourses = 'manage_courses';
  static const manageCourseStudents = 'manage_course_students';
  static const uploadMaterials = 'upload_materials';
  static const manageQuizzes = 'manage_quizzes';
  static const manageAssignments = 'manage_assignments';
  static const postAnnouncements = 'post_announcements';
  static const useAiQuizGeneration = 'use_ai_quiz_generation';
  static const useAiAssignmentGeneration = 'use_ai_assignment_generation';
  static const gradeStudentWork = 'grade_student_work';
  static const viewStudentActivity = 'view_student_activity';

  static const allowPublicStudentRegistration =
      'allow_public_student_registration';
  static const allowPublicInstructorRegistration =
      'allow_public_instructor_registration';
  static const allowInstructorsToCreateCourses =
      'allow_instructors_to_create_courses';
  static const requireReviewBeforeAiContentPublished =
      'require_review_before_ai_content_published';

  static const all = {
    downloadMaterials,
    takeQuizzes,
    submitAssignments,
    generateFlashcards,
    generateStudyNotes,
    viewCourseStudentList,
    manageCourses,
    manageCourseStudents,
    uploadMaterials,
    manageQuizzes,
    manageAssignments,
    postAnnouncements,
    useAiQuizGeneration,
    useAiAssignmentGeneration,
    gradeStudentWork,
    viewStudentActivity,
    allowPublicStudentRegistration,
    allowPublicInstructorRegistration,
    allowInstructorsToCreateCourses,
    requireReviewBeforeAiContentPublished,
  };
}
