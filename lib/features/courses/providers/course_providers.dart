import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/course_model.dart';

final instructorCoursesProvider =
    AsyncNotifierProvider<InstructorCoursesNotifier, List<CourseModel>>(
      InstructorCoursesNotifier.new,
    );

final studentCoursesProvider =
    AsyncNotifierProvider<StudentCoursesNotifier, List<CourseModel>>(
      StudentCoursesNotifier.new,
    );

final courseDetailsProvider = FutureProvider.family<CourseModel, String>((
  ref,
  courseId,
) {
  return ref.watch(courseServiceProvider).getCourseDetails(courseId);
});

class InstructorCoursesNotifier extends AsyncNotifier<List<CourseModel>> {
  @override
  Future<List<CourseModel>> build() {
    return ref.watch(courseServiceProvider).getInstructorCourses();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

class StudentCoursesNotifier extends AsyncNotifier<List<CourseModel>> {
  @override
  Future<List<CourseModel>> build() {
    return ref.watch(courseServiceProvider).getStudentCourses();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
