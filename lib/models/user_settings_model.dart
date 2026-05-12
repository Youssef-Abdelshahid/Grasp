import '../core/auth/app_role.dart';

class UserSettingsEnvelope {
  const UserSettingsEnvelope({
    required this.userId,
    required this.role,
    required this.settings,
    required this.defaults,
  });

  final String userId;
  final AppRole role;
  final UserSettings settings;
  final Map<String, dynamic> defaults;

  factory UserSettingsEnvelope.fromJson(Map<String, dynamic> json) {
    final role = AppRole.fromValue(json['role'] as String? ?? 'student');
    final settingsJson = Map<String, dynamic>.from(
      json['settings'] as Map? ?? const {},
    );
    return UserSettingsEnvelope(
      userId: json['user_id'] as String? ?? '',
      role: role,
      settings: UserSettings.fromJson(role, settingsJson),
      defaults: Map<String, dynamic>.from(json['defaults'] as Map? ?? const {}),
    );
  }
}

sealed class UserSettings {
  const UserSettings({required this.role});

  final AppRole role;

  Map<String, dynamic> toJson();

  factory UserSettings.fromJson(AppRole role, Map<String, dynamic> json) {
    return switch (role) {
      AppRole.student => StudentSettings.fromJson(json),
      AppRole.instructor => InstructorSettings.fromJson(json),
      AppRole.admin => StudentSettings.fromJson(json),
    };
  }
}

class StudentSettings extends UserSettings {
  const StudentSettings({
    this.themeMode = 'light',
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.assignmentAlerts = true,
    this.quizAlerts = true,
    this.announcementAlerts = true,
    this.deadlineReminder24h = true,
    this.deadlineReminder1h = false,
    this.studyReminders = true,
    this.dailyStudyReminder = true,
    this.weeklyStudySummary = true,
    this.showOverdueFirst = true,
    this.defaultDeadlineReminderTime = '09:00',
  }) : super(role: AppRole.student);

  final bool emailNotifications;
  final String themeMode;
  final bool pushNotifications;
  final bool assignmentAlerts;
  final bool quizAlerts;
  final bool announcementAlerts;
  final bool deadlineReminder24h;
  final bool deadlineReminder1h;
  final bool studyReminders;
  final bool dailyStudyReminder;
  final bool weeklyStudySummary;
  final bool showOverdueFirst;
  final String defaultDeadlineReminderTime;

  factory StudentSettings.fromJson(Map<String, dynamic> json) {
    const defaults = StudentSettings();
    return StudentSettings(
      themeMode: _themeMode(json['theme_mode'] as String?),
      emailNotifications:
          json['email_notifications'] as bool? ?? defaults.emailNotifications,
      pushNotifications:
          json['push_notifications'] as bool? ?? defaults.pushNotifications,
      assignmentAlerts:
          json['assignment_alerts'] as bool? ?? defaults.assignmentAlerts,
      quizAlerts: json['quiz_alerts'] as bool? ?? defaults.quizAlerts,
      announcementAlerts:
          json['announcement_alerts'] as bool? ?? defaults.announcementAlerts,
      deadlineReminder24h:
          json['deadline_reminder_24h'] as bool? ??
          defaults.deadlineReminder24h,
      deadlineReminder1h:
          json['deadline_reminder_1h'] as bool? ?? defaults.deadlineReminder1h,
      studyReminders:
          json['study_reminders'] as bool? ?? defaults.studyReminders,
      dailyStudyReminder:
          json['daily_study_reminder'] as bool? ?? defaults.dailyStudyReminder,
      weeklyStudySummary:
          json['weekly_study_summary'] as bool? ?? defaults.weeklyStudySummary,
      showOverdueFirst:
          json['show_overdue_first'] as bool? ?? defaults.showOverdueFirst,
      defaultDeadlineReminderTime:
          json['default_deadline_reminder_time'] as String? ??
          defaults.defaultDeadlineReminderTime,
    );
  }

  StudentSettings copyWith({
    String? themeMode,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? assignmentAlerts,
    bool? quizAlerts,
    bool? announcementAlerts,
    bool? deadlineReminder24h,
    bool? deadlineReminder1h,
    bool? studyReminders,
    bool? dailyStudyReminder,
    bool? weeklyStudySummary,
    bool? showOverdueFirst,
    String? defaultDeadlineReminderTime,
  }) {
    return StudentSettings(
      themeMode: themeMode ?? this.themeMode,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      assignmentAlerts: assignmentAlerts ?? this.assignmentAlerts,
      quizAlerts: quizAlerts ?? this.quizAlerts,
      announcementAlerts: announcementAlerts ?? this.announcementAlerts,
      deadlineReminder24h: deadlineReminder24h ?? this.deadlineReminder24h,
      deadlineReminder1h: deadlineReminder1h ?? this.deadlineReminder1h,
      studyReminders: studyReminders ?? this.studyReminders,
      dailyStudyReminder: dailyStudyReminder ?? this.dailyStudyReminder,
      weeklyStudySummary: weeklyStudySummary ?? this.weeklyStudySummary,
      showOverdueFirst: showOverdueFirst ?? this.showOverdueFirst,
      defaultDeadlineReminderTime:
          defaultDeadlineReminderTime ?? this.defaultDeadlineReminderTime,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'theme_mode': _themeMode(themeMode),
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'assignment_alerts': assignmentAlerts,
      'quiz_alerts': quizAlerts,
      'announcement_alerts': announcementAlerts,
      'deadline_reminder_24h': deadlineReminder24h,
      'deadline_reminder_1h': deadlineReminder1h,
      'study_reminders': studyReminders,
      'daily_study_reminder': dailyStudyReminder,
      'weekly_study_summary': weeklyStudySummary,
      'show_overdue_first': showOverdueFirst,
      'default_deadline_reminder_time': defaultDeadlineReminderTime,
    };
  }
}

