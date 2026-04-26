import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/app_role.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ProfileService {
  ProfileService._();

  static final instance = ProfileService._();

  static const avatarBucketName = 'user-avatars';

  SupabaseClient get _client => Supabase.instance.client;

  Future<UserModel> getCurrentProfile() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<UserModel> updateProfile({
    required AppRole role,
    required String fullName,
    required String email,
    String studentId = '',
    String program = '',
    String academicYear = '',
    String department = '',
    String employeeId = '',
    String bio = '',
  }) async {
    final userId = _client.auth.currentUser!.id;
    final currentEmail = _client.auth.currentUser?.email ?? '';

    if (email.trim().isNotEmpty && email.trim() != currentEmail) {
      await _client.auth.updateUser(UserAttributes(email: email.trim()));
    }

    final response = await _client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'email': email.trim(),
          'student_id': studentId.trim(),
          'program': program.trim(),
          'academic_year': academicYear.trim(),
          'department': department.trim(),
          'employee_id': employeeId.trim(),
          'bio': bio.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();

    await AuthService.instance.reloadProfile();
    return UserModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<UserModel> updatePreferences(Map<String, dynamic> preferences) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('profiles')
        .update({
          'preferences': preferences,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();

    await AuthService.instance.reloadProfile();
    return UserModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<UserModel> uploadAvatar(PlatformFile file) async {
    final userId = _client.auth.currentUser!.id;
    final bytes = await _readFileBytes(file);
    final extension = (file.extension ?? 'png').toLowerCase();
    final objectPath =
        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage
        .from(avatarBucketName)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _guessImageMime(extension),
          ),
        );

    final avatarUrl = await _client.storage
        .from(avatarBucketName)
        .createSignedUrl(objectPath, 31536000);

    final response = await _client
        .from('profiles')
        .update({
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();

    await AuthService.instance.reloadProfile();
    return UserModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<Uint8List> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }
    final readStream = file.readStream;
    if (readStream != null) {
      final chunks = <int>[];
      await for (final chunk in readStream) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    }
    throw const ProfileException('Unable to read the selected file.');
  }

  String _guessImageMime(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }
}

class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
