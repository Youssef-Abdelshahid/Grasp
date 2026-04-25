import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/app_role.dart';
import '../models/admin_models.dart';
import '../models/dashboard_models.dart';
import 'auth_service.dart';

class AdminService {
  AdminService._();

  static final instance = AdminService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<AdminDashboardSummary> getDashboardSummary() async {
    final response = await _client.rpc('get_admin_dashboard_summary');
    return AdminDashboardSummary.fromJson(_mapResponse(response));
  }

  Future<List<AdminUser>> listUsers({
    String search = '',
    AppRole? role,
    AdminAccountStatus? status,
  }) async {
    final response = await _client.rpc(
      'list_admin_users',
      params: {
        'p_search': search.trim(),
        'p_role': role?.value,
        'p_status': status?.value,
      },
    );

    return (response as List<dynamic>? ?? [])
        .map(
          (item) => AdminUser.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AdminUserDetail> getUserDetail(String userId) async {
    final response = await _client.rpc(
      'get_admin_user_detail',
      params: {'p_user_id': userId},
    );
    return AdminUserDetail.fromJson(_mapResponse(response));
  }

  Future<AdminUserDetail> updateUser({
    required String userId,
    String? fullName,
    AppRole? role,
    AdminAccountStatus? status,
    String? department,
    String? phone,
  }) async {
    final response = await _client.rpc(
      'admin_update_user',
      params: {
        'p_user_id': userId,
        'p_full_name': fullName,
        'p_role': role?.value,
        'p_status': status?.value,
        'p_department': department,
        'p_phone': phone,
      },
    );
    return AdminUserDetail.fromJson(_mapResponse(response));
  }

  Future<void> removeUser(String userId) async {
    await _client.rpc('admin_remove_user', params: {'p_user_id': userId});
  }

  Future<AdminProfileData> getCurrentAdminProfile() async {
    final response = await _client.rpc('get_current_admin_profile');
    return AdminProfileData.fromJson(_mapResponse(response));
  }

  Future<AdminProfileData> updateOwnProfile({
    required String fullName,
    required String phone,
    required String department,
    required String bio,
    String? email,
  }) async {
    final currentEmail = _client.auth.currentUser?.email ?? '';
    final trimmedEmail = email?.trim() ?? '';

    if (trimmedEmail.isNotEmpty && trimmedEmail != currentEmail) {
      await _client.auth.updateUser(UserAttributes(email: trimmedEmail));
    }

    final response = await _client.rpc(
      'admin_update_own_profile',
      params: {
        'p_full_name': fullName,
        'p_email': trimmedEmail,
        'p_phone': phone,
        'p_department': department,
        'p_bio': bio,
      },
    );

    await AuthService.instance.reloadProfile();
    return AdminProfileData.fromJson(_mapResponse(response));
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Map<String, dynamic> _mapResponse(dynamic response) {
    if (response == null) {
      throw const AdminServiceException('Admin action returned no data.');
    }
    return Map<String, dynamic>.from(response as Map);
  }
}

class AdminServiceException implements Exception {
  const AdminServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
