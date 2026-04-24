import '../core/auth/app_role.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final AppRole role;
  final String? avatarUrl;
  final String studentId;
  final String program;
  final String academicYear;
  final String department;
  final String employeeId;
  final String bio;
  final Map<String, dynamic> preferences;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.studentId = '',
    this.program = '',
    this.academicYear = '',
    this.department = '',
    this.employeeId = '',
    this.bio = '',
    this.preferences = const {},
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: AppRole.fromValue(json['role'] as String? ?? 'student'),
      avatarUrl: json['avatar_url'] as String?,
      studentId: json['student_id'] as String? ?? '',
      program: json['program'] as String? ?? '',
      academicYear: json['academic_year'] as String? ?? '',
      department: json['department'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      preferences: (json['preferences'] as Map<String, dynamic>? ?? const {}),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}
