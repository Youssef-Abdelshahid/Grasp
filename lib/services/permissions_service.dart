import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/permissions_model.dart';

class PermissionsService {
  PermissionsService._();

  static final instance = PermissionsService._();

  static const blockedMessage =
      'You do not currently have permission to perform this action.';

  SupabaseClient get _client => Supabase.instance.client;

  Future<AppPermissions> getPermissions() async {
    try {
      final response = await _client.rpc('get_effective_permissions');
      return AppPermissions.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (error) {
      throw PermissionsException(_friendlyMessage(error));
    }
  }

  Future<AppPermissions> getAdminPermissions() async {
    try {
      final response = await _client.rpc('get_admin_permissions_config');
      return AppPermissions.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (error) {
      throw PermissionsException(_friendlyMessage(error));
    }
  }

  Future<AppPermissions> updateAdminPermissions(AppPermissions permissions) async {
    try {
      final response = await _client.rpc(
        'update_admin_permissions_config',
        params: {'p_config': permissions.toJson()},
      );
      return AppPermissions.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (error) {
      throw PermissionsException(_friendlyMessage(error));
    }
  }

  Future<AppPermissions> resetAdminPermissions() async {
    try {
      final response = await _client.rpc('reset_admin_permissions_config');
      return AppPermissions.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (error) {
      throw PermissionsException(_friendlyMessage(error));
    }
  }

  Future<({bool student, bool instructor})> getPublicRegistrationPermissions()
      async {
    try {
      final response = await _client.rpc('get_public_registration_permissions');
      final json = Map<String, dynamic>.from(response as Map);
      return (
        student: json[PermissionKeys.allowPublicStudentRegistration] as bool? ??
            true,
        instructor:
            json[PermissionKeys.allowPublicInstructorRegistration] as bool? ??
                false,
      );
    } catch (_) {
      return (student: true, instructor: false);
    }
  }

  Future<void> requirePermission(String key) async {
    final permissions = await getPermissions();
    final value = permissions.toJson()[key];
    if (value != true) {
      throw const PermissionsException(blockedMessage);
    }
  }

  Future<void> requireStudentPermission(String key) async {
    final role = await _currentRole();
    if (role == 'admin' || role == 'instructor') {
      return;
    }
    await requirePermission(key);
  }

  Future<void> requireInstructorPermission(String key) async {
    final role = await _currentRole();
    if (role == 'admin') {
      return;
    }
    if (role != 'instructor') {
      throw const PermissionsException(blockedMessage);
    }
    await requirePermission(key);
  }

  Future<void> requireInstructorCourseManagement({bool creating = false}) async {
    final role = await _currentRole();
    if (role == 'admin') {
      return;
    }
    if (role != 'instructor') {
      throw const PermissionsException(blockedMessage);
    }
    final permissions = await getPermissions();
    final allowed = creating
        ? permissions.canInstructorCreateCourses
        : permissions.canInstructorManageCourses;
    if (!allowed) {
      throw const PermissionsException(blockedMessage);
    }
  }

  Future<void> requireInstructorCourseCreation() {
    return requireInstructorCourseManagement(creating: true);
  }

  Future<void> requireInstructorCourseStudentsManagement() async {
    final role = await _currentRole();
    if (role == 'admin') {
      return;
    }
    if (role != 'instructor') {
      throw const PermissionsException(blockedMessage);
    }
    await requirePermission(PermissionKeys.manageCourseStudents);
  }

  Future<String?> _currentRole() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final response = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return (response as Map?)?['role']?.toString();
  }

  String _friendlyMessage(Object error) {
    if (error is PermissionsException) return error.message;
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('permission') ||
          message.contains('access required') ||
          error.code == '42501') {
        return blockedMessage;
      }
      if (message.contains('unknown permission') ||
          message.contains('invalid permission')) {
        return 'The permissions configuration is invalid. Refresh and try again.';
      }
    }
    return 'Unable to update permissions right now. Please try again.';
  }
}

class PermissionsException implements Exception {
  const PermissionsException(this.message);

  final String message;

  @override
  String toString() => message;
}
