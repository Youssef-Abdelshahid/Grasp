import '../core/auth/app_role.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final AppRole role;
  final String? avatarUrl;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: AppRole.fromValue(json['role'] as String? ?? 'student'),
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}
