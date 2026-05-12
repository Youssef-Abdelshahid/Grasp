import '../core/auth/app_role.dart';

class BasicProfileModel {
  const BasicProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.status = 'active',
    this.enrolledAt,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final AppRole role;
  final String phone;
  final String status;
  final DateTime? enrolledAt;
  final String? avatarUrl;

  String get roleLabel => role.label;

  factory BasicProfileModel.fromJson(Map<String, dynamic> json) {
    return BasicProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: AppRole.fromValue(json['role'] as String? ?? 'student'),
      status: json['status'] as String? ?? 'active',
      avatarUrl: json['avatar_url'] as String?,
      enrolledAt: json['enrolled_at'] == null
          ? null
          : DateTime.tryParse(json['enrolled_at'].toString())?.toLocal(),
    );
  }
}