class InstructorSettings extends UserSettings {
  const InstructorSettings({
    this.themeMode = 'light',
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.quizSubmissionAlerts = true,
    this.assignmentSubmissionAlerts = true,
    this.announcementAlerts = true,
    this.deadlineReminders = true,
    this.defaultQuizDifficulty = 'medium',
    this.defaultQuestionCount = 10,
    this.defaultQuestionTypes = const [
      'MCQ',
      'True/False',
      'Short Answer',
      'Matching',
    ],
    this.defaultAssignmentDifficulty = 'medium',
  }) : super(role: AppRole.instructor);

  final bool emailNotifications;
  final String themeMode;
  final bool pushNotifications;
  final bool quizSubmissionAlerts;
  final bool assignmentSubmissionAlerts;
  final bool announcementAlerts;
  final bool deadlineReminders;
  final String defaultQuizDifficulty;
  final int defaultQuestionCount;
  final List<String> defaultQuestionTypes;
  final String defaultAssignmentDifficulty;

  static const allowedDifficulties = ['easy', 'medium', 'hard'];
  static const allowedQuestionTypes = [
    'MCQ',
    'True/False',
    'Short Answer',
    'Matching',
  ];

  factory InstructorSettings.fromJson(Map<String, dynamic> json) {
    const defaults = InstructorSettings();
    final questionTypes = (json['default_question_types'] as List? ?? const [])
        .map((item) => item.toString())
        .where(allowedQuestionTypes.contains)
        .toSet()
        .toList();
    final difficulty = (json['default_quiz_difficulty'] as String? ?? '')
        .trim()
        .toLowerCase();
    final assignmentDifficulty =
        (json['default_assignment_difficulty'] as String? ?? '')
            .trim()
            .toLowerCase();

    return InstructorSettings(
      themeMode: _themeMode(json['theme_mode'] as String?),
      emailNotifications:
          json['email_notifications'] as bool? ?? defaults.emailNotifications,
      pushNotifications:
          json['push_notifications'] as bool? ?? defaults.pushNotifications,
      quizSubmissionAlerts:
          json['quiz_submission_alerts'] as bool? ??
          defaults.quizSubmissionAlerts,
      assignmentSubmissionAlerts:
          json['assignment_submission_alerts'] as bool? ??
          defaults.assignmentSubmissionAlerts,
      announcementAlerts:
          json['announcement_alerts'] as bool? ?? defaults.announcementAlerts,
      deadlineReminders:
          json['deadline_reminders'] as bool? ?? defaults.deadlineReminders,
      defaultQuizDifficulty: allowedDifficulties.contains(difficulty)
          ? difficulty
          : defaults.defaultQuizDifficulty,
      defaultQuestionCount:
          (json['default_question_count'] as num?)?.toInt().clamp(1, 50) ??
          defaults.defaultQuestionCount,
      defaultQuestionTypes: questionTypes.isEmpty
          ? defaults.defaultQuestionTypes
          : questionTypes,
      defaultAssignmentDifficulty:
          allowedDifficulties.contains(assignmentDifficulty)
          ? assignmentDifficulty
          : defaults.defaultAssignmentDifficulty,
    );
  }

  InstructorSettings copyWith({
    String? themeMode,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? quizSubmissionAlerts,
    bool? assignmentSubmissionAlerts,
    bool? announcementAlerts,
    bool? deadlineReminders,
    String? defaultQuizDifficulty,
    int? defaultQuestionCount,
    List<String>? defaultQuestionTypes,
    String? defaultAssignmentDifficulty,
  }) {
    return InstructorSettings(
      themeMode: themeMode ?? this.themeMode,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      quizSubmissionAlerts: quizSubmissionAlerts ?? this.quizSubmissionAlerts,
      assignmentSubmissionAlerts:
          assignmentSubmissionAlerts ?? this.assignmentSubmissionAlerts,
      announcementAlerts: announcementAlerts ?? this.announcementAlerts,
      deadlineReminders: deadlineReminders ?? this.deadlineReminders,
      defaultQuizDifficulty:
          defaultQuizDifficulty ?? this.defaultQuizDifficulty,
      defaultQuestionCount: defaultQuestionCount ?? this.defaultQuestionCount,
      defaultQuestionTypes: defaultQuestionTypes ?? this.defaultQuestionTypes,
      defaultAssignmentDifficulty:
          defaultAssignmentDifficulty ?? this.defaultAssignmentDifficulty,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'theme_mode': _themeMode(themeMode),
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'quiz_submission_alerts': quizSubmissionAlerts,
      'assignment_submission_alerts': assignmentSubmissionAlerts,
      'announcement_alerts': announcementAlerts,
      'deadline_reminders': deadlineReminders,
      'default_quiz_difficulty': defaultQuizDifficulty,
      'default_question_count': defaultQuestionCount.clamp(1, 50),
      'default_question_types': defaultQuestionTypes
          .where(allowedQuestionTypes.contains)
          .toSet()
          .toList(),
      'default_assignment_difficulty': defaultAssignmentDifficulty,
    };
  }
}

String _themeMode(String? value) {
  return value == 'dark' ? 'dark' : 'light';
}
