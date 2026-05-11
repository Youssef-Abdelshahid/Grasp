import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/activity_service.dart';
import '../../services/admin_content_service.dart';
import '../../services/admin_service.dart';
import '../../services/announcement_service.dart';
import '../../services/assignment_service.dart';
import '../../services/auth_service.dart';
import '../../services/calendar_service.dart';
import '../../services/course_people_service.dart';
import '../../services/course_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/flashcard_service.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/material_service.dart';
import '../../services/notification_service.dart';
import '../../services/permissions_service.dart';
import '../../services/profile_service.dart';
import '../../services/quiz_service.dart';
import '../../services/study_note_service.dart';
import '../../services/submission_service.dart';
import '../../services/user_settings_service.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService.instance,
);
final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService.instance,
);
final courseServiceProvider = Provider<CourseService>(
  (ref) => CourseService.instance,
);
final coursePeopleServiceProvider = Provider<CoursePeopleService>(
  (ref) => CoursePeopleService.instance,
);
final materialServiceProvider = Provider<MaterialService>(
  (ref) => MaterialService.instance,
);
final quizServiceProvider = Provider<QuizService>(
  (ref) => QuizService.instance,
);
final assignmentServiceProvider = Provider<AssignmentService>(
  (ref) => AssignmentService.instance,
);
final submissionServiceProvider = Provider<SubmissionService>(
  (ref) => SubmissionService.instance,
);
final announcementServiceProvider = Provider<AnnouncementService>(
  (ref) => AnnouncementService.instance,
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);
final permissionsServiceProvider = Provider<PermissionsService>(
  (ref) => PermissionsService.instance,
);
final flashcardServiceProvider = Provider<FlashcardService>(
  (ref) => FlashcardService.instance,
);
final studyNoteServiceProvider = Provider<StudyNoteService>(
  (ref) => StudyNoteService.instance,
);
final adminServiceProvider = Provider<AdminService>(
  (ref) => AdminService.instance,
);
final adminContentServiceProvider = Provider<AdminContentService>(
  (ref) => AdminContentService.instance,
);
final activityServiceProvider = Provider<ActivityService>(
  (ref) => ActivityService.instance,
);
final enrollmentServiceProvider = Provider<EnrollmentService>(
  (ref) => EnrollmentService.instance,
);
final calendarServiceProvider = Provider<CalendarService>(
  (ref) => CalendarService.instance,
);
final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService.instance,
);
final geminiAiServiceProvider = Provider<GeminiAiService>(
  (ref) => GeminiAiService.instance,
);
final userSettingsServiceProvider = Provider<UserSettingsService>(
  (ref) => UserSettingsService.instance,
);
