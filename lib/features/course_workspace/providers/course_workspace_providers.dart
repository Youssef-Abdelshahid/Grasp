import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/activity_models.dart';
import '../../../models/announcement_model.dart';
import '../../../models/assignment_model.dart';
import '../../../models/basic_profile_model.dart';
import '../../../models/material_model.dart';
import '../../../models/quiz_model.dart';

final courseMaterialsProvider =
    FutureProvider.family<List<MaterialModel>, String>((ref, courseId) {
      return ref.watch(materialServiceProvider).getCourseMaterials(courseId);
    });

final courseAnnouncementsProvider =
    FutureProvider.family<List<AnnouncementModel>, String>((ref, courseId) {
      return ref
          .watch(announcementServiceProvider)
          .getCourseAnnouncements(courseId);
    });

final courseQuizzesProvider = FutureProvider.family<List<QuizModel>, String>((
  ref,
  courseId,
) {
  return ref.watch(quizServiceProvider).getCourseQuizzes(courseId);
});

final courseAssignmentsProvider =
    FutureProvider.family<List<AssignmentModel>, String>((ref, courseId) {
      return ref
          .watch(assignmentServiceProvider)
          .getCourseAssignments(courseId);
    });

final courseStudentsActivityProvider =
    FutureProvider.family<List<CourseStudentActivity>, String>((ref, courseId) {
      return ref
          .watch(activityServiceProvider)
          .getCourseStudentsActivity(courseId);
    });

final courseStudentsRosterProvider =
    FutureProvider.family<List<BasicProfileModel>, String>((ref, courseId) {
      return ref
          .watch(coursePeopleServiceProvider)
          .listCourseStudents(courseId);
    });
