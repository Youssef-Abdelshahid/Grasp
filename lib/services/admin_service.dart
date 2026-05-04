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
    String? email,
    AppRole? role,
    AdminAccountStatus? status,
    String? phone,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'admin-update-user',
        body: {
          'user_id': userId,
          if (fullName != null) 'full_name': fullName.trim(),
          if (email != null) 'email': email.trim(),
          if (role != null) 'role': role.value,
          if (status != null) 'account_status': status.value,
          if (phone != null) 'phone': phone.trim(),
        },
      );
      final data = response.data;
      if (data is Map && data['error'] is String) {
        throw AdminServiceException(data['error'] as String);
      }
      return getUserDetail(userId);
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] is String) {
        throw AdminServiceException(details['error'] as String);
      }
      throw const AdminServiceException('User profile could not be updated.');
    } on AdminServiceException {
      rethrow;
    } catch (_) {
      throw const AdminServiceException('User profile could not be updated.');
    }
  }

  Future<void> removeUser(String userId) async {
    await _client.rpc('admin_remove_user', params: {'p_user_id': userId});
  }

  Future<AdminUser> createUser({
    required String fullName,
    required String email,
    required String temporaryPassword,
    required AppRole role,
    required AdminAccountStatus status,
    String phone = '',
    String department = '',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'admin-create-user',
        body: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': temporaryPassword,
          'role': role.value,
          'account_status': status.value,
          'phone': phone.trim(),
          'department': department.trim(),
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const AdminServiceException('User account could not be created.');
      }
      final error = data['error'] as String?;
      if (error != null && error.isNotEmpty) {
        throw AdminServiceException(error);
      }
      final user = data['user'];
      if (user is! Map) {
        throw const AdminServiceException('User account could not be created.');
      }
      return AdminUser.fromJson(Map<String, dynamic>.from(user));
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] is String) {
        throw AdminServiceException(details['error'] as String);
      }
      throw const AdminServiceException('User account could not be created.');
    } on AdminServiceException {
      rethrow;
    } catch (_) {
      throw const AdminServiceException('User account could not be created.');
    }
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

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email?.trim() ?? '';
    if (email.isEmpty) {
      throw const AdminServiceException('Admin session could not be verified.');
    }

    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } on AuthException {
      throw const AdminServiceException('Current password is incorrect.');
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException {
      throw const AdminServiceException('Password could not be updated.');
    }
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
