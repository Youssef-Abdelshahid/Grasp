import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/course_model.dart';
import '../../../services/course_service.dart';
import '../../courses/pages/create_course_page.dart';
import '../tabs/assignments_tab.dart';
import '../tabs/materials_tab.dart';
import '../tabs/overview_tab.dart';
import '../tabs/quizzes_tab.dart';
import '../tabs/students_tab.dart';

class CourseWorkspacePage extends StatefulWidget {
  const CourseWorkspacePage({
    super.key,
    required this.courseId,
    this.initialCourse,
    this.accentColor = AppColors.primary,
  });

  final String courseId;
  final CourseModel? initialCourse;
  final Color accentColor;

  @override
  State<CourseWorkspacePage> createState() => _CourseWorkspacePageState();
}

class _CourseWorkspacePageState extends State<CourseWorkspacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<CourseModel> _courseFuture;

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
    _courseFuture = CourseService.instance.getCourseDetails(widget.courseId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallbackCourse = widget.initialCourse;

    return FutureBuilder<CourseModel>(
      future: _courseFuture,
      initialData: fallbackCourse,
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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => _editCourse(course),
                    tooltip: 'Edit Course',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'archive') {
                        _archiveCourse(course);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'archive',
                        child: Text('Archive Course'),
                      ),
                    ],
                  ),
                ],
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
                OverviewTab(course: course),
                MaterialsTab(courseId: course.id),
                QuizzesTab(courseId: course.id),
                AssignmentsTab(courseId: course.id),
                StudentsTab(courseId: course.id),
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
                          course.code,
                          style: AppTextStyles.buttonSmall
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.isVisible ? 'Published' : 'Draft',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _HeaderMeta(
                        icon: Icons.people_rounded,
                        label: '${course.studentsCount} students',
                      ),
                      _HeaderMeta(
                        icon: Icons.book_rounded,
                        label: '${course.lecturesCount} materials',
                      ),
                      if (course.semester.isNotEmpty)
                        _HeaderMeta(
                          icon: Icons.calendar_month_rounded,
                          label: course.semester,
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

  Future<void> _editCourse(CourseModel course) async {
    final result = await Navigator.push<CourseModel>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCoursePage(course: course),
      ),
    );
    if (result != null) {
      setState(() {
        _courseFuture = CourseService.instance.getCourseDetails(widget.courseId);
      });
    }
  }

  Future<void> _archiveCourse(CourseModel course) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Archive Course'),
            content: Text('Archive "${course.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Archive'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await CourseService.instance.archiveCourse(course.id);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }
}

class _HeaderMeta extends StatelessWidget {
  const _HeaderMeta({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white60, size: 13),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}
