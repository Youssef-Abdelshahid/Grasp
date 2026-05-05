import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/providers/service_providers.dart';
import '../../../models/admin_content_models.dart';
import '../../../models/admin_models.dart';
import '../../../models/flashcard_model.dart';
import '../../../models/study_note_model.dart';

class AdminUsersQuery {
  const AdminUsersQuery({this.search = '', this.role, this.status});

  final String search;
  final AppRole? role;
  final AdminAccountStatus? status;

  @override
  bool operator ==(Object other) {
    return other is AdminUsersQuery &&
        other.search == search &&
        other.role == role &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(search, role, status);
}

class AdminCoursesQuery {
  const AdminCoursesQuery({this.search = '', this.status});

  final String search;
  final String? status;

  @override
  bool operator ==(Object other) {
    return other is AdminCoursesQuery &&
        other.search == search &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(search, status);
}

class AdminContentQuery {
  const AdminContentQuery({this.search = '', this.courseId, this.status});

  final String search;
  final String? courseId;
  final String? status;

  @override
  bool operator ==(Object other) {
    return other is AdminContentQuery &&
        other.search == search &&
        other.courseId == courseId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(search, courseId, status);
}

final adminUsersProvider =
    FutureProvider.family<List<AdminUser>, AdminUsersQuery>((ref, query) {
      return ref
          .watch(adminServiceProvider)
          .listUsers(
            search: query.search,
            role: query.role,
            status: query.status,
          );
    });

final adminUserDetailProvider = FutureProvider.family<AdminUserDetail, String>((
  ref,
  userId,
) {
  return ref.watch(adminServiceProvider).getUserDetail(userId);
});

final adminCoursesProvider =
    FutureProvider.family<List<AdminCourseItem>, AdminCoursesQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(adminContentServiceProvider)
          .listCourses(search: query.search, status: query.status);
    });

final adminMaterialsProvider =
    FutureProvider.family<List<AdminMaterialItem>, AdminContentQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(adminContentServiceProvider)
          .listMaterials(
            search: query.search,
            courseId: query.courseId,
            fileType: query.status,
          );
    });

final adminQuizzesProvider =
    FutureProvider.family<List<AdminAssessmentItem>, AdminContentQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(adminContentServiceProvider)
          .listQuizzes(
            search: query.search,
            courseId: query.courseId,
            status: query.status,
          );
    });

final adminAssignmentsProvider =
    FutureProvider.family<List<AdminAssessmentItem>, AdminContentQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(adminContentServiceProvider)
          .listAssignments(
            search: query.search,
            courseId: query.courseId,
            status: query.status,
          );
    });

final adminAnnouncementsProvider =
    FutureProvider.family<List<AdminAnnouncementItem>, AdminContentQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(adminContentServiceProvider)
          .listAnnouncements(search: query.search, courseId: query.courseId);
    });

final adminFlashcardsProvider =
    FutureProvider.family<List<FlashcardModel>, String>((ref, search) {
      return ref
          .watch(flashcardServiceProvider)
          .getAllFlashcards(search: search);
    });

final adminStudyNotesProvider =
    FutureProvider.family<List<StudyNoteModel>, String>((ref, search) {
      return ref.watch(studyNoteServiceProvider).getAllNotes(search: search);
    });
