import '../core/theme/app_colors.dart';
import '../models/calendar_event_model.dart';
import '../models/course_model.dart';
import 'announcement_service.dart';
import 'assignment_service.dart';
import 'course_service.dart';
import 'quiz_service.dart';

class CalendarService {
  CalendarService._();

  static final instance = CalendarService._();

  Future<List<CalendarEventModel>> getStudentCalendarEvents() async {
    final courses = await CourseService.instance.getStudentCourses();
    return _buildEventsForCourses(courses, includeAnnouncements: true);
  }

  Future<List<CalendarEventModel>> getInstructorCalendarEvents() async {
    final courses = await CourseService.instance.getInstructorCourses();
    return _buildEventsForCourses(courses, includeAnnouncements: true);
  }

  Future<List<CalendarEventModel>> _buildEventsForCourses(
    List<CourseModel> courses, {
    required bool includeAnnouncements,
  }) async {
    final events = <CalendarEventModel>[];
    for (final course in courses) {
      final quizzes = await QuizService.instance.getCourseQuizzes(course.id);
      final assignments = await AssignmentService.instance.getCourseAssignments(
        course.id,
      );

      for (final quiz in quizzes.where((item) => item.dueAt != null)) {
        events.add(
          CalendarEventModel(
            id: 'quiz_${quiz.id}',
            title: quiz.title,
            subtitle: '${course.title} • ${course.code}',
            type: 'Quiz',
            date: quiz.dueAt!.toLocal(),
            color: AppColors.violet,
          ),
        );
      }

      for (final assignment in assignments.where(
        (item) => item.dueAt != null,
      )) {
        events.add(
          CalendarEventModel(
            id: 'assignment_${assignment.id}',
            title: assignment.title,
            subtitle: '${course.title} • ${course.code}',
            type: 'Assignment',
            date: assignment.dueAt!.toLocal(),
            color: AppColors.emerald,
          ),
        );
      }

      if (includeAnnouncements) {
        final announcements = await AnnouncementService.instance
            .getCourseAnnouncements(course.id);
        for (final announcement in announcements.take(3)) {
          events.add(
            CalendarEventModel(
              id: 'announcement_${announcement.id}',
              title: announcement.title,
              subtitle: '${course.title} • announcement',
              type: 'Announcement',
              date: announcement.createdAt.toLocal(),
              color: AppColors.cyan,
            ),
          );
        }
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }
}
