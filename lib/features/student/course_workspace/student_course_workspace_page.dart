import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/course_model.dart';
import '../../courses/providers/course_providers.dart';
import '../../permissions/providers/permissions_provider.dart';
import 'tabs/student_announcements_tab.dart';
import 'tabs/student_assignments_tab.dart';
import 'tabs/student_flashcards_tab.dart';
import 'tabs/student_materials_tab.dart';
import 'tabs/student_overview_tab.dart';
import 'tabs/student_quizzes_tab.dart';
import 'tabs/student_study_notes_tab.dart';
import 'tabs/student_students_tab.dart';

class StudentCourseWorkspacePage extends ConsumerStatefulWidget {
  const StudentCourseWorkspacePage({
    super.key,
    required this.courseId,
    this.initialCourse,
    this.accentColor = AppColors.primary,
  });

  final String courseId;
  final CourseModel? initialCourse;
  final Color accentColor;

  @override
  ConsumerState<StudentCourseWorkspacePage> createState() =>
      _StudentCourseWorkspacePageState();
}

class _StudentCourseWorkspacePageState
    extends ConsumerState<StudentCourseWorkspacePage> {
  static const _baseTabs = [
    (icon: Icons.dashboard_rounded, label: 'Overview'),
    (icon: Icons.attach_file_rounded, label: 'Materials'),
    (icon: Icons.style_rounded, label: 'Flashcards'),
    (icon: Icons.note_alt_rounded, label: 'Notes'),
    (icon: Icons.quiz_rounded, label: 'Quizzes'),
    (icon: Icons.assignment_rounded, label: 'Assignments'),
    (icon: Icons.people_rounded, label: 'Students'),
    (icon: Icons.campaign_rounded, label: 'Announcements'),
  ];

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailsProvider(widget.courseId));
    final course = courseAsync.valueOrNull ?? widget.initialCourse;
    final permissions = ref.watch(permissionsProvider).valueOrDefaults;
    final tabs = _baseTabs
        .where(
          (tab) =>
              tab.label != 'Students' || permissions.viewCourseStudentList,
        )
        .toList();

    if (course == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (courseAsync.hasError && widget.initialCourse == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () =>
                ref.invalidate(courseDetailsProvider(widget.courseId)),
            child: const Text('Retry'),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 240,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.sidebarBg,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _buildCourseHeader(course),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(46),
                child: _buildTabBar(tabs),
              ),
            ),
          ],
          body: TabBarView(
            children: tabs
                .map((tab) => _buildTabView(tab.label, course))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTabView(String label, CourseModel course) {
    switch (label) {
      case 'Overview':
        return StudentOverviewTab(course: course);
      case 'Materials':
        return StudentMaterialsTab(courseId: course.id);
      case 'Flashcards':
        return StudentFlashcardsTab(courseId: course.id);
      case 'Notes':
        return StudentStudyNotesTab(courseId: course.id);
      case 'Quizzes':
        return StudentQuizzesTab(courseId: course.id);
      case 'Assignments':
        return StudentAssignmentsTab(courseId: course.id);
      case 'Students':
        return StudentStudentsTab(courseId: course.id);
      default:
        return StudentAnnouncementsTab(courseId: course.id);
    }
  }

  Widget _buildCourseHeader(CourseModel course) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.sidebarBg,
            widget.accentColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 62),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.code,
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        color: Colors.white60,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        course.instructorSummary,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.book_rounded,
                        color: Colors.white60,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.lecturesCount} materials',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(List<({IconData icon, String label})> tabs) {
    return Container(
      color: AppColors.sidebarBg,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: Colors.white,
        indicatorWeight: 2,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        tabs: tabs
            .map(
              (tab) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 15),
                    const SizedBox(width: 5),
                    Text(tab.label),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
