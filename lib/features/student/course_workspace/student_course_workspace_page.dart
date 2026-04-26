import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/course_model.dart';
import '../../../services/course_service.dart';
import 'tabs/student_announcements_tab.dart';
import 'tabs/student_assignments_tab.dart';
import 'tabs/student_materials_tab.dart';
import 'tabs/student_overview_tab.dart';
import 'tabs/student_quizzes_tab.dart';

class StudentCourseWorkspacePage extends StatefulWidget {
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
  State<StudentCourseWorkspacePage> createState() =>
      _StudentCourseWorkspacePageState();
}

class _StudentCourseWorkspacePageState extends State<StudentCourseWorkspacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<CourseModel> _courseFuture;

  static const _tabs = [
    (icon: Icons.dashboard_rounded, label: 'Overview'),
    (icon: Icons.attach_file_rounded, label: 'Materials'),
    (icon: Icons.quiz_rounded, label: 'Quizzes'),
    (icon: Icons.assignment_rounded, label: 'Assignments'),
    (icon: Icons.campaign_rounded, label: 'Announcements'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _courseFuture = CourseService.instance.getCourseDetails(widget.courseId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CourseModel>(
      future: _courseFuture,
      initialData: widget.initialCourse,
      builder: (context, snapshot) {
        final course = snapshot.data;
        if (course == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
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
                  child: _buildTabBar(),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                StudentOverviewTab(course: course),
                StudentMaterialsTab(courseId: course.id),
                StudentQuizzesTab(courseId: course.id),
                StudentAssignmentsTab(courseId: course.id),
                StudentAnnouncementsTab(courseId: course.id),
              ],
            ),
          ),
        );
      },
    );
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
                        course.instructor,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white60,
                        ),
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

  Widget _buildTabBar() {
    return Container(
      color: AppColors.sidebarBg,
      child: TabBar(
        controller: _tabController,
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
        tabs: _tabs
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
