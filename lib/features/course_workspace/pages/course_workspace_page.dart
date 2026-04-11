import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/course_model.dart';
import '../tabs/overview_tab.dart';
import '../tabs/materials_tab.dart';
import '../tabs/quizzes_tab.dart';
import '../tabs/assignments_tab.dart';
import '../tabs/students_tab.dart';

class CourseWorkspacePage extends StatefulWidget {
  final CourseModel course;
  final Color accentColor;

  const CourseWorkspacePage({
    super.key,
    required this.course,
    this.accentColor = AppColors.primary,
  });

  @override
  State<CourseWorkspacePage> createState() => _CourseWorkspacePageState();
}

class _CourseWorkspacePageState extends State<CourseWorkspacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (icon: Icons.dashboard_rounded, label: 'Overview'),
    (icon: Icons.attach_file_rounded, label: 'Materials'),
    (icon: Icons.quiz_rounded, label: 'Quizzes'),
    (icon: Icons.assignment_rounded, label: 'Assignments'),
    (icon: Icons.people_rounded, label: 'Students'),
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
                icon: const Icon(Icons.edit_rounded),
                onPressed: () {},
                tooltip: 'Edit Course',
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {},
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
            OverviewTab(course: widget.course),
            const MaterialsTab(),
            const QuizzesTab(),
            const AssignmentsTab(),
            const StudentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader() {
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
                  const SizedBox(height: 8),
                  Text(
                    widget.course.title,
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_rounded,
                              color: Colors.white60, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.course.studentsCount} students',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white60),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.book_rounded,
                              color: Colors.white60, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.course.lecturesCount} lectures',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white60),
                          ),
                        ],
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
