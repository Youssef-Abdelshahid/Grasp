import 'package:intl/intl.dart';

import '../core/auth/app_role.dart';
import 'dashboard_models.dart';

enum AdminAccountStatus {
  active('active'),
  inactive('inactive'),
  suspended('suspended'),
  removed('removed');

  const AdminAccountStatus(this.value);

  final String value;

  static AdminAccountStatus fromValue(String value) {
    return AdminAccountStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => AdminAccountStatus.active,
    );
  }

  String get label {
    switch (this) {
      case AdminAccountStatus.active:
        return 'Active';
      case AdminAccountStatus.inactive:
        return 'Inactive';
      case AdminAccountStatus.suspended:
        return 'Suspended';
      case AdminAccountStatus.removed:
        return 'Removed';
    }
  }
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.phone = '',
    this.department = '',
    this.studentId = '',
    this.program = '',
    this.academicYear = '',
    this.employeeId = '',
    this.bio = '',
    this.createdAt,
    this.updatedAt,
    this.lastActiveAt,
    this.enrolledAt,
    this.enrollmentStatus = '',
    this.coursesCount = 0,
    this.submissionsCount = 0,
    this.adminActionsCount = 0,
    this.managedUsersCount = 0,
  });

  final String id;
  final String name;
  final String email;
  final AppRole role;
  final AdminAccountStatus status;
  final String? avatarUrl;
  final String phone;
  final String department;
  final String studentId;
  final String program;
  final String academicYear;
  final String employeeId;
  final String bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActiveAt;
  final DateTime? enrolledAt;
  final String enrollmentStatus;
  final int coursesCount;
  final int submissionsCount;
  final int adminActionsCount;
  final int managedUsersCount;

  String get roleLabel => role.label;
  String get statusLabel => status.label;
  String get joinedLabel => _formatDate(createdAt);
  String get lastActiveLabel => _formatRelative(lastActiveAt);
  String get enrolledLabel => _formatDate(enrolledAt);
  String get enrollmentStatusLabel =>
      enrollmentStatus.isEmpty ? '' : _label(enrollmentStatus);

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: AppRole.fromValue(json['role'] as String? ?? 'student'),
      status: AdminAccountStatus.fromValue(
        json['status'] as String? ??
            json['account_status'] as String? ??
            'active',
      ),
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String? ?? '',
      department: json['department'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      program: json['program'] as String? ?? '',
      academicYear: json['academic_year'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      lastActiveAt: _parseDate(json['last_active_at']),
      enrolledAt: _parseDate(json['enrolled_at']),
      enrollmentStatus: json['enrollment_status'] as String? ?? '',
      coursesCount: (json['courses_count'] as num? ?? 0).toInt(),
      submissionsCount: (json['submissions_count'] as num? ?? 0).toInt(),
      adminActionsCount: (json['admin_actions_count'] as num? ?? 0).toInt(),
      managedUsersCount: (json['managed_users_count'] as num? ?? 0).toInt(),
    );
  }
}

class AdminCourseActivity {
  const AdminCourseActivity({
    required this.title,
    required this.subtitle,
    required this.status,
    this.createdAt,
  });

  final String title;
  final String subtitle;
  final String status;
  final DateTime? createdAt;

  factory AdminCourseActivity.fromJson(Map<String, dynamic> json) {
    return AdminCourseActivity(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class AdminUserDetail {
  const AdminUserDetail({
    required this.user,
    required this.courses,
    required this.activity,
  });

  final AdminUser user;
  final List<AdminCourseActivity> courses;
  final List<DashboardActivityItem> activity;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final userJson = Map<String, dynamic>.from(
      json['user'] as Map? ?? const {},
    );
    final courseItems = (json['courses'] as List<dynamic>? ?? [])
        .map(
          (item) => AdminCourseActivity.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final activityItems = (json['activity'] as List<dynamic>? ?? [])
        .map(
          (item) => DashboardActivityItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return AdminUserDetail(
      user: AdminUser.fromJson(userJson),
      courses: courseItems,
      activity: activityItems,
    );
  }
}

class AdminProfileData {
  const AdminProfileData({required this.profile, required this.activity});

  final AdminUser profile;
  final List<DashboardActivityItem> activity;

  factory AdminProfileData.fromJson(Map<String, dynamic> json) {
    final profileJson = Map<String, dynamic>.from(
      json['profile'] as Map? ?? const {},
    );
    final activityItems = (json['activity'] as List<dynamic>? ?? [])
        .map(
          (item) => DashboardActivityItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return AdminProfileData(
      profile: AdminUser.fromJson(profileJson),
      activity: activityItems,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return 'Unknown';
  }
  return DateFormat('MMM d, yyyy').format(value);
}

String _label(String value) {
  if (value.isEmpty) {
    return '';
  }
  return value[0].toUpperCase() + value.substring(1);
}

String _formatRelative(DateTime? value) {
  if (value == null) {
    return 'Unknown';
  }

  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) {
    return 'Just now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours} hours ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} days ago';
  }
  return _formatDate(value);
}
