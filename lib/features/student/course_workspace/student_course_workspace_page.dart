import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/course_model.dart';
import 'tabs/student_overview_tab.dart';
import 'tabs/student_materials_tab.dart';
import 'tabs/student_quizzes_tab.dart';
import 'tabs/student_assignments_tab.dart';
import 'tabs/student_announcements_tab.dart';

class StudentCourseWorkspacePage extends StatefulWidget {
  final CourseModel course;
  final Color accentColor;
  final double progress;

  const StudentCourseWorkspacePage({
    super.key,
    required this.course,
    this.accentColor = AppColors.primary,
    this.progress = 0.0,
  });

  @override
  State<StudentCourseWorkspacePage> createState() =>
      _StudentCourseWorkspacePageState();
}

class _StudentCourseWorkspacePageState extends State<StudentCourseWorkspacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildCourseHeader(),
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
            StudentOverviewTab(course: widget.course, progress: widget.progress),
            const StudentMaterialsTab(),
            const StudentQuizzesTab(),
            const StudentAssignmentsTab(),
            const StudentAnnouncementsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader() {
    final percent = (widget.progress * 100).round();

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.course.code,
                          style: AppTextStyles.buttonSmall
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '$percent% done',
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.course.title,
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          color: Colors.white60, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        widget.course.instructor,
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      color: Colors.white,
                      minHeight: 4,
                    ),
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
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        tabs: _tabs
            .map((t) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, size: 15),
                      const SizedBox(width: 5),
                      Text(t.label),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
