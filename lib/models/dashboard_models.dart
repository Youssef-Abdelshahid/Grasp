class DashboardStat {
  const DashboardStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class DashboardActivityItem {
  const DashboardActivityItem({
    required this.title,
    required this.subtitle,
    required this.timestampLabel,
    this.type,
  });

  final String title;
  final String subtitle;
  final String timestampLabel;
  final String? type;

  factory DashboardActivityItem.fromJson(Map<String, dynamic> json) {
    return DashboardActivityItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      timestampLabel: json['time'] as String? ?? '',
      type: json['type'] as String?,
    );
  }
}

class InstructorDashboardSummary {
  const InstructorDashboardSummary({
    required this.coursesCount,
    required this.studentsCount,
    required this.pendingAiDrafts,
    required this.averageScore,
    required this.recentActivity,
  });

  final int coursesCount;
  final int studentsCount;
  final int pendingAiDrafts;
  final double averageScore;
  final List<DashboardActivityItem> recentActivity;

  factory InstructorDashboardSummary.fromJson(Map<String, dynamic> json) {
    final activities = (json['recent_activity'] as List<dynamic>? ?? [])
        .map((item) => DashboardActivityItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();

    return InstructorDashboardSummary(
      coursesCount: (json['courses_count'] as num? ?? 0).toInt(),
      studentsCount: (json['students_count'] as num? ?? 0).toInt(),
      pendingAiDrafts: (json['pending_ai_drafts'] as num? ?? 0).toInt(),
      averageScore: (json['average_score'] as num? ?? 0).toDouble(),
      recentActivity: activities,
    );
  }
}

class StudentDeadlineItem {
  const StudentDeadlineItem({
    required this.title,
    required this.course,
    required this.dueLabel,
    required this.type,
  });

  final String title;
  final String course;
  final String dueLabel;
  final String type;

  factory StudentDeadlineItem.fromJson(Map<String, dynamic> json) {
    return StudentDeadlineItem(
      title: json['title'] as String? ?? '',
      course: json['course'] as String? ?? '',
      dueLabel: json['due'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}

class StudentAnnouncementItem {
  const StudentAnnouncementItem({
    required this.title,
    required this.course,
    required this.timeLabel,
    required this.isPinned,
  });

  final String title;
  final String course;
  final String timeLabel;
  final bool isPinned;

  factory StudentAnnouncementItem.fromJson(Map<String, dynamic> json) {
    return StudentAnnouncementItem(
      title: json['title'] as String? ?? '',
      course: json['course'] as String? ?? '',
      timeLabel: json['time'] as String? ?? '',
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }
}

class StudentDashboardSummary {
  const StudentDashboardSummary({
    required this.enrolledCourses,
    required this.pendingTasks,
    required this.averageScore,
    required this.completedSubmissions,
    required this.upcomingDeadlines,
    required this.recentAnnouncements,
  });

  final int enrolledCourses;
  final int pendingTasks;
  final double averageScore;
  final int completedSubmissions;
  final List<StudentDeadlineItem> upcomingDeadlines;
  final List<StudentAnnouncementItem> recentAnnouncements;

  factory StudentDashboardSummary.fromJson(Map<String, dynamic> json) {
    final deadlines = (json['upcoming_deadlines'] as List<dynamic>? ?? [])
        .map((item) => StudentDeadlineItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
    final announcements =
        (json['recent_announcements'] as List<dynamic>? ?? [])
            .map((item) => StudentAnnouncementItem.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();

    return StudentDashboardSummary(
      enrolledCourses: (json['enrolled_courses'] as num? ?? 0).toInt(),
      pendingTasks: (json['pending_tasks'] as num? ?? 0).toInt(),
      averageScore: (json['average_score'] as num? ?? 0).toDouble(),
      completedSubmissions:
          (json['completed_submissions'] as num? ?? 0).toInt(),
      upcomingDeadlines: deadlines,
      recentAnnouncements: announcements,
    );
  }
}

class AdminRegistrationItem {
  const AdminRegistrationItem({
    required this.name,
    required this.email,
    required this.role,
    required this.timeLabel,
  });

  final String name;
  final String email;
  final String role;
  final String timeLabel;

  factory AdminRegistrationItem.fromJson(Map<String, dynamic> json) {
    return AdminRegistrationItem(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      timeLabel: json['time'] as String? ?? '',
    );
  }
}

class AdminAlertItem {
  const AdminAlertItem({
    required this.title,
    required this.body,
    required this.level,
  });

  final String title;
  final String body;
  final String level;

  factory AdminAlertItem.fromJson(Map<String, dynamic> json) {
    return AdminAlertItem(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      level: json['level'] as String? ?? 'info',
    );
  }
}

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.totalUsers,
    required this.studentsCount,
    required this.instructorsCount,
    required this.totalCourses,
    required this.activeCourses,
    required this.aiItemsToday,
    required this.recentRegistrations,
    required this.systemActivity,
    required this.alerts,
  });

  final int totalUsers;
  final int studentsCount;
  final int instructorsCount;
  final int totalCourses;
  final int activeCourses;
  final int aiItemsToday;
  final List<AdminRegistrationItem> recentRegistrations;
  final List<DashboardActivityItem> systemActivity;
  final List<AdminAlertItem> alerts;

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    final registrations =
        (json['recent_registrations'] as List<dynamic>? ?? [])
            .map((item) => AdminRegistrationItem.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
    final activity = (json['system_activity'] as List<dynamic>? ?? [])
        .map((item) => DashboardActivityItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
    final alerts = (json['alerts'] as List<dynamic>? ?? [])
        .map((item) => AdminAlertItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();

    return AdminDashboardSummary(
      totalUsers: (json['total_users'] as num? ?? 0).toInt(),
      studentsCount: (json['students_count'] as num? ?? 0).toInt(),
      instructorsCount: (json['instructors_count'] as num? ?? 0).toInt(),
      totalCourses: (json['total_courses'] as num? ?? 0).toInt(),
      activeCourses: (json['active_courses'] as num? ?? 0).toInt(),
      aiItemsToday: (json['ai_items_today'] as num? ?? 0).toInt(),
      recentRegistrations: registrations,
      systemActivity: activity,
      alerts: alerts,
    );
  }
}
